import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/summary_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/responsive_layout.dart';
import 'transport_dummy.dart';

class TransportScreen extends StatelessWidget {
  const TransportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Logistics', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          Container(
            height: 220,
            width: double.infinity,
            decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fleet Status',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  
                  _buildStatsGrid(context),

                  const SizedBox(height: 32),
                  const SectionHeader(title: 'Active Trips'),
                  const SizedBox(height: 16),
                  _buildTripList(),

                  const SizedBox(height: 32),
                  const SectionHeader(title: 'Vehicle Status'),
                  const SizedBox(height: 16),
                  _buildVehicleGrid(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildGrid(2, 1.1),
      tablet: _buildGrid(3, 1.3),
      desktop: _buildGrid(3, 1.5),
    );
  }

  Widget _buildGrid(int crossAxisCount, double aspectRatio) {
    return GridView.count(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: aspectRatio,
      children: [
        SummaryCard(title: 'Active Trips', value: TransportDummy.summary['activeTrips'], icon: Icons.local_shipping_rounded, iconColor: AppTheme.primaryColor),
        SummaryCard(title: 'Fuel Spend', value: TransportDummy.summary['fuelExpense'], icon: Icons.local_gas_station_rounded, iconColor: Colors.deepOrange),
        SummaryCard(title: 'On-Time', value: '94%', icon: Icons.timer_rounded, iconColor: AppTheme.successColor),
      ],
    );
  }

  Widget _buildTripList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: TransportDummy.trips.length,
        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
        itemBuilder: (context, index) {
          final item = TransportDummy.trips[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.05),
              child: const Icon(Icons.route_rounded, color: AppTheme.primaryColor, size: 20),
            ),
            title: Text(item['route']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            subtitle: Text('Vehicle: ${item['vehicle']} • Driver: ${item['driver']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            trailing: _buildStatusBadge(item['status']!, item['status'] == 'Delivered' ? AppTheme.successColor : Colors.orange),
          );
        },
      ),
    );
  }

  Widget _buildVehicleGrid() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildVehicleCard('Truck A (WB 01)', 'Idle', Colors.grey),
        _buildVehicleCard('Van B (WB 02)', 'In Transit', Colors.orange),
        _buildVehicleCard('Truck C (WB 03)', 'Service', AppTheme.errorColor),
      ],
    );
  }

  Widget _buildVehicleCard(String title, String status, Color color) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
