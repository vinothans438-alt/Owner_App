import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PurchaseDetailsScreen extends StatelessWidget {
  final Map data;

  const PurchaseDetailsScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          /// 🔷 HEADER
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 10),
                const Text(
                  "Purchase Details",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          /// 🔷 BODY
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  /// 🔹 TOP SUMMARY CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade50, Colors.blue.shade100],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        /// ICON
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.shopping_bag,
                              color: Colors.blue),
                        ),

                        const SizedBox(width: 16),

                        /// DETAILS
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "PO #${data['id']}",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text("Vendor: ${data['vendor'] ?? ''}"),
                              const SizedBox(height: 4),
                              Text("Date: ${_formatDate(data['date'])}"),
                            ],
                          ),
                        ),

                        /// STATUS
                        _statusBadge(data['status']),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// 🔹 INFO GRID
                  Row(
                    children: [
                      _infoCard("Items", "${data['item_count'] ?? 0}",
                          Icons.list, Colors.blue),
                      const SizedBox(width: 10),
                      _infoCard("Quantity", "${data['total_qty'] ?? 0}",
                          Icons.inventory, Colors.green),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      _infoCard(
                        "Expected Date",
                        data['expected_date'] != null
                            ? _formatDate(data['expected_date'])
                            : "-",
                        Icons.calendar_today,
                        Colors.purple,
                      ),
                      const SizedBox(width: 10),
                      _infoCard(
                        "Status",
                        data['status'] ?? '',
                        Icons.info,
                        Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 INFO CARD
  Widget _infoCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 STATUS BADGE
  Widget _statusBadge(String status) {
    final isDone = status == "Completed";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDone ? Colors.green.shade100 : Colors.orange.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: isDone ? Colors.green : Colors.orange,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 🔹 FORMAT DATE
  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return '';

    try {
      final parsed = DateTime.parse(date);
      return DateFormat('dd-MM-yyyy').format(parsed);
    } catch (e) {
      return date;
    }
  }
}
