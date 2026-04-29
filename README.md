![AlphaPulse Banner](assets/banner.png)

# AlphaPulse Stock AI Assistant

An advanced, AI-powered stock market analysis and portfolio management system. This project combines a high-performance **FastAPI** backend with two premium mobile frontends: **Flutter** and **React Native**, providing real-time technical analysis, multi-agent AI investment insights, and secure portfolio tracking across platforms.

---

## 🚀 Project Overview

**AlphaPulse Stock AI** is designed to bridge the gap between complex market data and actionable insights. By leveraging technical indicators and state-of-the-art LLMs, it provides users with a "Hedge Fund in your pocket" experience.

### Key Components:
- **`backend/stock-ai-backend`**: A Python-based FastAPI server handling data ingestion, technical analysis (RSI, MACD), and AI-driven decision-making.
- **`frontend/flutter/AlphaPulseFlutter`**: A Flutter mobile application featuring a premium dark-themed UI and interactive charts.
- **`frontend/react-native/AlphaPulseReactNative`**: A React Native CLI application mirroring the premium UI and features of the Flutter version.

---

## 🛠️ Tech Stack

### Backend (`stock-ai-backend`)
- **Framework**: [FastAPI](https://fastapi.tiangolo.com/) (Asynchronous Python)
- **AI/LLM**: [OpenAI GPT-4o & GPT-4o-mini](https://openai.com/)
- **Market Data**: [yfinance](https://github.com/ranaroussi/yfinance)
- **Technical Analysis**: [ta-lib](https://github.com/mrjbq7/ta-lib) / [ta](https://github.com/bukosabino/ta)
- **Database**: [SQLite](https://www.sqlite.org/) with [SQLAlchemy](https://www.sqlalchemy.org/) (Async)
- **Auth**: JWT (JSON Web Tokens) with Bcrypt hashing
- **Task Scheduling**: Asyncio background tasks for alert monitoring

### Frontend (Flutter)
- **Framework**: [Flutter](https://flutter.dev/)
- **Charts**: [fl_chart](https://pub.dev/packages/fl_chart)
- **Icons**: [Lucide Icons](https://lucide.dev/)

### Frontend (React Native)
- **Framework**: [React Native CLI](https://reactnative.dev/)
- **Navigation**: [React Navigation](https://reactnavigation.org/)
- **Charts**: [react-native-chart-kit](https://github.com/indiespirit/react-native-chart-kit)
- **Icons**: [Lucide React Native](https://lucide.dev/guide/react-native)
- **State Management**: React Context API
- **Networking**: [Axios](https://axios-http.com/)

---

## ✨ Features

- **Multi-Agent AI Analysis**: Utilizes four distinct AI personas (Bullish, Bearish, Quant, and Manager) to reach a consensus on stock recommendations.
- **Technical Indicator Dashboard**: Real-time RSI and MACD tracking with automated crossover detection.
- **Market Scanner**: Automatically scans top stocks to identify high-confidence opportunities.
- **Portfolio Management**: Track buys/sells and calculate real-time profit/loss based on current market prices.
- **Smart Alerts**: Set triggers for price targets or technical conditions (e.g., RSI below 30).
- **Demo Mode**: Instant access with seeded data for testing features without a real portfolio.

---

## 📥 Installation & Setup

### Backend Setup
1. Navigate to the backend directory:
   ```bash
   cd backend/stock-ai-backend
   ```
2. Create and activate a virtual environment:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```
3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
4. Configure `.env` file:
   ```env
   OPENAI_API_KEY=your_key_here
   DATABASE_URL=sqlite+aiosqlite:///./stocks.db
   SECRET_KEY=your_secret_jwt_key
   ```
5. Run the server (Note: You will be prompted for a security code):
   ```bash
   uvicorn main:app --reload
   ```

### Flutter Setup
1. Navigate to the project: `cd frontend/flutter/AlphaPulseFlutter`
2. Get packages: `flutter pub get`
3. Run: `flutter run`

### React Native Setup
1. Navigate to the project: `cd frontend/react-native/AlphaPulseReactNative`
2. Install dependencies: `npm install`
3. Start Metro: `npx react-native start`
4. Run on Android: `npx react-native run-android`

---

## 📂 Directory Structure

```text
.
├── backend/
│   └── stock-ai-backend/       # FastAPI Backend Source
├── frontend/
│   ├── flutter/
│   │   └── AlphaPulseFlutter/  # Flutter Mobile App
│   └── react-native/
│       └── AlphaPulseReactNative/ # React Native App
├── README.md
├── LICENSE
└── .gitignore
```

---

## 🛡️ License
Distributed under a Proprietary License. See `LICENSE` for more information.
