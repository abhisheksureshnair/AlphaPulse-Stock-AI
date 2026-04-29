import sys
import getpass

def security_check():
    # Only run check if we are the main module or starting up
    # Note: This will prompt in the terminal where uvicorn is running
    print("\n" + "="*40)
    print(" ALPHAPULSE BACKEND - SECURITY LOCK")
    print("="*40)
    try:
        code = getpass.getpass("Enter Security Code to start: ")
        if code != "007":
            print("\nACCESS DENIED. Invalid security code.")
            sys.exit(1)
        print("\nACCESS GRANTED. Initializing system...")
    except EOFError:
        print("\nSecurity check failed: No terminal input available.")
        sys.exit(1)

security_check()

from fastapi import FastAPI, HTTPException, Query, Body, Depends, status, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from pydantic import BaseModel
from dotenv import load_dotenv
import time
from collections import defaultdict
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException
import logging
import json
from datetime import datetime
from openai import AsyncOpenAI
import ta
import yfinance as yf
from sqlalchemy import create_async_engine, Column, Integer, String, Float, DateTime, ForeignKey
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, relationship
from sqlalchemy.future import select
from sqlalchemy import delete
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from datetime import datetime, timedelta
from jose import JWTError, jwt
from passlib.context import CryptContext
import asyncio
import os
from typing import Any, Optional

class RateLimiter:
    def __init__(self, limit: int, window: int):
        self.limit = limit
        self.window = window
        self.requests = defaultdict(list)

    def is_allowed(self, user_id: int) -> bool:
        now = time.time()
        user_requests = self.requests[user_id]
        # Clean old requests
        self.requests[user_id] = [req for req in user_requests if now - req < self.window]
        if len(self.requests[user_id]) < self.limit:
            self.requests[user_id].append(now)
            return True
        return False

ai_rate_limiter = RateLimiter(limit=10, window=60)

# Pydantic Models
class TransactionCreate(BaseModel):
    ticker: str
    price: float
    quantity: int

class AlertCreate(BaseModel):
    ticker: str
    condition: str
    target_value: float

class RecommendationRequest(BaseModel):
    budget: float
    strategy: str = "aggressive"
    symbol: Optional[str] = None
    explain_simple: bool = False

app = FastAPI()

@app.middleware("http")
async def log_requests(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    duration = time.time() - start_time
    request_info = {
        "method": request.method,
        "path": request.url.path,
        "status_code": response.status_code,
        "duration_ms": int(duration * 1000)
    }
    logger.info(f"API Request: {request.method} {request.url.path}", extra={"request_info": request_info})
    return response

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.error(f"Global Error: {str(exc)}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={"error": True, "message": "An unexpected error occurred. Please try again later."}
    )

@app.exception_handler(StarletteHTTPException)
async def http_exception_handler(request: Request, exc: StarletteHTTPException):
    return JSONResponse(status_code=exc.status_code, content={"error": True, "message": exc.detail})

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    return JSONResponse(status_code=422, content={"error": True, "message": "Invalid input data provided."})

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

load_dotenv()
client = AsyncOpenAI(api_key=os.getenv("OPENAI_API_KEY"))

# Auth Configuration
SECRET_KEY = os.getenv("SECRET_KEY", "your-secret-key-change-this-in-production")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30*24*60 # 30 days for now

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

# In-memory Cache
recommendation_cache = {}
CACHE_TTL = 3600 # 1 hour

# Database Configuration
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite+aiosqlite:///./stocks.db")
engine = create_async_engine(DATABASE_URL, echo=True)
Base = declarative_base()
async_session = sessionmaker(engine, expire_on_commit=False, class_=AsyncSession)

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    
    transactions = relationship("Transaction", back_populates="owner")
    alerts = relationship("Alert", back_populates="owner")

class Transaction(Base):
    __tablename__ = "transactions"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    ticker = Column(String, index=True)
    price = Column(Float)
    quantity = Column(Integer)
    type = Column(String)  # 'BUY' or 'SELL'
    timestamp = Column(DateTime, default=datetime.utcnow)
    
    owner = relationship("User", back_populates="transactions")

class Alert(Base):
    __tablename__ = "alerts"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    ticker = Column(String, index=True)
    condition = Column(String)  # 'PRICE_ABOVE', 'PRICE_BELOW', 'RSI_BELOW', etc.
    target_value = Column(Float)
    is_triggered = Column(Integer, default=0)
    timestamp = Column(DateTime, default=datetime.utcnow)
    
    owner = relationship("User", back_populates="alerts")

# Auth Utilities
def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password):
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

