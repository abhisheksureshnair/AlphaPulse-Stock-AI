import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alpha_pulse/screens/ai_analysis.dart';
import 'package:alpha_pulse/screens/ai_investor_screen.dart';
import 'package:alpha_pulse/screens/alerts_screen.dart';
import 'package:alpha_pulse/screens/dashboard.dart';
import 'package:alpha_pulse/screens/profile.dart';
import 'package:alpha_pulse/screens/stock_detail.dart';
import 'package:alpha_pulse/screens/portfolio_screen.dart';
import 'package:alpha_pulse/state/app_state.dart';
import 'package:alpha_pulse/theme/colors.dart';
import 'package:alpha_pulse/theme/theme.dart';
import 'package:alpha_pulse/screens/login_screen.dart';
import 'package:alpha_pulse/services/auth_service.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const StockAssistantApp(),
    ),
  );
}

class StockAssistantApp extends StatelessWidget {
  const StockAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ALPHAPULSE',
      theme: AppTheme.darkTheme.copyWith(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
            TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthGate()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.neonGreen.withOpacity(0.1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonGreen.withOpacity(0.2),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Icon(Icons.psychology, size: 80, color: AppColors.neonGreen),
            ),
            const SizedBox(height: 40),
            const Text(
              'ALPHAPULSE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'AI STOCK ASSISTANT',
              style: TextStyle(
                color: AppColors.neonGreen.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService.isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator(color: AppColors.neonGreen)),
          );
        }
        
        if (snapshot.data == true) {
          return const MainScreen();
        }
        
        return const LoginScreen();
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final ticker = context.watch<AppState>().selectedTicker;
    
    // Screens mapping to bottom nav indices
    final screens = [
      const DashboardScreen(),
      AIAnalysisScreen(ticker: ticker),
      const AIInvestorScreen(),
      const PortfolioScreen(),
      const AlertsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.background,
          selectedItemColor: AppColors.neonGreen,
          unselectedItemColor: AppColors.mutedGrey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.psychology_outlined), label: 'AI'),
            BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Invest'),
            BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Portfolio'),
            BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), label: 'Alerts'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
          ],
          showSelectedLabels: false,
          showUnselectedLabels: false,
        ),
      ),
    );
  }
}
