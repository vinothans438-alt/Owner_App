import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' as ex;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../services/api_service.dart';
import '../../widgets/responsive_scaffold.dart';

class TransferHistoryScreen extends StatefulWidget {
  const TransferHistoryScreen({super.key});

  @override
  State<TransferHistoryScreen> createState() => _TransferHistoryScreenState();
}

class _TransferHistoryScreenState extends State<TransferHistoryScreen> {
  final ApiService _apiService = ApiService();
  final ScrollController _hScroll = ScrollController();
  final ScrollController _vScroll = ScrollController();

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _displayData = [];
  List<String> _locationCols =[];
  List<Map<String, dynamic>> _outlets =[];

  String _searchQuery = "";
  String _selectedPeriod = "This Month";
  int? _selectedLocationId;

  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _setPeriodDates("This Month");
    _loadInitialData();
  }

  @override
  void dispose() {
    _hScroll.dispose();
    _vScroll.dispose();
    super.dispose();
  }

  void _setPeriodDates(String period) {
    DateTime now = DateTime.now();
    _selectedPeriod = period;
    setState(() {
      if (period == "Today") {
        _fromDate = now; _toDate = now;
      } else if (period == "Yesterday") {
        _fromDate = now.subtract(const Duration(days: 1));
        _toDate = now.subtract(const Duration(days: 1));
      } else if (period == "This Month") {
        _fromDate = DateTime(now.year, now.month, 1);
        _toDate = now;
      }
    });
  }

  Future<void> _selectManualDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate ? _fromDate : _toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) _fromDate = picked; else _toDate = picked;
        _selectedPeriod = "Custom Range";
      });
      _fetchReport();
    }
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      _outlets = await _apiService.fetchLocationList();
      await _fetchReport();
    } catch (e) {
      _errorMessage = "Could not load locations. Check server.";
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchReport() async {
    setState(() => _isLoading = true);
    List<Map<String, dynamic>> combinedData =[];

    try {
      if (_selectedLocationId == null) {
        for (var outlet in _outlets) {
          try {
            final data = await _apiService.fetchTransferHistoryReport(
              startDate: DateFormat('yyyy-MM-dd').format(_fromDate),
              endDate: DateFormat('yyyy-MM-dd').format(_toDate),
              locationId: outlet['id'],
            );
            combinedData.addAll(data);
          } catch (e) {
            debugPrint("Skipping outlet ${outlet['name']}");
          }
        }
      } else {
        combinedData = await _apiService.fetchTransferHistoryReport(
          startDate: DateFormat('yyyy-MM-dd').format(_fromDate),
          endDate: DateFormat('yyyy-MM-dd').format(_toDate),
          locationId: _selectedLocationId,
        );
      }

      if (combinedData.isEmpty) {
        _errorMessage = "No data found for the selected period.";
        _displayData =[];
      } else {
        _processPivotData(combinedData);
        _errorMessage = null;
      }
    } catch (e) {
      _errorMessage = "Critical Error: ${e.toString()}";
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _processPivotData(List<Map<String, dynamic>> raw) {
    Map<String, Map<String, dynamic>> pivot = {};
    Set<String> locations = {};

    for (var item in raw) {
      final productInfo = item['product'] ?? item['variant'] ?? {};
      String pName = productInfo['name'] ?? 'Unknown Product';
      String loc = item['location']?['name'] ?? 'Unknown Location';
      double qty = double.tryParse(item['quantity_dispatched'].toString()) ?? 0;
      double price = double.tryParse(productInfo['transfer_price']?.toString() ?? '0') ?? 0;
      String unit = item['unit_name'] ?? productInfo['unit']?['name'] ?? 'pcs';

      locations.add(loc);

      if (!pivot.containsKey(pName)) {
        pivot[pName] = {'name': pName, 'unit': unit, 'locs': <String, Map<String, double>>{}};
      }
      if (!pivot[pName]!['locs'].containsKey(loc)) {
        pivot[pName]!['locs'][loc] = {'qty': 0.0, 'amt': 0.0};
      }

      pivot[pName]!['locs'][loc]['qty'] += qty;
      pivot[pName]!['locs'][loc]['amt'] += (qty * price);
    }

    _locationCols = locations.toList()..sort();
    _displayData = pivot.values.toList();
  }

  // =========================================================
  // EXPORT FUNCTIONS (FIXED)
  // =========================================================

  Future<void> _exportToExcel() async {
    try {
      var excel = ex.Excel.createExcel();
      
      // ✅ FIX: Do NOT rename the sheet. Just grab the default one.
      // Renaming in older excel packages causes "Unmodifiable list" crash.
      String defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
      var sheet = excel[defaultSheet]; 

      final filtered = _displayData.where((e) => e['name'].toLowerCase().contains(_searchQuery)).toList();

      // Row 1: Headers
      List<dynamic> headers =[
        "PRODUCT NAME",
        "UNIT",
      ];
      for (var loc in _locationCols) {
        headers.add("$loc (QTY)");
        headers.add("$loc (AMT)");
      }
      headers.add("TOTAL (QTY)");
      headers.add("TOTAL (AMT)");
      sheet.appendRow(headers);

      // Data Rows
      for (var item in filtered) {
        List<dynamic> row =[
          item['name'],
          item['unit'],
        ];
        double rowQ = 0; double rowA = 0;
        for (var loc in _locationCols) {
          final data = item['locs'][loc] ?? {'qty': 0.0, 'amt': 0.0};
          rowQ += data['qty']; rowA += data['amt'];
          row.add(data['qty']);
          row.add(data['amt']);
        }
        row.add(rowQ);
        row.add(rowA);
        sheet.appendRow(row);
      }

      // Footer Row
      List<dynamic> footer = [
        "GRAND TOTAL",
        "",
      ];
      for (var loc in _locationCols) {
        double q = 0; double a = 0;
        for (var d in filtered) {
          q += d['locs'][loc]?['qty'] ?? 0;
          a += d['locs'][loc]?['amt'] ?? 0;
        }
        footer.add(q);
        footer.add(a);
      }
      footer.add(double.parse(_sumAll(filtered, 'qty')));
      footer.add(double.parse(_sumAll(filtered, 'amt')));
      sheet.appendRow(footer);

      // Save File
      final fileBytes = excel.encode()!;
      Directory? dir;
      if (Platform.isWindows) {
        dir = Directory(r'C:\Users\' + (Platform.environment['USERNAME'] ?? '') + r'\Downloads');
        if (!await dir.exists()) dir = await getApplicationDocumentsDirectory();
      } else if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
        if (!await dir.exists()) dir = await getExternalStorageDirectory();
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      if (dir != null) {
        if (!await dir.exists()) await dir.create(recursive: true);
        final file = File("${dir.path}/Transfer_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx");
        await file.writeAsBytes(fileBytes);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Excel saved to ${file.path}"), 
              action: SnackBarAction(label: "OPEN", onPressed: () => OpenFile.open(file.path))
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Excel Error: $e")));
    }
  }

  Future<pw.Document> _generatePdfDocument() async {
    final pdf = pw.Document();
    final filtered = _displayData.where((e) => e['name'].toLowerCase().contains(_searchQuery)).toList();

    List<String> headers = ["PRODUCT NAME", "UNIT"];
    for (var loc in _locationCols) {
      headers.add("$loc (QTY)");
      headers.add("$loc (AMT)");
    }
    headers.add("TOTAL (QTY)");
    headers.add("TOTAL (AMT)");

    List<List<String>> data =[];
    
    // Data Rows
    for (var item in filtered) {
      List<String> row = [item['name'].toString(), item['unit'].toString()];
      double rowQ = 0, rowA = 0;
      for (var loc in _locationCols) {
        final locData = item['locs'][loc] ?? {'qty': 0.0, 'amt': 0.0};
        rowQ += locData['qty']; rowA += locData['amt'];
        row.add(locData['qty'] > 0 ? locData['qty'].toStringAsFixed(1) : "-");
        row.add(locData['amt'] > 0 ? locData['amt'].toStringAsFixed(0) : "-");
      }
      row.add(rowQ.toStringAsFixed(1));
      row.add(rowA.toStringAsFixed(0));
      data.add(row);
    }

    // Footer Row
    List<String> footer = ["GRAND TOTAL", ""];
    for (var loc in _locationCols) {
      double q = 0, a = 0;
      for (var d in filtered) {
        q += d['locs'][loc]?['qty'] ?? 0;
        a += d['locs'][loc]?['amt'] ?? 0;
      }
      footer.add(q.toStringAsFixed(1));
      footer.add(a.toStringAsFixed(0));
    }
    footer.add(_sumAll(filtered, 'qty'));
    footer.add(_sumAll(filtered, 'amt'));
    data.add(footer);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape, // Adjust to A3 if lots of columns
        margin: const pw.EdgeInsets.all(20),
        build: (context) =>[
          pw.Text("Transfer Report", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Text("Period: ${DateFormat('dd-MM-yyyy').format(_fromDate)} to ${DateFormat('dd-MM-yyyy').format(_toDate)}"),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: data,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.center,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          ),
        ],
      ),
    );

    return pdf;
  }

  // ✅ FIX: Save PDF directly to Downloads folder to avoid Windows Share issues
  Future<void> _exportToPdf() async {
    try {
      final pdf = await _generatePdfDocument();
      final bytes = await pdf.save();

      Directory? dir;
      if (Platform.isWindows) {
        dir = Directory(r'C:\Users\' + (Platform.environment['USERNAME'] ?? '') + r'\Downloads');
        if (!await dir.exists()) dir = await getApplicationDocumentsDirectory();
      } else if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
        if (!await dir.exists()) dir = await getExternalStorageDirectory();
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      if (dir != null) {
        if (!await dir.exists()) await dir.create(recursive: true);
        final file = File("${dir.path}/Transfer_Report_${DateTime.now().millisecondsSinceEpoch}.pdf");
        await file.writeAsBytes(bytes);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("PDF saved to ${file.path}"), 
              action: SnackBarAction(label: "OPEN", onPressed: () => OpenFile.open(file.path))
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("PDF Error: $e")));
    }
  }

  Future<void> _printReport() async {
    try {
      final pdf = await _generatePdfDocument();
      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Print Error: $e")));
    }
  }

  // =========================================================
  // UI BUILDERS
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 650;

    return ResponsiveScaffold(
      title: "Transfer Report",
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          isMobile ? _buildMobileFilterBar() : _buildDesktopFilterBar(),
          if (_errorMessage != null && !_isLoading)
             Container(
               color: Colors.red.shade50,
               width: double.infinity,
               padding: const EdgeInsets.all(8),
               child: Text("⚠️ $_errorMessage", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
             ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : _buildStableGrid(isMobile), 
          ),
        ],
      ),
    );
  }

  Widget _buildMobileFilterBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Column(
        children: [
          Row(
            children:[
              Expanded(child: _mobileDropdown("Period", _selectedPeriod,["Today", "Yesterday", "This Month", "Custom Range"], (v) { _setPeriodDates(v!); _fetchReport(); })),
              const SizedBox(width: 10),
              Expanded(child: _mobileOutletDropdown()),
            ],
          ),
          const SizedBox(height: 10),
          _mobileInput("Product Search"),
          const SizedBox(height: 10),
          Row(
            children:[
              Expanded(child: _mobileDateButton("From", _fromDate, () => _selectManualDate(context, true))),
              const SizedBox(width: 10),
              Expanded(child: _mobileDateButton("To", _toDate, () => _selectManualDate(context, false))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children:[
              Expanded(child: _actionBtn("Excel", Colors.green, Icons.table_chart, _exportToExcel)),
              const SizedBox(width: 8),
              Expanded(child: _actionBtn("PDF", Colors.red, Icons.picture_as_pdf, _exportToPdf)),
              const SizedBox(width: 8),
              Expanded(child: _actionBtn("Print", Colors.cyan, Icons.print, _printReport)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopFilterBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Wrap(
        spacing: 15, runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _desktopDropdown("Period", _selectedPeriod,["Today", "Yesterday", "This Month", "Custom Range"], (v) { _setPeriodDates(v!); _fetchReport(); }),
          _desktopInput("Product"),
          _desktopOutletDropdown(),
          _desktopDateButton("From", _fromDate, () => _selectManualDate(context, true)),
          _desktopDateButton("To", _toDate, () => _selectManualDate(context, false)),
          _actionBtn("Excel", Colors.green, Icons.table_chart, _exportToExcel),
          _actionBtn("PDF", Colors.red, Icons.picture_as_pdf, _exportToPdf),
          _actionBtn("Print", Colors.cyan, Icons.print, _printReport),
        ],
      ),
    );
  }

  Widget _buildStableGrid(bool isMobile) {
    final filtered = _displayData.where((e) => e['name'].toLowerCase().contains(_searchQuery)).toList();
    if (filtered.isEmpty && !_isLoading) return const Center(child: Text("No items to display."));

    final double nameW = isMobile ? 120.0 : 240.0; 
    final double unitW = isMobile ? 40.0 : 70.0;
    final double qtyW  = isMobile ? 45.0 : 80.0;
    final double amtW  = isMobile ? 55.0 : 90.0;
    
    final double rowH  = isMobile ? 38.0 : 45.0;
    final double subH  = isMobile ? 26.0 : 30.0;
    final double fSize = isMobile ? 8.5 : 11.0;

    return Scrollbar(
      controller: _vScroll, thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _vScroll,
        scrollDirection: Axis.vertical,
        child: Scrollbar(
          controller: _hScroll, thumbVisibility: true,
          notificationPredicate: (n) => n.depth == 1,
          child: SingleChildScrollView(
            controller: _hScroll,
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:[
                _buildTableHeader(nameW, unitW, qtyW, amtW, rowH, subH, fSize),
                ...filtered.asMap().entries.map((entry) => _buildTableRow(entry.key, entry.value, nameW, unitW, qtyW, amtW, rowH, fSize)),
                _buildTableFooter(nameW, unitW, qtyW, amtW, rowH, fSize, filtered),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader(double nw, double uw, double qw, double aw, double h, double subH, double fSize) {
    return Container(
      decoration: BoxDecoration(color: Colors.grey.shade100, border: Border.all(color: Colors.grey.shade300)),
      child: Column(
        children: [
          Row(children:[
            _cell("PRODUCT NAME", nw, h: h, isHead: true, fSize: fSize),
            _cell("UNIT", uw, h: h, isHead: true, fSize: fSize),
            ..._locationCols.map((l) => _cell(l.toUpperCase(), qw + aw, h: h, isHead: true, fSize: fSize)),
            _cell("GRAND TOTAL", qw + aw, h: h, isHead: true, bgColor: Colors.blue.shade100, fSize: fSize),
          ]),
          Row(children:[
            _cell("", nw, h: subH, fSize: fSize), 
            _cell("", uw, h: subH, fSize: fSize),
            ..._locationCols.expand((l) =>[_cell("QTY", qw, h: subH, fSize: fSize), _cell("AMT", aw, h: subH, fSize: fSize)]),
            _cell("QTY", qw, h: subH, bgColor: Colors.blue.shade50, fSize: fSize), 
            _cell("AMT", aw, h: subH, bgColor: Colors.blue.shade50, fSize: fSize),
          ]),
        ],
      ),
    );
  }

  Widget _buildTableRow(int index, Map item, double nw, double uw, double qw, double aw, double h, double fSize) {
    double totalQ = 0; double totalA = 0;
    return Container(
      decoration: BoxDecoration(color: index.isOdd ? Colors.grey.shade50 : Colors.white, border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(children: [
        _cell(item['name'], nw, h: h, isBold: true, align: TextAlign.left, fSize: fSize),
        _cell(item['unit'], uw, h: h, fSize: fSize),
        ..._locationCols.map((loc) {
          final data = item['locs'][loc] ?? {'qty': 0.0, 'amt': 0.0};
          totalQ += data['qty']; totalA += data['amt'];
          return Row(children: [
            _cell(data['qty'] > 0 ? data['qty'].toStringAsFixed(1) : "-", qw, h: h, fSize: fSize),
            _cell(data['amt'] > 0 ? data['amt'].toStringAsFixed(0) : "-", aw, h: h, fSize: fSize),
          ]);
        }),
        _cell(totalQ.toStringAsFixed(1), qw, h: h, bgColor: Colors.blue.shade50, isBold: true, textColor: Colors.blue.shade900, fSize: fSize),
        _cell(totalA.toStringAsFixed(0), aw, h: h, bgColor: Colors.blue.shade50, isBold: true, textColor: Colors.blue.shade900, fSize: fSize),
      ]),
    );
  }

  Widget _buildTableFooter(double nw, double uw, double qw, double aw, double h, double fSize, List data) {
    return Container(
      color: const Color(0xFF1E293B),
      child: Row(children:[
        _cell("GRAND TOTAL", nw + uw, h: h, isBold: true, textColor: Colors.white, fSize: fSize),
        ..._locationCols.map((loc) {
          double q = 0; double a = 0;
          for (var d in data) { q += d['locs'][loc]?['qty'] ?? 0; a += d['locs'][loc]?['amt'] ?? 0; }
          return Row(children:[
            _cell(q.toStringAsFixed(1), qw, h: h, isBold: true, textColor: Colors.white, fSize: fSize),
            _cell(a.toStringAsFixed(0), aw, h: h, isBold: true, textColor: Colors.white, fSize: fSize),
          ]);
        }),
        _cell(_sumAll(data, 'qty'), qw, h: h, bgColor: Colors.blue.shade700, isBold: true, textColor: Colors.white, fSize: fSize),
        _cell(_sumAll(data, 'amt'), aw, h: h, bgColor: Colors.blue.shade700, isBold: true, textColor: Colors.white, fSize: fSize),
      ]),
    );
  }

  String _sumAll(List data, String key) {
    double total = 0;
    for (var d in data) { d['locs'].forEach((k, v) => total += v[key]); }
    return key == 'qty' ? total.toStringAsFixed(1) : total.toStringAsFixed(0);
  }

  // --- UI ATOM HELPERS ---

  Widget _cell(String t, double w, {double h = 45, bool isBold = false, bool isHead = false, Color? bgColor, Color textColor = Colors.black87, TextAlign align = TextAlign.center, double fSize = 10}) {
    return Container(
      width: w, height: h, alignment: align == TextAlign.left ? Alignment.centerLeft : Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(color: bgColor, border: Border.all(color: Colors.grey.shade300, width: 0.5)),
      child: Text(t, style: TextStyle(fontSize: isHead ? fSize + 1 : fSize, fontWeight: (isBold || isHead) ? FontWeight.bold : FontWeight.normal, color: textColor), overflow: TextOverflow.ellipsis),
    );
  }

  Widget _mobileDropdown(String label, String value, List<String> opts, Function(String?) onChg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 2),
        Container(
          height: 36, padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(6)),
          child: DropdownButton<String>(
            isExpanded: true, value: value, underline: const SizedBox(), style: const TextStyle(fontSize: 12, color: Colors.black87),
            items: opts.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: onChg,
          ),
        ),
      ],
    );
  }

  Widget _mobileOutletDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
        const Text("Location", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 2),
        Container(
          height: 36, padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(6)),
          child: DropdownButton<int?>(
            isExpanded: true, value: _selectedLocationId, underline: const SizedBox(), style: const TextStyle(fontSize: 12, color: Colors.black87),
            items:[
              const DropdownMenuItem(value: null, child: Text("All Locations")),
              ..._outlets.map((o) => DropdownMenuItem(value: o['id'], child: Text(o['name'])))
            ],
            onChanged: (v) { setState(() => _selectedLocationId = v); _fetchReport(); },
          ),
        ),
      ],
    );
  }

  Widget _mobileInput(String label) {
    return SizedBox(
      height: 36,
      child: TextField(
        decoration: InputDecoration(hintText: label, hintStyle: const TextStyle(fontSize: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)), contentPadding: const EdgeInsets.symmetric(horizontal: 10)),
        onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
      ),
    );
  }

  Widget _mobileDateButton(String label, DateTime date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 36, padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(border: Border.all(color: Colors.blue.shade200), borderRadius: BorderRadius.circular(6), color: Colors.blue.shade50.withOpacity(0.3)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children:[
            Text("$label: ${DateFormat('dd-MM-yy').format(date)}", style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold)),
            const Icon(Icons.calendar_month, size: 14, color: Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _desktopDropdown(String label, String value, List<String> opts, Function(String?) onChg) {
    return Row(mainAxisSize: MainAxisSize.min, children:[
      Text("$label: ", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      Container(
        height: 32, padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
        child: DropdownButton<String>(value: value, underline: const SizedBox(), isDense: true, items: opts.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12)))).toList(), onChanged: onChg),
      )
    ]);
  }

  Widget _desktopOutletDropdown() {
    return Row(mainAxisSize: MainAxisSize.min, children:[
      const Text("Location: ", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      Container(
        height: 32, padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
        child: DropdownButton<int?>(
          value: _selectedLocationId, underline: const SizedBox(), isDense: true,
          items:[
            const DropdownMenuItem(value: null, child: Text("All Locations", style: TextStyle(fontSize: 12))),
            ..._outlets.map((o) => DropdownMenuItem(value: o['id'], child: Text(o['name'], style: const TextStyle(fontSize: 12))))
          ],
          onChanged: (v) { setState(() => _selectedLocationId = v); _fetchReport(); },
        ),
      )
    ]);
  }

  Widget _desktopInput(String label) {
    return Row(mainAxisSize: MainAxisSize.min, children:[
      Text("$label: ", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      SizedBox(width: 140, height: 32, child: TextField(
        decoration: const InputDecoration(hintText: "Search...", border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8)),
        onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
      ))
    ]);
  }

  Widget _desktopDateButton(String label, DateTime date, VoidCallback onTap) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children:[
        Text("$label: ", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(border: Border.all(color: Colors.blue.shade300), borderRadius: BorderRadius.circular(6), color: Colors.blue.shade50.withOpacity(0.3)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children:[
                Text(DateFormat('dd-MM-yyyy').format(date), style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold)),
                const SizedBox(width: 5),
                const Icon(Icons.calendar_month, size: 14, color: Colors.blue),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionBtn(String lbl, Color col, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed, 
      icon: Icon(icon, size: 13, color: Colors.white), 
      label: Text(lbl, style: const TextStyle(color: Colors.white, fontSize: 10)),
      style: ElevatedButton.styleFrom(
        backgroundColor: col, 
        padding: const EdgeInsets.symmetric(horizontal: 4),
        minimumSize: const Size(0, 36)
      ),
    );
  }
}