async def get_current_user(token: str = Depends(oauth2_scheme)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    
    async with async_session() as session:
        result = await session.execute(select(User).where(User.username == username))
        user = result.scalars().first()
        if user is None:
            raise credentials_exception
        return user

# Auth Endpoints
@app.post("/register")
async def register(username: str = Body(...), password: str = Body(...)):
    async with async_session() as session:
        # Check if user exists
        result = await session.execute(select(User).where(User.username == username))
        if result.scalars().first():
            raise HTTPException(status_code=400, detail="Username already registered")
        
        hashed_pwd = get_password_hash(password)
        new_user = User(username=username, hashed_password=hashed_pwd)
        session.add(new_user)
        await session.commit()
        return {"message": "User created successfully"}

@app.post("/auth/demo")
async def demo_login():
    """Create/Reset demo user and return token"""
    async with async_session() as session:
        # 1. Ensure demo user exists
        demo_username = "demo_user"
        result = await session.execute(select(User).where(User.username == demo_username))
        user = result.scalars().first()
        
        if not user:
            hashed_pwd = get_password_hash("demo_password_123")
            user = User(username=demo_username, hashed_password=hashed_pwd)
            session.add(user)
            await session.flush() # Get user ID
        
        # 2. Reset demo data for a fresh experience
        await session.execute(
            delete(Transaction).where(Transaction.user_id == user.id)
        )
        await session.execute(
            delete(Alert).where(Alert.user_id == user.id)
        )
        
        # 3. Seed Transactions
        seed_data = [
            {"ticker": "AAPL", "price": 175.50, "quantity": 10, "type": "BUY"},
            {"ticker": "TSLA", "price": 165.20, "quantity": 5, "type": "BUY"},
            {"ticker": "NVDA", "price": 850.00, "quantity": 2, "type": "BUY"},
            {"ticker": "MSFT", "price": 415.00, "quantity": 3, "type": "BUY"},
            {"ticker": "AMZN", "price": 178.00, "quantity": 4, "type": "BUY"},
        ]
        
        for item in seed_data:
            tx = Transaction(
                user_id=user.id,
                ticker=item["ticker"],
                price=item["price"],
                quantity=item["quantity"],
                type=item["type"]
            )
            session.add(tx)
            
        # 4. Seed Alerts
        alerts = [
            {"ticker": "NVDA", "condition": "PRICE_ABOVE", "target_value": 950.0},
            {"ticker": "TSLA", "condition": "PRICE_BELOW", "target_value": 150.0},
        ]
        
        for item in alerts:
            al = Alert(
                user_id=user.id,
                ticker=item["ticker"],
                condition=item["condition"],
                target_value=item["target_value"]
            )
            session.add(al)
            
        await session.commit()
        
        # 5. Return Token
        access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            data={"sub": user.username}, expires_delta=access_token_expires
        )
        return {"access_token": access_token, "token_type": "bearer", "is_demo": True}

@app.post("/token")
async def login_for_access_token(form_data: OAuth2PasswordRequestForm = Depends()):
    async with async_session() as session:
        result = await session.execute(select(User).where(User.username == form_data.username))
        user = result.scalars().first()
        if not user or not verify_password(form_data.password, user.hashed_password):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Incorrect username or password",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            data={"sub": user.username}, expires_delta=access_token_expires
        )
        return {"access_token": access_token, "token_type": "bearer"}

async def init_db():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

