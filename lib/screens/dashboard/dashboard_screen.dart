import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/summary_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/responsive_scaffold.dart';
import '../../widgets/date_filter_bar.dart';
import '../../services/api_service.dart'; // Import the API Service

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _dashboardData;

  @override
  void initState() {
    super.initState();
    // Fetch the data from localhost as soon as the screen opens
    _dashboardData = _apiService.fetchDashboardStats();
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final today = _formatDate(DateTime.now());

    return ResponsiveScaffold(
      title: 'Dashboard',
      actions: [
        Stack(
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none_rounded, size: 28),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.errorColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        const CircleAvatar(
          radius: 18,
          backgroundImage:
              NetworkImage('https://i.pravatar.cc/150?u=bakery_owner'),
        ),
        const SizedBox(width: 16),
      ],
      filters: DateFilterBar(
        onFilterChanged: (filter) {
          // You can trigger a new API call here when filters change
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildWelcomeCard(today),
            const SizedBox(height: 32),
            const SectionHeader(title: 'Business Overview'),
            const SizedBox(height: 16),

            // --- LIVE DATA FUTURE BUILDER ---
            FutureBuilder<Map<String, dynamic>>(
              future: _dashboardData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      'Connection Error: ${snapshot.error}\nMake sure your local server (XAMPP/Laravel) is running!',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data == null) {
                  return const Text("No data received from server.");
                }

                // If success, build the grid with REAL DATA!
                return _buildStatsGrid(context, snapshot.data!);
              },
            ),
            // --------------------------------

            const SizedBox(height: 32),
            // (You can add Live Alerts back here if your API provides them)
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(String date) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withValues(alpha: 0.8)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome, Master Baker!',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Here is what\'s happening in your bakery today, $date.',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.auto_graph_rounded, color: Colors.white, size: 48),
        ],
      ),
    );
  }

  // --- UPDATED GRID MATCHING YOUR IMAGE ---
  Widget _buildStatsGrid(BuildContext context, Map<String, dynamic> data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 1000
            ? 3
            : (constraints.maxWidth > 600 ? 2 : 1);

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.8, // Adjusted ratio to match the web cards
          children: [
            // Mapping keys based on standard API responses.
            // Change 'gross_sales', 'net_sales', etc., to match the EXACT keys your Laravel API returns!
            SummaryCard(
                title: 'GROSS SALES',
                value: '₹${data['gross_sales'] ?? '0.00'}',
                icon: Icons.trending_up,
                iconColor: Colors.green),
            SummaryCard(
                title: 'DISCOUNTS',
                value: '₹${data['discounts'] ?? '0.00'}',
                icon: Icons.money_off,
                iconColor: Colors.orange),
            SummaryCard(
                title: 'REFUNDS',
                value: '₹${data['refunds'] ?? '0.00'}',
                icon: Icons.assignment_return,
                iconColor: Colors.red),
            SummaryCard(
                title: 'NET SALES',
                value: '₹${data['net_sales'] ?? '0.00'}',
                icon: Icons.account_balance_wallet,
                iconColor: Colors.blue),
            SummaryCard(
                title: 'TAXES',
                value: '₹${data['taxes'] ?? '0.00'}',
                icon: Icons.receipt,
                iconColor: Colors.grey),
            SummaryCard(
                title: 'NET TOTAL',
                value: '₹${data['net_total'] ?? '0.00'}',
                icon: Icons.calculate,
                iconColor: Colors.indigo),
          ],
        );
      },
    );
  }
}
