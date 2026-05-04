import 'package:flutter/material.dart';

class StockBatchDetailScreen extends StatelessWidget {
  final dynamic item;

  const StockBatchDetailScreen({
    Key? key,
    required this.item,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double totalQty =
        double.tryParse((item['quantity'] ?? 0).toString()) ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),

      // ================= APP BAR =================

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          "Batch Stock Matrix",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // ================= BODY =================

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ================= HEADER =================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.grey.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'] ?? "Unknown Material",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        color: Colors.blue.shade700,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Batch Wise Stock Availability",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ================= TABLE =================

            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.grey.shade200,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: DataTable(
                  headingRowHeight: 54,
                  dataRowMinHeight: 60,
                  columnSpacing: 20,
                  horizontalMargin: 16,
                  dividerThickness: 0.5,
                  headingRowColor: MaterialStateProperty.all(
                    const Color(0xFFF1F5F9),
                  ),
                  columns: const [
                    DataColumn(
                      label: Text(
                        "BATCH",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "QTY",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "STATUS",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  rows: [
                    _buildRow("OLD BATCH", item['old_batch']),
                    _buildRow("BATCH 1", item['batch_1']),
                    _buildRow("BATCH 2", item['batch_2']),
                    _buildRow("BATCH 3", item['batch_3']),
                    _buildRow("BATCH 4", item['batch_4']),
                    _buildRow("BATCH 5", item['batch_5']),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ================= TOTAL STOCK =================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F2FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.blue.shade200,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "TOTAL STOCK",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    totalQty.toString(),
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ================= NOTE =================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.orange.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Green highlighted batches indicate active stock availability.",
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= ROW BUILDER =================

  static DataRow _buildRow(String batchName, dynamic value) {
    final qty = double.tryParse((value ?? 0).toString()) ?? 0;

    final bool hasStock = qty > 0;

    return DataRow(
      cells: [
        // BATCH NAME

        DataCell(
          Text(
            batchName,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // QTY

        DataCell(
          Text(
            qty > 0 ? qty.toString() : "-",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: hasStock ? Colors.green.shade700 : Colors.grey,
            ),
          ),
        ),

        // STATUS

        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: hasStock ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              hasStock ? "AVAILABLE" : "EMPTY",
              style: TextStyle(
                color: hasStock ? Colors.green.shade700 : Colors.red.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