@app.post("/alerts")
async def create_alert(alert: AlertCreate, current_user: User = Depends(get_current_user)):
    async with async_session() as session:
        new_alert = Alert(
            user_id=current_user.id,
            ticker=alert.ticker.upper(),
            condition=alert.condition,
            target_value=alert.target_value
        )
        session.add(new_alert)
        await session.commit()
    return {"message": "Alert created"}

@app.get("/scan")
async def scan_market(current_user: User = Depends(get_current_user)):
    if not ai_rate_limiter.is_allowed(current_user.id):
        raise HTTPException(status_code=429, detail="Market scan rate limit exceeded. Please wait a minute.")
    
    tickers = ["AAPL", "TSLA", "NVDA", "MSFT", "AMZN"]

@app.get("/alerts")
async def get_alerts(current_user: User = Depends(get_current_user)):
    async with async_session() as session:
        result = await session.execute(
            select(Alert).where(Alert.user_id == current_user.id)
        )
        alerts = result.scalars().all()
        return alerts

async def check_alerts_task():
    """Background task to check alerts periodically"""
    while True:
        try:
            async with async_session() as session:
                result = await session.execute(select(Alert).where(Alert.is_triggered == 0))
                active_alerts = result.scalars().all()
                
                for alert in active_alerts:
                    data = get_stock_snapshot(alert.ticker)
                    triggered = False
                    
                    if alert.condition == "PRICE_ABOVE" and data["price"] >= alert.target_value:
                        triggered = True
                    elif alert.condition == "PRICE_BELOW" and data["price"] <= alert.target_value:
                        triggered = True
                    elif alert.condition == "RSI_BELOW" and data["RSI"] <= alert.target_value:
                        triggered = True
                    
                    if triggered:
                        alert.is_triggered = 1
                        print(f"ALERT TRIGGERED: {alert.ticker} {alert.condition} {alert.target_value}")
                
                await session.commit()
        except Exception as e:
            print(f"Error checking alerts: {e}")
        
        await asyncio.sleep(60)  # Check every minute

@app.on_event("startup")
async def startup():
    await init_db()
    asyncio.create_task(check_alerts_task())

# Production-ready CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # In production, replace with specific domains
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

DEFAULT_SYMBOLS = ["AAPL", "TSLA", "NVDA", "MSFT"]
COMPANY_NAMES = {
    "AAPL": "Apple Inc.",
    "TSLA": "Tesla Inc.",
    "NVDA": "NVIDIA Corp.",
    "MSFT": "Microsoft Corp.",
}


def _to_float(value: Any) -> float | None:
    try:
        if value is None:
            return None
        if hasattr(value, "item"):
            value = value.item()
        return float(value)
    except (TypeError, ValueError):
        return None


def _build_signal(rsi: float | None, macd: float | None) -> str:
    if rsi is None or macd is None:
        return "NEUTRAL"
    if rsi < 30 and macd > 0:
        return "STRONG BUY"
    if rsi < 45 and macd >= 0:
        return "BUY"
    if rsi > 70 and macd < 0:
        return "STRONG SELL"
    if rsi > 55 and macd <= 0:
        return "SELL"
    return "NEUTRAL"


