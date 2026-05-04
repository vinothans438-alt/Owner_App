import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:excel/excel.dart' as ex;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../services/api_service.dart';

class ItemWiseReport extends StatefulWidget {
  final String startDate;
  final String endDate;

  const ItemWiseReport({
    super.key,
    required this.startDate,
    required this.endDate,
  });

  @override
  State<ItemWiseReport> createState() => _ItemWiseReportState();
}

class _ItemWiseReportState extends State<ItemWiseReport> {
  // ================= PDF CELL (FIXED) =================
  pw.Widget _pdfCell(
    String text,
    pw.Font font, {
    bool bold = false,
    bool isNumeric = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 3),
      alignment: isNumeric ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
      child: pw.Text(
        text,
        maxLines: 2,
        overflow: pw.TextOverflow.clip,
        style: pw.TextStyle(
          font: font,
          fontSize: 7.5,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  final ScrollController _horizontal = ScrollController();
  final ScrollController _vertical = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  final double rowHeight = 45;
  final double headerHeight = 70;
  final double productColWidth = 160;
  final double outletColWidth = 140;
  final double totalColWidth = 150;

  bool isLoading = true;

  List<String> outlets = [];
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> filtered = [];

  @override
  void initState() {
    super.initState();
    _fetch();
    _searchController.addListener(_filter);
  }

  @override
  void dispose() {
    _horizontal.dispose();
    _vertical.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            _searchBar(),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _table(),
            ),
          ],
        ),
        Positioned(top: 10, right: 10, child: _downloadMenu()),
      ],
    );
  }

  // ================= MENU =================
  Widget _downloadMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.download),
      onSelected: (v) {
        if (v == "pdf") _downloadPDF();
        if (v == "excel") _downloadExcel();
        if (v == "whatsapp") _sendWhatsApp();
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: "pdf", child: Text("Download PDF")),
        PopupMenuItem(value: "excel", child: Text("Download Excel")),
        PopupMenuItem(value: "whatsapp", child: Text("Send WhatsApp")),
      ],
    );
  }

  // ================= API =================
  Future<void> _fetch() async {
    try {
      if (!mounted) return;

      setState(() => isLoading = true);

      final data = await ApiService().fetchItemReport(
        startDate: widget.startDate,
        endDate: widget.endDate,
      );

      if (!mounted) return;

      outlets = List<String>.from(data['outlets'] ?? []);
      products = List<Map<String, dynamic>>.from(data['products'] ?? []);
      filtered = List.from(products);

      setState(() => isLoading = false);
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  // ================= SEARCH =================
  void _filter() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      filtered = products
          .where((p) => (p['name'] ?? '').toLowerCase().contains(q))
          .toList();
    });
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: "Search product...",
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  // ================= TABLE =================
  Widget _table() {
    return Scrollbar(
      controller: _vertical,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _vertical,
        child: Scrollbar(
          controller: _horizontal,
          thumbVisibility: true,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: _horizontal,
            child: Column(
              children: [
                _headerRow(),
                ...filtered.map(_dataRow),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerRow() {
    return Row(
      children: [
        _cell("PRODUCT",
            width: productColWidth, height: headerHeight, bold: true),
        ...outlets.map(_header),
        _cell("TOTAL", width: totalColWidth, height: headerHeight, bold: true),
      ],
    );
  }

  Widget _dataRow(Map<String, dynamic> p) {
    final map = (p['outlets'] as Map?) ?? {};

    double totalQty = 0;
    double totalAmt = 0;

    return Row(
      children: [
        _cell(p['name'] ?? '', width: productColWidth, bold: true),
        ...outlets.map((o) {
          final d = map[o] ?? {};
          final q = (d['qty'] ?? 0);
          final a = (d['amt'] ?? 0).toDouble();

          totalQty += q;
          totalAmt += a;

          return _split(q.toString(), _format(a));
        }),
        _split(
          totalQty.toStringAsFixed(0),
          _format(totalAmt),
          width: totalColWidth,
          isBold: true,
        ),
      ],
    );
  }

  // ================= PDF =================
  Future<void> _downloadPDF() async {
    try {
      final pdf = pw.Document();

      final fontData =
          await rootBundle.load("assets/fonts/NotoSans-Regular.ttf");
      final font = pw.Font.ttf(fontData);

      const int rowsPerPage = 18;

      if (filtered.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No data available to export")),
        );
        return;
      }

      for (int i = 0; i < filtered.length; i += rowsPerPage) {
        final chunk = filtered.skip(i).take(rowsPerPage).toList();

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4.landscape,
            margin: const pw.EdgeInsets.all(10),
            build: (_) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    "Item Wise Report",
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Table(
                    border: pw.TableBorder.all(width: 0.5),
                    defaultVerticalAlignment:
                        pw.TableCellVerticalAlignment.middle,
                    columnWidths: {
                      0: const pw.FlexColumnWidth(2.5),
                      for (int i = 0; i < outlets.length; i++)
                        i + 1: const pw.FlexColumnWidth(1),
                      outlets.length + 1: const pw.FlexColumnWidth(1.3),
                    },
                    children: [
                      // HEADER
                      pw.TableRow(
                        decoration:
                            const pw.BoxDecoration(color: PdfColors.grey300),
                        children: [
                          _pdfCell("PRODUCT", font, bold: true),
                          ...outlets.map(
                            (o) => _pdfCell(o, font, bold: true),
                          ),
                          _pdfCell("TOTAL", font, bold: true),
                        ],
                      ),

                      // DATA
                      ...chunk.map((p) {
                        final map = (p['outlets'] as Map?) ?? {};

                        double totalQty = 0;
                        double totalAmt = 0;

                        List<pw.Widget> row = [];

                        row.add(_pdfCell(p['name'] ?? '-', font));

                        for (var o in outlets) {
                          final d = map[o] ?? {};
                          final q = (d['qty'] ?? 0).toDouble();
                          final a = (d['amt'] ?? 0).toDouble();

                          totalQty += q;
                          totalAmt += a;

                          row.add(
                            _pdfCell(
                              "${q.toInt()} / ₹${a.toStringAsFixed(0)}",
                              font,
                              isNumeric: true,
                            ),
                          );
                        }

                        row.add(
                          _pdfCell(
                            "${totalQty.toInt()} / ₹${totalAmt.toStringAsFixed(0)}",
                            font,
                            bold: true,
                            isNumeric: true,
                          ),
                        );

                        return pw.TableRow(children: row);
                      }),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      }

      final bytes = await pdf.save();

      // ================= SAVE FILE =================
      String filePath = "";

      if (kIsWeb) {
        await Printing.sharePdf(bytes: bytes, filename: "Item_Report.pdf");
        return;
      }

      if (Platform.isWindows) {
        final dir = await getDownloadsDirectory();
        if (dir == null) {
          throw Exception("Downloads folder not found");
        }

        filePath =
            "${dir.path}\\Item_Report_${DateTime.now().millisecondsSinceEpoch}.pdf";
      } else if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          throw Exception("Storage permission denied");
        }

        final dir = Directory("/storage/emulated/0/Download");

        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }

        filePath =
            "${dir.path}/Item_Report_${DateTime.now().millisecondsSinceEpoch}.pdf";
      } else {
        final dir = await getApplicationDocumentsDirectory();
        filePath =
            "${dir.path}/Item_Report_${DateTime.now().millisecondsSinceEpoch}.pdf";
      }

      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("PDF saved at:\n$filePath")),
      );

      // optional: open file (Windows/mobile)
      await Printing.sharePdf(bytes: bytes, filename: "Item_Report.pdf");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("PDF Error: $e")),
      );
    }
  }

  // ================= EXCEL =================
  Future<void> _downloadExcel() async {
    final excel = ex.Excel.createExcel();
    final sheet = excel['Report'];

    sheet.appendRow(["Product", ...outlets, "Total"]);

    for (var p in filtered) {
      final map = (p['outlets'] as Map?) ?? {};
      List row = [p['name']];
      double total = 0;

      for (var o in outlets) {
        final val = map[o]?['amt'] ?? 0;
        row.add(val);
        total += val;
      }

      row.add(total);
      sheet.appendRow(row);
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/report.xlsx");
    await file.writeAsBytes(excel.encode()!);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Saved: ${file.path}")),
    );
  }

  // ================= SHARE =================
  Future<void> _sendWhatsApp() async {
    String msg = "Item Report\n\n";
    for (var p in filtered) {
      msg += "${p['name']}\n";
    }
    await Share.share(msg);
  }

  // ================= UI HELPERS =================
  Widget _cell(String t,
      {required double width, double? height, bool bold = false}) {
    return Container(
      width: width,
      height: height ?? rowHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.grey.shade100,
      ),
      child: Text(t,
          style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
    );
  }

  Widget _split(String q, String a, {double? width, bool isBold = false}) {
    return Container(
      width: width ?? outletColWidth,
      height: rowHeight,
      decoration:
          BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
      child: Row(
        children: [
          Expanded(child: Center(child: Text(q))),
          Container(width: 1, color: Colors.grey.shade300),
          Expanded(
            child: Center(
              child: Text(a,
                  style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight:
                          isBold ? FontWeight.bold : FontWeight.normal)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(String o) {
    return Container(
      width: outletColWidth,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.grey.shade200,
      ),
      child: Column(
        children: [
          SizedBox(
              height: 35,
              child: Center(
                  child: Text(o,
                      style: const TextStyle(fontWeight: FontWeight.bold)))),
          const Row(
            children: [
              Expanded(child: Center(child: Text("QTY"))),
              Expanded(child: Center(child: Text("AMT"))),
            ],
          )
        ],
      ),
    );
  }

  String _format(double a) {
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(a);
  }
}
