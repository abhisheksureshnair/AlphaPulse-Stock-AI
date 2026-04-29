import React, { useEffect, useState } from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { StatusBar } from 'react-native';
import { LayoutDashboard, Brain, Wallet, TrendingUp, Bell, User } from 'lucide-react-native';

import { AppColors } from './src/theme/colors';
import { AppProvider } from './src/context/AppContext';
import { AuthService } from './src/services/api';

import { DashboardScreen } from './src/screens/Dashboard/DashboardScreen';
import { AIAnalysisScreen } from './src/screens/AIAnalysis/AIAnalysisScreen';
import { AIInvestorScreen } from './src/screens/AIInvestor/AIInvestorScreen';
import { PortfolioScreen } from './src/screens/Portfolio/PortfolioScreen';
import { AlertsScreen } from './src/screens/Alerts/AlertsScreen';
import { ProfileScreen } from './src/screens/Profile/ProfileScreen';
import { LoginScreen } from './src/screens/Auth/LoginScreen';
import { StockDetailScreen } from './src/screens/StockDetail/StockDetailScreen';

const Tab = createBottomTabNavigator();
const Stack = createNativeStackNavigator();

function TabNavigator() {
  return (
    <Tab.Navigator
      screenOptions={{
        headerShown: false,
        tabBarStyle: {
          backgroundColor: AppColors.background,
          borderTopColor: 'rgba(255,255,255,0.05)',
          paddingBottom: 5,
          paddingTop: 5,
        },
        tabBarActiveTintColor: AppColors.neonGreen,
        tabBarInactiveTintColor: AppColors.mutedGrey,
        tabBarShowLabel: false,
      }}
    >
      <Tab.Screen 
        name="Dashboard" 
        component={DashboardScreen} 
        options={{ tabBarIcon: ({ color }) => <LayoutDashboard color={color} size={24} /> }}
      />
      <Tab.Screen 
        name="AIAnalysis" 
        component={AIAnalysisScreen} 
        options={{ tabBarIcon: ({ color }) => <Brain color={color} size={24} /> }}
      />
      <Tab.Screen 
        name="AIInvestor" 
        component={AIInvestorScreen} 
        options={{ tabBarIcon: ({ color }) => <Wallet color={color} size={24} /> }}
      />
      <Tab.Screen 
        name="Portfolio" 
        component={PortfolioScreen} 
        options={{ tabBarIcon: ({ color }) => <TrendingUp color={color} size={24} /> }}
      />
      <Tab.Screen 
        name="Alerts" 
        component={AlertsScreen} 
        options={{ tabBarIcon: ({ color }) => <Bell color={color} size={24} /> }}
      />
      <Tab.Screen 
        name="Profile" 
        component={ProfileScreen} 
        options={{ tabBarIcon: ({ color }) => <User color={color} size={24} /> }}
      />
    </Tab.Navigator>
  );
}

export default function App() {
  const [isAuthenticated, setIsAuthenticated] = useState(null);

  useEffect(() => {
    AuthService.getToken().then(token => setIsAuthenticated(!!token));
  }, []);

  if (isAuthenticated === null) return null;

  return (
    <SafeAreaProvider>
      <AppProvider>
        <StatusBar barStyle="light-content" backgroundColor={AppColors.background} />
        <NavigationContainer>
          <Stack.Navigator screenOptions={{ headerShown: false }}>
            {isAuthenticated ? (
              <>
                <Stack.Screen name="Main" component={TabNavigator} />
                <Stack.Screen name="StockDetail" component={StockDetailScreen} />
              </>
            ) : (
              <Stack.Screen name="Login" component={LoginScreen} />
            )}
          </Stack.Navigator>
        </NavigationContainer>
      </AppProvider>
    </SafeAreaProvider>
  );
}