def get_stock_snapshot(symbol: str) -> dict[str, Any]:
    normalized_symbol = symbol.upper().strip()
    history = yf.Ticker(normalized_symbol).history(period="3mo", interval="1d")

    if history.empty:
        raise HTTPException(status_code=404, detail=f"No market data found for {normalized_symbol}.")

    close = history["Close"].dropna()
    if close.empty:
        raise HTTPException(status_code=404, detail=f"No closing price data found for {normalized_symbol}.")

    rsi_series = ta.momentum.RSIIndicator(close=close).rsi().dropna()
    macd_obj = ta.trend.MACD(close=close)
    macd_series = macd_obj.macd().dropna()
    macd_signal_series = macd_obj.macd_signal().dropna()
    macd_diff_series = macd_obj.macd_diff().dropna()

    latest_price = _to_float(close.iloc[-1])
    previous_price = _to_float(close.iloc[-2]) if len(close) > 1 else latest_price
    latest_rsi = _to_float(rsi_series.iloc[-1]) if not rsi_series.empty else None
    latest_macd = _to_float(macd_series.iloc[-1]) if not macd_series.empty else None
    latest_macd_signal = _to_float(macd_signal_series.iloc[-1]) if not macd_signal_series.empty else None
    latest_macd_diff = _to_float(macd_diff_series.iloc[-1]) if not macd_diff_series.empty else None
    
    # Crossover detection
    prev_macd_diff = _to_float(macd_diff_series.iloc[-2]) if len(macd_diff_series) > 1 else None
    macd_crossover = "NONE"
    if prev_macd_diff is not None and latest_macd_diff is not None:
        if prev_macd_diff < 0 and latest_macd_diff > 0:
            macd_crossover = "BULLISH (Cross Above)"
        elif prev_macd_diff > 0 and latest_macd_diff < 0:
            macd_crossover = "BEARISH (Cross Below)"

    if latest_price is None or previous_price in (None, 0):
        raise HTTPException(status_code=500, detail=f"Invalid pricing data returned for {normalized_symbol}.")

    change = latest_price - previous_price
    change_percent = (change / previous_price) * 100

    chart = [
        {
            "date": index.strftime("%Y-%m-%d"),
            "close": round(float(price), 2),
        }
        for index, price in close.tail(30).items()
    ]

    return {
        "symbol": normalized_symbol,
        "name": COMPANY_NAMES.get(normalized_symbol, normalized_symbol),
        "price": round(latest_price, 2),
        "change": round(change, 2),
        "change_percent": round(change_percent, 2),
        "RSI": round(latest_rsi, 2) if latest_rsi is not None else None,
        "MACD": round(latest_macd, 2) if latest_macd is not None else None,
        "MACD_Signal": round(latest_macd_signal, 2) if latest_macd_signal is not None else None,
        "MACD_Diff": round(latest_macd_diff, 2) if latest_macd_diff is not None else None,
        "MACD_Crossover": macd_crossover,
        "signal": _build_signal(latest_rsi, latest_macd),
        "history": chart,
    }


@app.get("/")
def home() -> dict[str, str]:
    return {"message": "AlphaPulse backend running"}


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/stock/{symbol}")
def analyze_stock(symbol: str) -> dict[str, Any]:
    return get_stock_snapshot(symbol)


@app.get("/stocks")
def list_stocks(symbols: str = Query(",".join(DEFAULT_SYMBOLS))) -> dict[str, list[dict[str, Any]]]:
    requested_symbols = [symbol.strip().upper() for symbol in symbols.split(",") if symbol.strip()]
    if not requested_symbols:
        raise HTTPException(status_code=400, detail="At least one stock symbol is required.")

    data = [get_stock_snapshot(symbol) for symbol in requested_symbols]
    return {"stocks": data}

@app.post("/buy")
async def buy_stock(transaction: TransactionCreate, current_user: User = Depends(get_current_user)):
    async with async_session() as session:
        new_transaction = Transaction(
            user_id=current_user.id,
            ticker=transaction.ticker.upper(),
            price=transaction.price,
            quantity=transaction.quantity,
            type="BUY"
        )
        session.add(new_transaction)
        await session.commit()
    return {"message": "Purchase recorded"}

@app.post("/sell")
async def sell_stock(transaction: TransactionCreate, current_user: User = Depends(get_current_user)):
    async with async_session() as session:
        new_tx = Transaction(
            user_id=current_user.id,
            ticker=transaction.ticker.upper(),
            price=transaction.price,
            quantity=transaction.quantity,
            type="SELL"
        )
        session.add(new_tx)
        await session.commit()
    return {"message": "Sale recorded"}

