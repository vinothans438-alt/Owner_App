import 'package:flutter/material.dart';
import '../../widgets/summary_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/responsive_scaffold.dart';
import '../../widgets/date_filter_bar.dart';
import 'admin_summary_dummy.dart';

class AdminSummaryScreen extends StatelessWidget {
  const AdminSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'Admin & HR',
      filters: DateFilterBar(onFilterChanged: (f) {}),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Workforce Overview'),
            const SizedBox(height: 16),
            _buildStatsGrid(),
            const SizedBox(height: 32),
            const SectionHeader(title: 'Staff Distribution'),
            const SizedBox(height: 16),
            _buildRoleGrid(),
            const SizedBox(height: 32),
            const SectionHeader(title: 'Productivity'),
            const SizedBox(height: 16),
            _buildEfficiencyCard(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ===================== STATS =====================
  Widget _buildStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.3,
          children: [
            SummaryCard(
              title: 'Total Staff',
              value: AdminSummaryDummy.summary['totalEmployees'] ?? '0',
              icon: Icons.people_rounded,
              iconColor: Colors.blue,
            ),
            SummaryCard(
              title: 'Absent Today',
              value: AdminSummaryDummy.summary['absentToday'] ?? '0',
              icon: Icons.person_off_rounded,
              iconColor: Colors.red,
            ),
            SummaryCard(
              title: 'New Hires',
              value: AdminSummaryDummy.summary['newJoinings'] ?? '0',
              icon: Icons.person_add_rounded,
              iconColor: Colors.green,
            ),
          ],
        );
      },
    );
  }

  // ===================== ROLES =====================
  Widget _buildRoleGrid() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: AdminSummaryDummy.employeeRoles.map((r) {
        final role = r['role'] ?? '';
        final count = r['count'] ?? '0';

        return Container(
          width: 140,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            children: [
              const Icon(Icons.badge_rounded, color: Colors.blue, size: 24),
              const SizedBox(height: 12),
              Text(
                role,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                count,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ===================== EFFICIENCY =====================
  Widget _buildEfficiencyCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Overall Efficiency',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '85%',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: 0.85,
              backgroundColor: Colors.grey.shade100,
              color: Colors.green,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 12),
            Text(
              'Productivity is consistent with previous period',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
