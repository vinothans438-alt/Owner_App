import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/responsive_scaffold.dart';
import '../../services/api_service.dart';
import 'reports/item_wise_report.dart';
import 'reports/hourly_sales_report.dart';

import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:excel/excel.dart' as ex;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'bill_details_screen.dart';
import 'package:open_file/open_file.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  // ================= LOGIC =================
  String getReportTitle() {
    final now = DateTime.now();
    if (selectedFilter == "today") {
      return "Day Report of ${formatDisplayDate(now)}";
    }
    if (selectedFilter == "weekly") {
      final start = _startOfWeek(now);
      final end = _endOfWeek(now);
      return "Weekly Report from ${formatDisplayDate(start)} to ${formatDisplayDate(end)}";
    }
    if (selectedFilter == "monthly") {
      final start = DateTime(now.year, now.month, 1);
      return "Monthly Report from ${formatDisplayDate(start)} to ${formatDisplayDate(now)}";
    }
    if (selectedFilter == "custom" && fromDate != null && toDate != null) {
      return "Custom Report from ${formatDisplayDate(fromDate!)} to ${formatDisplayDate(toDate!)}";
    }
    return "Day Report";
  }

  String formatDisplayDate(DateTime date) =>
      DateFormat('MM/dd/yyyy').format(date);
  String toBackendDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  // New logic for formatting the explicit explicit Display String on UI
  String getDisplayDateRange() {
    final DateFormat formatter = DateFormat('MM/dd/yyyy');
    final now = DateTime.now();

    if (selectedFilter == "today") {
      return formatter.format(now);
    } else if (selectedFilter == "weekly") {
      return "${formatter.format(_startOfWeek(now))} - ${formatter.format(_endOfWeek(now))}";
    } else if (selectedFilter == "monthly") {
      final start = DateTime(now.year, now.month, 1);
      return "${formatter.format(start)} - ${formatter.format(now)}";
    } else if (selectedFilter == "custom" &&
        fromDate != null &&
        toDate != null) {
      return "${formatter.format(fromDate!)} - ${formatter.format(toDate!)}";
    }
    return "Select Custom Date";
  }

  String getStartDate() {
    final now = DateTime.now();
    if (selectedFilter == "today") return toBackendDate(now);
    if (selectedFilter == "weekly") return toBackendDate(_startOfWeek(now));
    if (selectedFilter == "monthly") {
      return toBackendDate(DateTime(now.year, now.month, 1));
    }
    if (selectedFilter == "custom" && fromDate != null) {
      return toBackendDate(fromDate!);
    }
    return toBackendDate(now);
  }

  String getEndDate() {
    final now = DateTime.now();
    if (selectedFilter == "today") return toBackendDate(now);
    if (selectedFilter == "weekly") return toBackendDate(_endOfWeek(now));
    if (selectedFilter == "monthly") return toBackendDate(now);
    if (selectedFilter == "custom" && toDate != null) {
      return toBackendDate(toDate!);
    }
    return toBackendDate(now);
  }

  DateTime _startOfWeek(DateTime date) =>
      date.subtract(Duration(days: date.weekday % 7));
  DateTime _endOfWeek(DateTime date) =>
      _startOfWeek(date).add(const Duration(days: 6));

  final List<String> reportTypes = [
    'Day Report',
    'Item Wise Report',
    'Hourly Sales',
    'Wastage Report',
    'Production Report',
    'Comparison Reports',
  ];
  String selectedReport = 'Day Report';
  String selectedFilter = "today";
  DateTime? fromDate;
  DateTime? toDate;

  final ApiService _apiService = ApiService();
  late Future<List<Map<String, dynamic>>> _future;

  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  final List<Map<String, dynamic>> metrics = [
    {'label': 'Bills', 'key': 'bills', 'icon': Icons.receipt_long},
    {'label': 'Cash', 'key': 'cash', 'icon': Icons.payments},
    {'label': 'UPI', 'key': 'upi', 'icon': Icons.qr_code_2},
    {'label': 'Expense', 'key': 'expense', 'icon': Icons.trending_down},
    {
      'label': 'Opening Balance',
      'key': 'opening_balance',
      'icon': Icons.lock_open
    },
    {'label': 'Closing Balance', 'key': 'closing_balance', 'icon': Icons.lock},
    {'label': 'Edit Bill', 'key': 'edit_bill', 'icon': Icons.edit_note},
    {'label': 'Cancel', 'key': 'cancel', 'icon': Icons.cancel_presentation},
    {'label': 'Return', 'key': 'return', 'icon': Icons.assignment_return},
    {'label': 'Guest Bill', 'key': 'guest', 'icon': Icons.person_pin},
    {'label': 'B2B Bill', 'key': 'b2b', 'icon': Icons.business},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  void _loadData() {
    if (selectedReport != 'Day Report') return;
    _future = _apiService.fetchDayReport(
        startDate: getStartDate(), endDate: getEndDate());
    setState(() {});
  }

  Future<void> _pickDateRange() async {
    DateTime tempFrom = fromDate ?? DateTime.now();
    DateTime tempTo = toDate ?? DateTime.now();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.72,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Select Date Range",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),

                  const SizedBox(height: 20),

                  // FROM DATE
                  const Text(
                    "From Date",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 8),

                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: tempFrom,
                        firstDate: DateTime(2023),
                        lastDate: DateTime.now(),
                      );

                      if (picked != null) {
                        setModalState(() {
                          tempFrom = picked;
                        });
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        DateFormat('dd MMM yyyy').format(tempFrom),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // TO DATE
                  const Text(
                    "To Date",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 8),

                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: tempTo,
                        firstDate: DateTime(2023),
                        lastDate: DateTime.now(),
                      );

                      if (picked != null) {
                        setModalState(() {
                          tempTo = picked;
                        });
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        DateFormat('dd MMM yyyy').format(tempTo),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // APPLY BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E88E5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          fromDate = tempFrom;
                          toDate = tempTo;
                          selectedFilter = "custom";
                        });

                        Navigator.pop(context);

                        _loadData();
                      },
                      child: const Text(
                        "Apply Filter",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ================= NEW UI BUILD =================

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: "Sales Analytics",
      body: Container(
        color: const Color(0xFFF8FAFC),
        child: Column(
          children: [
            _buildModernHeader(),
            Expanded(child: _buildReportContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildReportTypeDropdown()),
              const SizedBox(width: 12),
              _buildCloudDownloadButton(),
            ],
          ),
          const SizedBox(height: 16),
          // Clean row containing 4 segment triggers
          _buildSegmentedFilter(),
          const SizedBox(height: 12),
          // Clear text displaying exactly what dates are loaded
          _buildDateDisplayRow(),
        ],
      ),
    );
  }

  Widget _buildDateDisplayRow() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_month_outlined,
              size: 20, color: Color(0xFF1E88E5)),
          const SizedBox(width: 8),
          Text(
            getDisplayDateRange(),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E88E5),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedFilter() {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          _buildPill("Today", "today"),
          _buildPill("Weekly", "weekly"),
          _buildPill("Monthly", "monthly"),
          _buildPill("Custom", "custom", isCustomTrigger: true),
        ],
      ),
    );
  }

  Widget _buildPill(String label, String value,
      {bool isCustomTrigger = false}) {
    bool isSelected = selectedFilter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (isCustomTrigger) {
            // Let custom date handler do its job
            _pickDateRange();
          } else {
            // Preset dates
            setState(() {
              selectedFilter = value;
              fromDate = null;
              toDate = null;
            });
            _loadData();
          }
        },
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05), blurRadius: 4)
                  ]
                : [],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(label,
                  style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF1E88E5)
                          : Colors.blueGrey,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCloudDownloadButton() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.cloud_download_outlined,
          color: Color(0xFF1E88E5), size: 30),
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) async {
        final data = await _future;
        if (value == 'pdf') {
          _downloadDayReportPDF(data);
        } else if (value == 'excel') {
          _downloadDayReportExcel(data);
        } else if (value == 'whatsapp') {
          _sendDayReportWhatsApp(data);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
            value: 'pdf',
            child: Row(children: [
              Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
              SizedBox(width: 10),
              Text("Download PDF")
            ])),
        const PopupMenuItem(
            value: 'excel',
            child: Row(children: [
              Icon(Icons.table_chart, color: Colors.green, size: 20),
              SizedBox(width: 10),
              Text("Download Excel")
            ])),
        const PopupMenuItem(
            value: 'whatsapp',
            child: Row(children: [
              Icon(Icons.share, color: Colors.blue, size: 20),
              SizedBox(width: 10),
              Text("Send WhatsApp")
            ])),
      ],
    );
  }

  Widget _buildReportTypeDropdown() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedReport,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.blueGrey),
          style: const TextStyle(
              color: Color(0xFF334155),
              fontWeight: FontWeight.bold,
              fontSize: 14),
          items: reportTypes
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
          onChanged: (val) {
            if (val != null) setState(() => selectedReport = val);
            _loadData();
          },
        ),
      ),
    );
  }

  Widget _buildReportContent() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error loading data: ${snapshot.error}"));
        }

        switch (selectedReport) {
          case 'Day Report':
            return (snapshot.data == null || snapshot.data!.isEmpty)
                ? const Center(child: Text("No data found"))
                : _buildDayReportView(snapshot.data!);
          case 'Item Wise Report':
            return ItemWiseReport(
                startDate: getStartDate(), endDate: getEndDate());
          case 'Hourly Sales':
            return HourlySalesReport(
                startDate: getStartDate(), endDate: getEndDate());
          default:
            return _buildPlaceholderView(
                Icons.analytics_outlined, "$selectedReport coming soon...");
        }
      },
    );
  }

  // ================= BIDIRECTIONAL MOVABLE TABLE =================

  Widget _buildDayReportView(List<Map<String, dynamic>> outlets) {
    // The wrapper `Scrollbar` is placed OUTSIDE the padding, forcing it to
    // render at the absolute far-right edge of the screen, away from the container.
    return Scrollbar(
      controller: _verticalScrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _verticalScrollController,
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: const EdgeInsets.all(
              16.0), // Padding ensures white card stays spaced
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Scrollbar(
              controller: _horizontalScrollController,
              thumbVisibility: true,
              notificationPredicate: (notif) => notif.depth == 0,
              child: SingleChildScrollView(
                controller: _horizontalScrollController,
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width - 32,
                  ),
                  child: DataTable(
                    headingRowColor:
                        MaterialStateProperty.all(const Color(0xFFF8FAFC)),
                    dataRowMinHeight: 52,
                    dataRowMaxHeight: 52,
                    horizontalMargin: 20,
                    columnSpacing: 35,
                    border: TableBorder(
                      horizontalInside:
                          BorderSide(color: Colors.grey.shade100, width: 1),
                      verticalInside:
                          BorderSide(color: Colors.grey.shade100, width: 1),
                    ),
                    columns: _buildColumns(outlets),
                    rows: _buildRows(outlets),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<DataColumn> _buildColumns(List<Map<String, dynamic>> outlets) {
    List<DataColumn> cols = [
      const DataColumn(
          label: Text("METRICS",
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
    ];
    for (var outlet in outlets) {
      cols.add(DataColumn(
          label: Text(outlet['name'].toString().toUpperCase(),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Color(0xFF64748B)))));
    }
    cols.add(const DataColumn(
        label: Text("TOTAL",
            style: TextStyle(
                fontWeight: FontWeight.w900, color: Color(0xFF1E88E5)))));
    return cols;
  }

  List<DataRow> _buildRows(List<Map<String, dynamic>> outlets) {
    return metrics.map((m) {
      final isExpense = m['key'] == 'expense';
      final isClickable = ['bills', 'guest', 'b2b'].contains(m['key']);
      double rowTotal = 0;
      List<DataCell> cells = [
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(m['icon'],
                size: 16, color: isExpense ? Colors.red : Colors.blueGrey),
            const SizedBox(width: 8),
            Text(m['label'],
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isExpense
                        ? Colors.red.shade700
                        : const Color(0xFF1E293B))),
          ],
        )),
      ];

      for (var outlet in outlets) {
        double val = double.tryParse((outlet[m['key']] ?? 0).toString()) ?? 0;
        rowTotal += val;
        cells.add(DataCell(
          isClickable && val > 0
              ? InkWell(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => BillDetailsScreen(
                                outletName: outlet['name'],
                                locationId: int.parse(outlet['id'].toString()),
                                startDate: getStartDate(),
                                endDate: getEndDate(),
                                billType: m['key'],
                              ))),
                  child: Text(val.toInt().toString(),
                      style: const TextStyle(
                          color: Color(0xFF1E88E5),
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline)),
                )
              : Text(_format(m['key'], val),
                  style: TextStyle(
                      color: isExpense
                          ? Colors.red.shade600
                          : const Color(0xFF334155))),
        ));
      }
      cells.add(DataCell(Text(_format(m['key'], rowTotal),
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color:
                  isExpense ? Colors.red.shade900 : const Color(0xFF0F172A)))));
      return DataRow(cells: cells);
    }).toList();
  }

  String _format(String key, double value) {
    if (key == 'bills') return value.toStringAsFixed(0);
    if (['cash', 'upi', 'expense', 'opening_balance', 'closing_balance']
        .contains(key)) {
      return NumberFormat.currency(
              locale: 'en_IN', symbol: '₹', decimalDigits: 2)
          .format(value);
    }
    return value.toStringAsFixed(0);
  }

  Widget _buildPlaceholderView(IconData icon, String msg) {
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 80, color: Colors.grey.shade300),
      const SizedBox(height: 16),
      Text(msg, style: const TextStyle(fontSize: 16, color: Colors.grey))
    ]));
  }

  // ================= EXPORTS =================

  Future<void> _downloadDayReportPDF(List<Map<String, dynamic>> outlets) async {
    final pdf = pw.Document();
    final fontData = await rootBundle.load("assets/fonts/NotoSans-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);
    pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (_) => pw.Column(children: [
              pw.Text(getReportTitle(),
                  style: pw.TextStyle(
                      font: ttf, fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headers: ["Metrics", ...outlets.map((e) => e['name']), "Total"],
                data: metrics.map((m) {
                  double total = 0;
                  List row = [m['label']];
                  for (var o in outlets) {
                    double val =
                        double.tryParse((o[m['key']] ?? 0).toString()) ?? 0;
                    total += val;
                    row.add(_format(m['key'], val));
                  }
                  row.add(_format(m['key'], total));
                  return row;
                }).toList(),
                headerStyle: pw.TextStyle(
                    font: ttf,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.blue800),
                cellStyle: pw.TextStyle(font: ttf, fontSize: 9),
              ),
            ])));
    await Printing.sharePdf(
        bytes: await pdf.save(), filename: "Day_Report.pdf");
  }

  Future<void> _downloadDayReportExcel(
      List<Map<String, dynamic>> outlets) async {
    final excel = ex.Excel.createExcel();
    final sheet = excel['Report'];
    sheet.appendRow(["Metrics", ...outlets.map((e) => e['name']), "Total"]);
    for (var m in metrics) {
      double total = 0;
      List row = [m['label']];
      for (var o in outlets) {
        double val = double.tryParse((o[m['key']] ?? 0).toString()) ?? 0;
        total += val;
        row.add(val);
      }
      row.add(total);
      sheet.appendRow(row);
    }
    Directory dir = Platform.isAndroid
        ? Directory('/storage/emulated/0/Download')
        : await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/Day_Report.xlsx");
    await file.writeAsBytes(excel.encode()!);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text("Excel saved to Downloads"),
        action: SnackBarAction(
            label: "OPEN", onPressed: () => OpenFile.open(file.path))));
  }

  Future<void> _sendDayReportWhatsApp(
      List<Map<String, dynamic>> outlets) async {
    final formatter =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    String msg = "📊 *Day Report*\n\n";
    for (var m in metrics) {
      msg += "*${m['label']}*\n";
      double total = 0;
      for (var o in outlets) {
        double val = double.tryParse((o[m['key']] ?? 0).toString()) ?? 0;
        total += val;
        msg += "• ${o['name']} : ${formatter.format(val)}\n";
      }
      msg += "➡ Total : ${formatter.format(total)}\n\n";
    }
    await Share.share(msg);
  }
}