@app.get("/portfolio")
async def get_portfolio(current_user: User = Depends(get_current_user)):
    async with async_session() as session:
        # Get user transactions
        result = await session.execute(
            select(Transaction).where(Transaction.user_id == current_user.id)
        )
        transactions = result.scalars().all()

        holdings = {}
        for tx in transactions:
            ticker = tx.ticker
            if ticker not in holdings:
                holdings[ticker] = {"quantity": 0, "total_cost": 0.0}
            
            if tx.type == "BUY":
                holdings[ticker]["quantity"] += tx.quantity
                holdings[ticker]["total_cost"] += tx.price * tx.quantity
            else:
                holdings[ticker]["quantity"] -= tx.quantity
                # For weighted avg cost basis, we don't adjust total_cost on sell
        
        portfolio_data = []
        total_value = 0.0
        total_cost = 0.0

        for ticker, data in holdings.items():
            if data["quantity"] > 0:
                try:
                    current_data = get_stock_snapshot(ticker)
                    current_price = current_data["price"]
                except:
                    current_price = 0.0
                
                avg_price = data["total_cost"] / data["quantity"] if data["quantity"] > 0 else 0
                value = current_price * data["quantity"]
                total_value += value
                total_cost += data["total_cost"]
                
                portfolio_data.append({
                    "ticker": ticker,
                    "quantity": data["quantity"],
                    "avg_price": avg_price,
                    "current_price": current_price,
                    "profit_loss": value - data["total_cost"]
                })
        
        return {
            "total_value": total_value,
            "total_profit_loss": total_value - total_cost,
            "holdings": portfolio_data
        }

@app.get("/history")
async def get_history(current_user: User = Depends(get_current_user)):
    async with async_session() as session:
        result = await session.execute(
            select(Transaction).where(Transaction.user_id == current_user.id).order_by(Transaction.timestamp.desc())
        )
        history = result.scalars().all()
        return history

@app.get("/scan")
async def scan_market(strategy: str = Query("aggressive"), current_user: User = Depends(get_current_user)):
    """Scan top 5 stocks and return AI rankings"""
    if not ai_rate_limiter.is_allowed(current_user.id):
        raise HTTPException(
            status_code=429, 
            detail="Market scan rate limit exceeded. Please wait a minute."
        )
    
    top_stocks = ["AAPL", "TSLA", "NVDA", "MSFT", "AMZN"]
    tasks = [recommend_stock(budget=1000, strategy=strategy, symbol=symbol) for symbol in top_stocks]
    results = await asyncio.gather(*tasks)
    
    # Sort by agreement_score and confidence
    ranked = sorted(
        results, 
        key=lambda x: (x["final"]["agreement_score"], x["final"]["confidence"]), 
        reverse=True
    )
    
    return {"top_picks": ranked[:3]}

