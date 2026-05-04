import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class VendorReportWidget extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const VendorReportWidget({super.key, required this.data});

  String _money(dynamic v) {
    double val = 0;
    if (v != null) {
      if (v is num)
        val = v.toDouble();
      else
        val = double.tryParse(v.toString()) ?? 0;
    }
    return "₹${NumberFormat('#,##,##0.00').format(val)}";
  }

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text("No Vendor Data"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final vendor = data[index];

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExpansionTile(
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            childrenPadding: const EdgeInsets.all(12),

            /// 🔹 HEADER
            title: Text(
              vendor['vendor_name'] ?? 'Unknown',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),

            subtitle: Text(
              "Orders: ${vendor['order_count'] ?? 0}",
              style: const TextStyle(fontSize: 12),
            ),

            /// 🔹 SUMMARY ROW
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _amountBox("Total", vendor['total_amount'], Colors.black),
                  _amountBox("Paid", vendor['total_paid'], Colors.green),
                  _amountBox("Due", vendor['total_outstanding'], Colors.red),
                ],
              ),

              const SizedBox(height: 12),

              /// 🔹 ORDER LIST
              ..._buildOrders(vendor['orders'] ?? []),
            ],
          ),
        );
      },
    );
  }

  /// 💰 Amount Box
  Widget _amountBox(String title, dynamic value, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          _money(value),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  /// 📄 Orders inside vendor
  List<Widget> _buildOrders(List orders) {
    return orders.map<Widget>((o) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            /// Left
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  o['invoice_no']?.toString() ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  o['date'] ?? '',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),

            /// Right
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_money(o['total'])),
                Text(
                  "Due: ${_money(o['due'])}",
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                ),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }
}
