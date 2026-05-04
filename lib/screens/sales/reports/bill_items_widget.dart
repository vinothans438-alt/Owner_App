import 'package:flutter/material.dart';

class BillItemsWidget extends StatelessWidget {
  final Map<String, dynamic> bill;

  const BillItemsWidget({super.key, required this.bill});

  @override
  Widget build(BuildContext context) {
    final items =
        (bill['items'] ?? bill['bill_items'] ?? bill['details'] ?? []) as List;

    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text("No items found"),
      );
    }

    return Column(
      children: items.map<Widget>((item) {
        final name = item['name'] ??
            item['item_name'] ??
            item['product_name'] ??
            'Unknown';

        final qty = item['qty'] ?? item['quantity'] ?? item['count'] ?? 0;

        final price = item['price'] ?? item['rate'] ?? item['amount'] ?? 0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              Expanded(child: Text(name.toString())),
              Text(qty.toString()),
              const SizedBox(width: 20),
              Text(price.toString()),
            ],
          ),
        );
      }).toList(),
    );
  }
}