async def recommend_stock(budget: float, strategy: str, symbol: str, explain_simple: bool = False) -> dict[str, Any]:
    """Internal helper for single stock recommendation (re-used for scanning)"""
    # Check cache
    cache_key = f"{symbol}_{strategy}_{explain_simple}"
    if cache_key in recommendation_cache:
        cached_data, timestamp = recommendation_cache[cache_key]
        if (datetime.utcnow() - timestamp).total_seconds() < CACHE_TTL:
            return cached_data

    # Fetch snapshot for the symbol
    try:
        data = get_stock_snapshot(symbol)
    except Exception:
        # Fallback if yfinance fails
        return {
            "bullish": {"agent": "bullish", "decision": "HOLD", "confidence": 50, "reasoning": "Data unavailable."},
            "bearish": {"agent": "bearish", "decision": "HOLD", "confidence": 50, "reasoning": "Data unavailable."},
            "quant": {"agent": "quant", "decision": "HOLD", "confidence": 50, "reasoning": "Data unavailable."},
            "final": {"final_decision": "HOLD", "stock": symbol, "quantity": 0, "confidence": 0, "risk_level": "HIGH", "agreement_score": 0.0, "final_reasoning": "Could not fetch market data.", "price": 0.0}
        }
    
    strategy_context = {
        "conservative": "Focus on stability, dividends, and low volatility.",
        "aggressive": "Focus on high growth, momentum, and volatility.",
        "long_term": "Focus on 5-10 year fundamental outlook."
    }.get(strategy.lower(), "Focus on growth.")

    # Analyst Prompts
    bull_prompt = f"Bullish Analyst for {symbol} ({strategy}): {strategy_context}. Data: {data}. Return JSON with 'agent', 'decision', 'confidence', 'reasoning'."
    bear_prompt = f"Bearish Analyst for {symbol} ({strategy}): {strategy_context}. Data: {data}. Return JSON with 'agent', 'decision', 'confidence', 'reasoning'."
    quant_prompt = f"Quant Analyst for {symbol} ({strategy}): RSI: {data['RSI']}, MACD: {data['MACD']}. Return JSON with 'agent', 'decision', 'confidence', 'reasoning'."

    bull_task = client.chat.completions.create(model="gpt-4o-mini", messages=[{"role": "user", "content": bull_prompt}], response_format={"type": "json_object"})
    bear_task = client.chat.completions.create(model="gpt-4o-mini", messages=[{"role": "user", "content": bear_prompt}], response_format={"type": "json_object"})
    quant_task = client.chat.completions.create(model="gpt-4o-mini", messages=[{"role": "user", "content": quant_prompt}], response_format={"type": "json_object"})
    
    bull_resp, bear_resp, quant_resp = await asyncio.gather(bull_task, bear_task, quant_task)
    
    # Log usage
    for resp, agent in zip([bull_resp, bear_resp, quant_resp], ["bullish", "bearish", "quant"]):
        logger.info(f"LLM Success: {agent}", extra={
            "usage": {
                "prompt_tokens": resp.usage.prompt_tokens,
                "completion_tokens": resp.usage.completion_tokens,
                "total_tokens": resp.usage.total_tokens
            }
        })

    import json
    bull_data = json.loads(bull_resp.choices[0].message.content)
    bear_data = json.loads(bear_resp.choices[0].message.content)
    quant_data = json.loads(quant_resp.choices[0].message.content)

    simple_instruction = "EXPLAIN IN SIMPLE, JARGON-FREE LANGUAGE FOR A BEGINNER." if explain_simple else "Use professional financial terminology."
    
    manager_prompt = f"""
    You are a Senior Hedge Fund Manager. 
    Task: Decide for {symbol} based on:
    Bullish: {bull_data}
    Bearish: {bear_data}
    Quant: {quant_data}
    
    Instruction: {simple_instruction}
    
    Return JSON: {{'final_decision', 'stock', 'quantity', 'confidence', 'risk_level', 'agreement_score', 'final_reasoning'}}
    """
    
    final_resp = await client.chat.completions.create(model="gpt-4o", messages=[{"role": "user", "content": manager_prompt}], response_format={"type": "json_object"})
    logger.info("LLM Success: manager", extra={
        "usage": {
            "prompt_tokens": final_resp.usage.prompt_tokens,
            "completion_tokens": final_resp.usage.completion_tokens,
            "total_tokens": final_resp.usage.total_tokens
        }
    })
    final_verdict = json.loads(final_resp.choices[0].message.content)
    final_verdict["price"] = data["price"]
    final_verdict["quantity"] = int(budget / data["price"]) if data["price"] > 0 else 0

    result = {
        "bullish": bull_data,
        "bearish": bear_data,
        "quant": quant_data,
        "final": final_verdict
    }
    
    # ... remaining recommendations logic ...
    
    # Save to cache
    recommendation_cache[cache_key] = (result, datetime.utcnow())
    return result

@app.on_event("startup")
async def startup_event():
    # Pre-cache top stocks on startup to avoid cold starts for /scan
    logger.info("Pre-caching top stocks for Market Scanner...")
    top_stocks = ["AAPL", "TSLA", "NVDA", "MSFT", "AMZN"]
    # We run them sequentially to avoid overwhelming LLM if rate limits are tight initially
    for stock in top_stocks:
        try:
            await recommend_stock(budget=1000, strategy="aggressive", symbol=stock)
            logger.info(f"Pre-cached {stock}")
        except Exception as e:
            logger.error(f"Failed to pre-cache {stock}: {e}")

