import 'package:flutter/material.dart';
import 'screens/login/login_screen.dart';
import 'theme/app_theme.dart';

class BakeryOwnerApp extends StatelessWidget {
  const BakeryOwnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bakery Owner App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        // '/dashboard': (context) => const DashboardScreen(),
      },
    );
  }
}
