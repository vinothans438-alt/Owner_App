import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RawMaterialStockTable extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const RawMaterialStockTable({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text("No Stock Data"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index];

        final stock = _toDouble(item['current_stock']);
        final unit = item['unit'] ?? 'KG';

        final status = _getStockStatus(stock);

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
                /// 🔹 MATERIAL NAME
                Text(
                  item['name'] ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                /// 🔹 STOCK VALUE
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Stock: ${_format(stock)} $unit",
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                    _statusChip(status),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 🔢 Convert safely
  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  /// 💰 Format number
  String _format(double value) {
    return NumberFormat('#,##0.##').format(value);
  }

  /// 🚦 Stock Status Logic
  String _getStockStatus(double stock) {
    if (stock <= 0) return "Out of Stock";
    if (stock < 10) return "Low";
    return "Good";
  }

  /// 🎨 Status UI
  Widget _statusChip(String status) {
    Color color;

    switch (status) {
      case "Good":
        color = Colors.green;
        break;
      case "Low":
        color = Colors.orange;
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
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