@app.post("/recommend")
async def api_recommend_stock(
    request: RecommendationRequest,
    current_user: User = Depends(get_current_user)
):
    if not ai_rate_limiter.is_allowed(current_user.id):
        raise HTTPException(
            status_code=429, 
            detail="AI Rate limit exceeded. Please wait a minute before requesting another analysis."
        )
    
    target_symbol = request.symbol or "AAPL"
    return await recommend_stock(
        budget=request.budget, 
        strategy=request.strategy, 
        symbol=target_symbol, 
        explain_simple=request.explain_simple
    )


@app.get("/ai-analysis/{symbol}")
async def analyze_stock_optimistic(symbol: str) -> dict[str, Any]:
    # 1. Fetch current data for the requested stock
    try:
        data = get_stock_snapshot(symbol)
    except Exception as e:
        raise HTTPException(status_code=404, detail=str(e))

    # 2. Stage 1: Fast Optimistic Reasoning (Persona: Optimistic Analyst)
    stage1_prompt = f"""
    You are a highly optimistic stock market analyst.
    Based on the following data:
    - Stock: {data['symbol']}
    - Current Price: {data['price']}
    - RSI: {data['RSI']}
    - MACD: {data['MACD']}
    - Trend: {data['signal']}

    Your job:
    - Argue WHY this stock is a strong BUY
    - Focus only on positive signals
    - Ignore risks unless critical
    """

    try:
        # LLM 1 (Fast Reasoning) - Using gpt-4o-mini
        fast_resp = await client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[{"role": "user", "content": stage1_prompt}]
        )
        optimistic_view = fast_resp.choices[0].message.content

        # Stage 2: Synthesis & Judge (Persona: Final Judge / Pro Analyst)
        final_prompt = f"""
        You are the Final Investment Judge. You have an initial bullish argument from an analyst:
        "{optimistic_view}"

        Your job is to finalize the analysis for {data['symbol']}. 
        Review the metrics (Price: {data['price']}, RSI: {data['RSI']}, MACD: {data['MACD']}) 
        and provide a high-confidence recommendation.
        
        Return ONLY a JSON object:
        {{
          "decision": "BUY",
          "confidence": 0-100,
          "reasoning": "..."
        }}
        """

        # LLM 4 (Judge) - Using gpt-4o for deeper reasoning
        final_resp = await client.chat.completions.create(
            model="gpt-4o",
            messages=[{"role": "user", "content": final_prompt}],
            response_format={"type": "json_object"}
        )
        
        import json
        return json.loads(final_resp.choices[0].message.content)

    except Exception:
        # Simplified Fallback logic if any LLM call fails
        return {
            "decision": "BUY",
            "confidence": 75,
            "reasoning": f"Automated technical analysis indicates {data['symbol']} is in a favorable position. RSI ({data['RSI']}) suggests momentum is building toward a bullish breakout."
        }


