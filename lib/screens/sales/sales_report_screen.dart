import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({super.key});

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  String selectedReport = "Day Report";
  String selectedFilter = "Monthly";

  late Future<List<OutletReport>> reportFuture;

  final List<String> reports = const [
    "Day Report",
    "Item Wise Report",
    "Hourly Sales",
    "Wastage Report",
    "Production Report",
    "Comparison Report",
  ];

  final List<String> filters = const [
    "Daily",
    "Monthly",
    "Yearly",
  ];

  @override
  void initState() {
    super.initState();
    reportFuture = fetchReport();
  }

  // ================= API CALL =================
  Future<List<OutletReport>> fetchReport() async {
    final filterParam = selectedFilter.toLowerCase();

    final url = Uri.parse(
      'http://192.168.29.160/api/daily-report?filter=$filterParam',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final List list = data['outlets'] ?? [];

      return list.map((e) => OutletReport.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load report');
    }
  }

  void reloadData() {
    setState(() {
      reportFuture = fetchReport();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sales Analytics"),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // ================= FILTER =================
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: filters.map((e) {
                return ChoiceChip(
                  label: Text(e),
                  selected: selectedFilter == e,
                  onSelected: (_) {
                    setState(() {
                      selectedFilter = e;
                    });
                    reloadData();
                  },
                );
              }).toList(),
            ),
          ),

          // ================= DROPDOWN =================
          Padding(
            padding: const EdgeInsets.all(10),
            child: DropdownButtonFormField<String>(
              initialValue:
                  reports.contains(selectedReport) ? selectedReport : null,
              decoration: const InputDecoration(
                labelText: "Select Report",
                border: OutlineInputBorder(),
              ),
              items: reports.map((e) {
                return DropdownMenuItem<String>(
                  value: e,
                  child: Text(e),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  selectedReport = value;
                });

                reloadData();
              },
            ),
          ),

          const SizedBox(height: 10),

          // ================= CONTENT =================
          Expanded(
            child: selectedReport == "Day Report"
                ? buildDayReport()
                : const Center(child: Text("Coming Soon")),
          ),
        ],
      ),
    );
  }

  // ================= REPORT UI =================
  Widget buildDayReport() {
    return FutureBuilder<List<OutletReport>>(
      future: reportFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Error loading data"),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: reloadData,
                  child: const Text("Retry"),
                ),
              ],
            ),
          );
        }

        final reports = snapshot.data ?? [];

        if (reports.isEmpty) {
          return const Center(child: Text("No data available"));
        }

        return ListView.builder(
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final r = reports[index];

            return Card(
              margin: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Bills: ${r.bills}"),
                        Text("Cash: ₹${r.cash}"),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("UPI: ₹${r.upi}"),
                        Text("Expense: ₹${r.expense}"),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Opening: ₹${r.openingBalance}"),
                        Text("Closing: ₹${r.closingBalance}"),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ================= MODEL =================
class OutletReport {
  final String name;
  final int bills;
  final double cash;
  final double upi;
  final double expense;
  final double openingBalance;
  final double closingBalance;

  OutletReport({
    required this.name,
    required this.bills,
    required this.cash,
    required this.upi,
    required this.expense,
    required this.openingBalance,
    required this.closingBalance,
  });

  factory OutletReport.fromJson(Map<String, dynamic> json) {
    return OutletReport(
      name: json['name'] ?? '',
      bills: json['bills'] ?? 0,
      cash: (json['cash'] ?? 0).toDouble(),
      upi: (json['upi'] ?? 0).toDouble(),
      expense: (json['expense'] ?? 0).toDouble(),
      openingBalance: (json['opening_balance'] ?? 0).toDouble(),
      closingBalance: (json['closing_balance'] ?? 0).toDouble(),
    );
  }
}
