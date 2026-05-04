import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'screens/login/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/sales/sales_screen.dart';
import 'screens/production/production_screen.dart';
import 'screens/purchase/purchase_screen.dart';
import 'screens/admin_summary/admin_summary_screen.dart';
import 'screens/gst_report/gst_report_screen.dart';
import 'screens/stockmatrix/stock_matrix_screen.dart';
import 'screens/accountant_summary/accountant_summary_screen.dart';
import 'screens/transport/transport_screen.dart';
import 'screens/reports/reports_screen.dart';

void main() {
  runApp(const BakeryOwnerApp());
}

class BakeryOwnerApp extends StatelessWidget {
  const BakeryOwnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bakery Owner Dashboard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/sales': (context) => const SalesScreen(),
        '/production': (context) => const ProductionScreen(),
        '/purchase': (context) => const PurchaseScreen(),
        '/admin_summary': (context) => const AdminSummaryScreen(),
        '/gst_report': (context) =>
            const GSTReportScreen(), // ✅ after fixing constructor
        '/stock_matrix': (context) => const StockMatrixScreen(),
        '/accountant_summary': (context) => const AccountantSummaryScreen(),
        '/transport': (context) => const TransportScreen(),
        '/reports': (context) => const ReportsScreen(),
      },
    );
  }
}