@app.get("/bear-analysis/{symbol}")
async def analyze_stock_pessimistic(symbol: str) -> dict[str, Any]:
    # 1. Fetch current data for the requested stock
    try:
        data = get_stock_snapshot(symbol)
    except Exception as e:
        raise HTTPException(status_code=404, detail=str(e))

    # 2. Stage 1: Fast Cautious Reasoning (Persona: Pessimistic Analyst)
    stage1_prompt = f"""
    You are a highly cautious and pessimistic analyst.
    Based on the following data:
    - Stock: {data['symbol']}
    - Current Price: {data['price']}
    - RSI: {data['RSI']}
    - MACD: {data['MACD']}
    - Trend: {data['signal']}

    Your job:
    - Focus on risks
    - Highlight why this stock is BAD
    - Suggest avoiding or selling
    """

    try:
        # LLM 1 (Fast Reasoning) - Using gpt-4o-mini
        fast_resp = await client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[{"role": "user", "content": stage1_prompt}]
        )
        pessimistic_view = fast_resp.choices[0].message.content

        # Stage 2: Synthesis & Judge (Persona: Final Judge / Cautious Specialist)
        final_prompt = f"""
        You are the Cautious Investment Judge. You have an initial bearish argument from an analyst:
        "{pessimistic_view}"

        Your job is to finalize the analysis for {data['symbol']}. 
        Focus strictly on the downside risks and why one might want to SELL or AVOID.
        
        Return ONLY a JSON object:
        {{
          "decision": "SELL or AVOID",
          "confidence": 0-100,
          "reasoning": "..."
        }}
        """

        # LLM 4 (Judge) - Using gpt-4o for deeper reasoning
        final_resp = await client.chat.completions.create(
            model="gpt-4o",
            messages=[{"role": "user", "content": final_prompt}],
            response_format={"type": "json_object"}
        )
        
        import json
        return json.loads(final_resp.choices[0].message.content)

    except Exception:
        # Simplified Fallback logic if any LLM call fails
        return {
            "decision": "SELL or AVOID",
            "confidence": 65,
            "reasoning": f"Caution: Indicators for {data['symbol']} suggest potential weakness. RSI ({data['RSI']}) may be flagging an overextended state or lack of conviction. Risk-averse investors may consider trimming positions."
        }


@app.get("/quant-analysis/{symbol}")
async def analyze_stock_quant(symbol: str) -> dict[str, Any]:
    # 1. Fetch current data for the requested stock
    try:
        data = get_stock_snapshot(symbol)
    except Exception as e:
        raise HTTPException(status_code=404, detail=str(e))

    # 2. Stage 1: Logical Quantitative Reasoning (Persona: Neutral Quant Analyst)
    stage1_prompt = f"""
    You are a neutral quantitative analyst.
    Systematic Rules:
    - RSI < 30 → Oversold (buy signal)
    - RSI > 70 → Overbought (sell signal)
    - MACD crossover → trend change

    Analyze the following data based on these rules:
    - Stock: {data['symbol']}
    - Current Price: {data['price']}
    - RSI: {data['RSI']}
    - MACD: {data['MACD']}
    - MACD Signal: {data['MACD_Signal']}
    - MACD Diff: {data['MACD_Diff']}
    - MACD Crossover: {data['MACD_Crossover']}
    - Trend: {data['signal']}

    Return a balanced, data-driven analysis.
    """

    try:
        # LLM 1 (Fast Reasoning) - Using gpt-4o-mini
        fast_resp = await client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[{"role": "user", "content": stage1_prompt}]
        )
        quant_view = fast_resp.choices[0].message.content

        # Stage 2: Synthesis & Format (Persona: Data Scientist / Quant Judge)
        final_prompt = f"""
        You are a Data Scientist specialization in financial formatting. 
        You have a quantitative analysis:
        "{quant_view}"

        Finalize the analysis for {data['symbol']}. 
        Provide a balanced recommendation (BUY, SELL, or HOLD) based strictly on the quantitative rules.
        
        Return ONLY a JSON object:
        {{
          "decision": "BUY/SELL/HOLD",
          "confidence": 0-100,
          "reasoning": "..."
        }}
        """

        # LLM 4 (Judge) - Using gpt-4o
        final_resp = await client.chat.completions.create(
            model="gpt-4o",
            messages=[{"role": "user", "content": final_prompt}],
            response_format={"type": "json_object"}
        )
        
        import json
        return json.loads(final_resp.choices[0].message.content)

    except Exception:
        # Fallback logic
        decision = "HOLD"
        if data['RSI'] < 30: decision = "BUY"
        elif data['RSI'] > 70: decision = "SELL"
        
        return {
            "decision": decision,
            "confidence": 70,
            "reasoning": f"Quantitative assessment for {data['symbol']} shows RSI at {data['RSI']} and MACD at {data['MACD']}. Following systematic rules, the current stance is {decision}."
        }
