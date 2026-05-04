import 'package:flutter/material.dart';
import '../../widgets/section_header.dart';
import '../../widgets/responsive_scaffold.dart';
import '../../widgets/date_filter_bar.dart';
import 'reports_dummy.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'Reports Hub',
      filters: DateFilterBar(onFilterChanged: (f) {}),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Business Intelligence'),
            const SizedBox(height: 8),
            Text(
              'Detailed stats and exportable reports',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            _buildStatsGrid(context),
            const SizedBox(height: 40),
            const SectionHeader(title: 'Recent Generations'),
            const SizedBox(height: 16),
            _buildRecentExports(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ================= REPORT GRID =================
  Widget _buildStatsGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 900
            ? 3
            : (constraints.maxWidth > 600 ? 2 : 1);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: ReportsDummy.reportList.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.6,
          ),
          itemBuilder: (context, index) {
            final report = ReportsDummy.reportList[index];

            final name = report['name'] ?? '';
            final description = report['description'] ?? '';

            return _buildReportCard(name, description);
          },
        );
      },
    );
  }

  // ================= REPORT CARD =================
  Widget _buildReportCard(String name, String description) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.analytics_rounded,
              color: Colors.blue,
              size: 24,
            ),
          ),
          const Spacer(),
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ================= EXPORT LIST =================
  Widget _buildRecentExports() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          _buildExportTile(
            'monthly_sales_march.pdf',
            '15 Mar 2024',
            Colors.red,
          ),
          _buildExportTile(
            'inventory_status.xlsx',
            '14 Mar 2024',
            Colors.green,
          ),
          _buildExportTile(
            'wastage_report_q1.pdf',
            '12 Mar 2024',
            Colors.red,
          ),
        ],
      ),
    );
  }

  // ================= EXPORT TILE =================
  Widget _buildExportTile(String filename, String date, Color iconColor) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconColor.withValues(alpha: 0.1),
        child: Icon(
          filename.endsWith('.pdf')
              ? Icons.picture_as_pdf_rounded
              : Icons.table_view_rounded,
          color: iconColor,
          size: 20,
        ),
      ),
      title: Text(
        filename,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        'Exported on $date',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade500,
        ),
      ),
      trailing: IconButton(
        onPressed: () {},
        icon: const Icon(
          Icons.cloud_download_rounded,
          color: Colors.blue,
        ),
      ),
    );
  }
}
