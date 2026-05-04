// ignore_for_file: unused_local_variable, unused_element

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class GSTReportScreen extends StatefulWidget {
  const GSTReportScreen({Key? key}) : super(key: key);

  @override
  _GSTReportScreenState createState() => _GSTReportScreenState();
}

class _GSTReportScreenState extends State<GSTReportScreen> {
  Widget _gstSection(String title, dynamic sales, dynamic cgst, dynamic sgst) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text("Sales: ₹$sales"),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("CGST: ₹$cgst"),
              Text("SGST: ₹$sgst"),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateRange() async {
    DateTime tempFrom = fromDate;
    DateTime tempTo = toDate;

    final now = DateTime.now();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Select Date Range"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text("From Date"),
              subtitle: Text(
                DateFormat('dd-MM-yyyy').format(tempFrom),
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: tempFrom,
                  firstDate: DateTime(2023),
                  lastDate: now,
                );

                if (picked != null) {
                  tempFrom = picked;
                }
              },
            ),
            ListTile(
              title: const Text("To Date"),
              subtitle: Text(
                DateFormat('dd-MM-yyyy').format(tempTo),
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: tempTo,
                  firstDate: DateTime(2023),
                  lastDate: now,
                );

                if (picked != null) {
                  tempTo = picked;
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                fromDate = tempFrom;
                toDate = tempTo;
              });

              Navigator.pop(context);

              // ✅ RELOAD GST
              loadGSTReport();
            },
            child: const Text("Apply"),
          ),
        ],
      ),
    );
  }

  List<String> tableColumns = [];

  DateTime fromDate = DateTime.now().subtract(Duration(days: 2));
  DateTime toDate = DateTime.now();
  final ApiService api = ApiService();

  bool isLoading = false;

  List<Map<String, dynamic>> reportData = [];
  double totalNet = 0;
  double totalTax = 0;
  int totalTxn = 0;

  Future<void> loadGSTReport() async {
    setState(() => isLoading = true);

    try {
      final response = await api.fetchGSTReport(
        startDate: DateFormat('yyyy-MM-dd').format(fromDate),
        endDate: DateFormat('yyyy-MM-dd').format(toDate),
      );

      print("GST RESPONSE: $response");

      final List<Map<String, dynamic>> list =
          List<Map<String, dynamic>>.from(response);

      // ===============================
      // DYNAMIC TABLE COLUMNS
      // ===============================
      if (list.isNotEmpty) {
        tableColumns = list.first.keys.where((key) {
          return ![
            'id',
            'created_at',
            'updated_at',
          ].contains(key);
        }).toList();
      }

      double netTotal = 0;
      double taxTotal = 0;

      final parsedList = list.map((e) {
        final Map<String, dynamic> row = {};

        e.forEach((key, value) {
          // Convert everything safely
          final parsedValue = num.tryParse(value.toString());

          // Store original value
          row[key] = parsedValue ?? value.toString();

          // Calculate totals dynamically
          if (key == "net_amount" && parsedValue != null) {
            netTotal += parsedValue;
          }

          if (key == "total_tax" && parsedValue != null) {
            taxTotal += parsedValue;
          }
        });

        return row;
      }).toList();

      setState(() {
        reportData = parsedList;
        totalNet = netTotal;
        totalTax = taxTotal;
        totalTxn = parsedList.length;
      });
    } catch (e) {
      debugPrint("GST ERROR: $e");
    }

    setState(() => isLoading = false);
  }

  @override
  void initState() {
    super.initState();
    loadGSTReport();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1E3A8A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/dashboard');
          },
        ),
        title: const Text("GST Report",
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🔹 DATE FILTER
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: GestureDetector(
                onTap: _pickDateRange,
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.blue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "${DateFormat('dd-MM-yyyy').format(fromDate)}  →  ${DateFormat('dd-MM-yyyy').format(toDate)}",
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 🔹 KPI CARDS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _kpiCard(
                      "Net",
                      "₹${totalNet.toStringAsFixed(2)}",
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _kpiCard(
                      "Tax",
                      "₹${totalTax.toStringAsFixed(2)}",
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _kpiCard(
                      "Txn",
                      totalTxn.toString(),
                      Colors.green,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 🔹 LIST DATA
            isLoading
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  )
                : reportData.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text("No Data Found"),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: reportData.length,
                        itemBuilder: (context, index) {
                          final row = reportData[index];

                          return Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 6)
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 🔹 HEADER
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(row['date'],
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    Text("Bill #${row['bill_no']}",
                                        style: const TextStyle(
                                            color: Colors.grey)),
                                  ],
                                ),

                                const Divider(),

                                // 🔹 NET + TAX
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("Net: ₹${row['net_amount']}"),
                                    Text("Tax: ₹${row['total_tax']}",
                                        style:
                                            const TextStyle(color: Colors.red)),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                // 🔹 GST 5%
                                Column(
                                  children: row.keys
                                      .where(
                                          (key) => key.contains("sales_value"))
                                      .map((key) {
                                    final rate = key.split("_")[1];

                                    final sales = double.tryParse(
                                            row['gst_${rate}_sales_value']
                                                .toString()) ??
                                        0;

                                    final cgst = double.tryParse(
                                            row['gst_${rate}_cgst']
                                                .toString()) ??
                                        0;

                                    final sgst = double.tryParse(
                                            row['gst_${rate}_sgst']
                                                .toString()) ??
                                        0;

                                    if (sales == 0) return const SizedBox();

                                    return _gstSection(
                                      "GST $rate%",
                                      sales,
                                      cgst,
                                      sgst,
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _formatValue(dynamic value, String column) {
    if (value == null) return "";

    if (column == "date" || column == "bill_no") {
      return value.toString();
    }

    final number = num.tryParse(value.toString());

    if (number == null) return value.toString();

    return "₹${number.toStringAsFixed(2)}";
  }

  String _formatColumn(String column) {
    return column
        .replaceAll("_", " ")
        .replaceAll("gst", "GST ")
        .replaceAll("cgst", "CGST ")
        .replaceAll("sgst", "SGST ")
        .replaceAll("tax value", "Tax")
        .replaceAll("sales value", "Sales")
        .toUpperCase();
  }

  Widget _kpiCard(String title, String value, Color color,
      {bool isFull = false}) {
    return Container(
      width: isFull ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem(
      String text, IconData icon, Color color) {
    return PopupMenuItem(
        value: text.toLowerCase(),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 12),
            Text(text,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ));
  }
}
