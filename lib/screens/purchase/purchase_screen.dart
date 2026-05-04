import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/responsive_scaffold.dart';
import '../../services/api_service.dart';
import '../../screens/purchase/purchase_details_screen.dart';
import 'widgets/purchase_received_table.dart';
import 'widgets/raw_material_stock_table.dart';
import 'widgets/vendor_report_widget.dart';

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  final ScrollController _horizontalController = ScrollController();

  // ================= REPORT TYPES =================
  final List<String> reportTypes = [
    'Purchase Orders',
    'Purchase Received',
    'Raw Material Stock',
    'Vendor Report',
  ];

  String selectedReport = 'Purchase Orders';

  // ================= DATE FILTER =================
  String selectedFilter = "today";
  DateTime? fromDate;
  DateTime? toDate;

  final ApiService _apiService = ApiService();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ================= DATE FORMAT =================
  String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date); // API
  }

  String formatDisplayDate(DateTime date) {
    return DateFormat('MM/dd/yyyy').format(date); // UI
  }

  String _formatApiDate(String? date) {
    if (date == null || date.isEmpty) return '';

    try {
      final parsed = DateTime.parse(date);
      return DateFormat('dd-MM-yyyy').format(parsed);
    } catch (e) {
      return date;
    }
  }

  // ================= DATE LOGIC =================
  DateTime _startOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday % 7)); // Sunday start
  }

  DateTime _endOfWeek(DateTime date) {
    return _startOfWeek(date).add(const Duration(days: 6));
  }

  String getStartDate() {
    final now = DateTime.now();

    if (selectedFilter == "today") {
      return formatDate(now);
    }

    if (selectedFilter == "weekly") {
      return formatDate(_startOfWeek(now));
    }

    if (selectedFilter == "monthly") {
      return formatDate(DateTime(now.year, now.month, 1));
    }

    if (selectedFilter == "custom") {
      return fromDate != null ? formatDate(fromDate!) : formatDate(now);
    }

    return formatDate(now);
  }

  String getEndDate() {
    final now = DateTime.now();

    if (selectedFilter == "today") {
      return formatDate(now);
    }

    if (selectedFilter == "weekly") {
      return formatDate(_endOfWeek(now));
    }

    if (selectedFilter == "monthly") {
      return formatDate(now);
    }

    if (selectedFilter == "custom") {
      return toDate != null ? formatDate(toDate!) : formatDate(now);
    }

    return formatDate(now);
  }

  // ================= LOAD DATA =================
  void _loadData() {
    final start = getStartDate();
    final end = getEndDate();

    debugPrint("📅 START DATE: $start");
    debugPrint("📅 END DATE: $end");

    _future = _apiService.fetchPurchaseReport(
      type: selectedReport,
      startDate: start,
      endDate: end,
    );

    setState(() {});
  }

  // ================= DATE PICKER =================
  Future<void> _pickDateRange() async {
    DateTime tempFrom = fromDate ?? DateTime.now();
    DateTime tempTo = toDate ?? DateTime.now();
    String selectedQuick = "";

    final now = DateTime.now();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Widget quickChip(String label, VoidCallback onTap) {
              final isSelected = selectedQuick == label;

              return ChoiceChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (_) {
                  setModalState(() {
                    selectedQuick = label;
                  });
                  onTap();
                },
                selectedColor: Colors.blue,
                backgroundColor: Colors.grey.shade200,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                ),
              );
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      /// 🔹 TITLE
                      const Text(
                        "Select Date Range",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 12),

                      /// 🔹 QUICK FILTERS
                      Wrap(
                        spacing: 8,
                        children: [
                          quickChip("Today", () {
                            setModalState(() {
                              tempFrom = now;
                              tempTo = now;
                            });
                          }),
                          quickChip("Last 7 Days", () {
                            setModalState(() {
                              tempFrom = now.subtract(const Duration(days: 7));
                              tempTo = now;
                            });
                          }),
                          quickChip("Last 30 Days", () {
                            setModalState(() {
                              tempFrom = now.subtract(const Duration(days: 30));
                              tempTo = now;
                            });
                          }),
                        ],
                      ),

                      const SizedBox(height: 16),

                      /// 🔹 FROM DATE
                      ListTile(
                        title: const Text("From Date"),
                        subtitle: Text(formatDisplayDate(tempFrom)),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: tempFrom,
                            firstDate: DateTime(2023),
                            lastDate: now,
                          );
                          if (picked != null) {
                            setModalState(() => tempFrom = picked);
                          }
                        },
                      ),

                      /// 🔹 TO DATE
                      ListTile(
                        title: const Text("To Date"),
                        subtitle: Text(formatDisplayDate(tempTo)),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: tempTo,
                            firstDate: DateTime(2023),
                            lastDate: now,
                          );
                          if (picked != null) {
                            setModalState(() => tempTo = picked);
                          }
                        },
                      ),

                      const SizedBox(height: 20),

                      /// 🔹 ACTIONS
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Cancel"),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (tempFrom.isAfter(tempTo)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Invalid date range"),
                                    ),
                                  );
                                  return;
                                }

                                setState(() {
                                  fromDate = tempFrom;
                                  toDate = tempTo;
                                  selectedFilter = "custom";
                                });

                                Navigator.pop(context);
                                _loadData();
                              },
                              child: const Text("Apply"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: "Purchase Reports",
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  // ================= HEADER =================
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== ROW 1 =====
          Row(
            children: [
              const Icon(Icons.shopping_cart, color: Colors.blueGrey),
              const SizedBox(width: 10),
              const Text(
                "Select Report:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: selectedReport,
                items: reportTypes.map((e) {
                  return DropdownMenuItem(value: e, child: Text(e));
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    selectedReport = val!;
                  });
                  _loadData();
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ===== ROW 2 =====
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _chip("Today", "today"),
              _chip("Weekly", "weekly"),
              _chip("Monthly", "monthly"),
              _chip("Custom", "custom"),

              if (selectedFilter == "custom")
                ElevatedButton.icon(
                  onPressed: _pickDateRange,
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: const Text("Select Range"),
                ),

              _buildDateDisplay(), // ✅ SINGLE DISPLAY
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value) {
    final selected = selectedFilter == value;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) async {
        setState(() {
          selectedFilter = value;
        });

        if (value == "custom") {
          await _pickDateRange();
        } else {
          fromDate = null;
          toDate = null;
          _loadData();
        }
      },
    );
  }

  // ================= DATE DISPLAY =================
  Widget _buildDateDisplay() {
    String display = "";
    final now = DateTime.now();

    if (selectedFilter == "today") {
      display = formatDisplayDate(now);
    } else if (selectedFilter == "weekly") {
      final start = _startOfWeek(now);
      final end = _endOfWeek(now);
      display = "${formatDisplayDate(start)} - ${formatDisplayDate(end)}";
    } else if (selectedFilter == "monthly") {
      final start = DateTime(now.year, now.month, 1);
      display = "${formatDisplayDate(start)} - ${formatDisplayDate(now)}";
    } else if (selectedFilter == "custom" &&
        fromDate != null &&
        toDate != null) {
      display =
          "${formatDisplayDate(fromDate!)} - ${formatDisplayDate(toDate!)}";
    }

    if (display.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        display,
        style: TextStyle(
          color: Colors.blue.shade900,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ================= CONTENT =================
  Widget _buildContent() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        /// 🔄 Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        /// ❌ No Data
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No Data Found"));
        }

        final data = snapshot.data!;

        /// 🔀 SWITCH REPORT UI
        switch (selectedReport) {
          /// 🟢 PURCHASE RECEIVED
          case 'Purchase Received':
            return PurchaseReceivedTable(data: data);

          /// 🔵 PURCHASE ORDERS (table)
          case 'Purchase Orders':
            return _buildTable(data);

          /// 🟡 RAW MATERIAL STOCK (NEW UI)
          case 'Raw Material Stock':
            return RawMaterialStockTable(data: data);

          /// 🟣 VENDOR REPORT (keep table for now)
          case 'Vendor Report':
            return VendorReportWidget(data: data);

          /// 🔁 DEFAULT
          default:
            return _buildTable(data);
        }
      },
    );
  }

  Widget _buildTable(List<Map<String, dynamic>> data) {
    return Column(
      children: [
        /// 🔹 HORIZONTAL SCROLL WITH SCROLLBAR
        Expanded(
          child: Scrollbar(
            controller: _horizontalController,
            thumbVisibility: true,
            trackVisibility: true,
            child: SingleChildScrollView(
              controller: _horizontalController,
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 700),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    columnSpacing: 16,
                    headingRowHeight: 45,
                    dataRowMinHeight: 40,
                    columns: _columns(),
                    rows: data.map((e) => _row(e)).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<DataColumn> _columns() {
    return const [
      DataColumn(label: Text("Date")),
      DataColumn(label: Text("PO ID")),
      DataColumn(label: Text("Vendor")),
      DataColumn(label: Text("Items")),
      DataColumn(label: Text("Qty")),
      DataColumn(label: Text("Status")),
    ];
  }

  DataRow _row(Map row) {
    return DataRow(cells: [
      DataCell(Text(_formatApiDate(row['date']))), // ✅ FIX HERE

      DataCell(
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PurchaseDetailsScreen(data: row),
              ),
            );
          },
          child: Text(
            row['id'] ?? '',
            style: const TextStyle(
              color: Colors.blue,
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),

      DataCell(Text(row['vendor'] ?? '')),
      DataCell(Text("${row['item_count'] ?? 0}")),
      DataCell(Text("${row['total_qty'] ?? 0}")),
      DataCell(_status(row['status'] ?? '')),
    ]);
  }

  Widget _status(String status) {
    final color = status == "Completed" ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(status,
          style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    );
  }
}
