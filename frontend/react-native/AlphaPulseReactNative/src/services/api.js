import AsyncStorage from '@react-native-async-storage/async-storage';
import axios from 'axios';
import { Platform } from 'react-native';

const BASE_URL = Platform.OS === 'android' ? 'http://10.0.2.2:8000' : 'http://127.0.0.1:8000';

const api = axios.create({
  baseURL: BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

api.interceptors.request.use(async (config) => {
  const token = await AsyncStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

export const ApiService = {
  fetchStockData: (symbol) => api.get(`/stock/${symbol}`).then(res => res.data),
  fetchStocks: (symbols) => {
    const query = symbols ? `?symbols=${symbols.join(',')}` : '';
    return api.get(`/stocks${query}`).then(res => res.data.stocks);
  },
  fetchPortfolio: () => api.get('/portfolio').then(res => res.data),
  buyStock: (data) => api.post('/buy', data).then(res => res.data),
  sellStock: (data) => api.post('/sell', data).then(res => res.data),
  fetchAlerts: () => api.get('/alerts').then(res => res.data),
  createAlert: (data) => api.post('/alerts', data).then(res => res.data),
  fetchHistory: () => api.get('/history').then(res => res.data),
  scanMarket: (strategy = 'aggressive') => api.get(`/scan?strategy=${strategy}`).then(res => res.data),
  fetchRecommendation: (data) => 
    api.post('/recommend', data).then(res => res.data),
  fetchOptimisticAnalysis: (symbol) => api.get(`/ai-analysis/${symbol}`).then(res => res.data),
  fetchPessimisticAnalysis: (symbol) => api.get(`/bear-analysis/${symbol}`).then(res => res.data),
};

export const AuthService = {
  login: (data) => api.post('/token', new URLSearchParams(data)).then(res => res.data),
  register: (data) => api.post('/register', data).then(res => res.data),
  demoLogin: () => api.post('/auth/demo').then(res => res.data),
  logout: () => AsyncStorage.removeItem('token'),
  setToken: (token) => AsyncStorage.setItem('token', token),
  getToken: () => AsyncStorage.getItem('token'),
};
