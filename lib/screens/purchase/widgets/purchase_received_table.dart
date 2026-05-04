import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PurchaseReceivedTable extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const PurchaseReceivedTable({
    super.key,
    required this.data,
  });

  /// 📅 FORMAT DATE (SAFE)
  String _formatDate(dynamic raw) {
    try {
      if (raw == null) return '-';
      return DateFormat('dd-MM-yyyy').format(DateTime.parse(raw.toString()));
    } catch (_) {
      return raw.toString();
    }
  }

  /// 💰 FORMAT AMOUNT (WITH COMMA)
  String _formatAmount(dynamic value) {
    double val = 0;

    if (value != null) {
      if (value is num) {
        val = value.toDouble();
      } else {
        val = double.tryParse(value.toString()) ?? 0;
      }
    }

    final formatter = NumberFormat('#,##,##0.00');
    return "₹${formatter.format(val)}";
  }

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text("No Data Found"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index];

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🔹 HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item['invoice_no']?.toString() ?? item['id'].toString(),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      _formatDate(item['date']),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                /// 🔹 VENDOR
                Row(
                  children: [
                    const Icon(Icons.store, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item['vendor'] ?? '-',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                /// 🔹 AMOUNTS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _amountBox("Total", item['grand_total']),
                    _amountBox("Paid", item['paid_amount']),
                    _amountBox("Balance", item['balance']),
                  ],
                ),

                const SizedBox(height: 12),

                /// 🔹 STATUS
                Align(
                  alignment: Alignment.centerRight,
                  child: _paymentStatus(item['status']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 💰 AMOUNT BOX
  Widget _amountBox(String title, dynamic value) {
    Color color;

    if (title == "Paid") {
      color = Colors.green;
    } else if (title == "Balance") {
      color = Colors.red;
    } else {
      color = Colors.black87;
    }

    return Expanded(
      // ✅ equal spacing
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),

          /// 🔥 BIG AMOUNT TEXT
          Text(
            _formatAmount(value),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18, // ✅ INCREASED SIZE
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// 🔴🟢 STATUS BADGE
  Widget _paymentStatus(dynamic status) {
    String text = status?.toString() ?? "Unpaid";

    Color color;

    switch (text) {
      case "Paid":
        color = Colors.green;
        break;
      case "Partial":
        color = Colors.blue;
        break;
      default:
        color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
