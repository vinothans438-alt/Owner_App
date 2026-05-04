import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 32,
                bottom: 32,
                left: 24,
                right: 24),
            width: double.infinity,
            decoration: AppTheme.professionalGradient,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white24,
                  child:
                      Icon(Icons.person_outline, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Bakery Owner',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Administrator',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildMenuItem(context, 'Dashboard', Icons.grid_view_outlined,
                    '/dashboard'),
                _buildMenuItem(
                    context, 'Sales', Icons.analytics_outlined, '/sales'),
                _buildMenuItem(context, 'Production',
                    Icons.precision_manufacturing_outlined, '/production'),
                _buildMenuItem(context, 'Purchase',
                    Icons.shopping_cart_outlined, '/purchase'),
                _buildMenuItem(context, 'Admin Summary',
                    Icons.manage_accounts_outlined, '/admin_summary'),
                _buildMenuItem(context, 'GST Report',
                    Icons.receipt_long_outlined, '/gst_report'),
                _buildMenuItem(
                  context,
                  'Available Stock Matrix',
                  Icons.inventory_2_outlined,
                  '/stock_matrix',
                ),
                _buildMenuItem(context, 'Accountant',
                    Icons.account_balance_outlined, '/accountant_summary'),
                _buildMenuItem(context, 'Transport',
                    Icons.local_shipping_outlined, '/transport'),
                _buildMenuItem(
                    context, 'Reports', Icons.description_outlined, '/reports'),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListTile(
              leading:
                  const Icon(Icons.logout_rounded, color: AppTheme.errorColor),
              title: const Text('Sign Out',
                  style: TextStyle(
                      color: AppTheme.errorColor, fontWeight: FontWeight.bold)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
      BuildContext context, String title, IconData icon, String route) {
    final bool isActive = ModalRoute.of(context)?.settings.name == route;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? AppTheme.primaryColor : Colors.grey.shade600,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? AppTheme.primaryColor : const Color(0xFF323130),
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        selected: isActive,
        selectedTileColor: AppTheme.primaryColor.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () {
          if (!isActive) {
            Navigator.pushReplacementNamed(context, route);
          } else {
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}
