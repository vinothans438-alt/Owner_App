import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BillViewScreen extends StatelessWidget {
  final Map<String, dynamic> bill;

  const BillViewScreen({super.key, required this.bill});

  @override
  Widget build(BuildContext context) {
    final amount = (bill['total'] is num)
        ? (bill['total'] as num).toDouble()
        : double.tryParse(bill['total'].toString()) ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bill Details"),
        backgroundColor: Colors.blue.shade800,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 3,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row("Bill No", bill['bill_number']),
                  _row("Time", bill['time']),
                  _row("Customer", "Walk-in"),
                  _row("Payment", bill['payment_method']),
                  const Divider(height: 30),
                  const Text(
                    "Items",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  ...List.generate(
                    (bill['items'] ?? []).length,
                    (index) {
                      final item = bill['items'][index];

                      final itemTotal = (item['total'] is num)
                          ? (item['total'] as num).toDouble()
                          : double.tryParse(item['total'].toString()) ?? 0;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(item['name'] ?? '')),
                            Text("${item['quantity']} x ${item['price']}"),
                            Text(_formatCurrency(itemTotal)),
                          ],
                        ),
                      );
                    },
                  ),
                  const Divider(height: 30),
                  _row(
                    "Total Amount",
                    _formatCurrency(amount),
                    isBold: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, dynamic value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value?.toString() ?? '',
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double value) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
    return formatter.format(value);
  }
}
