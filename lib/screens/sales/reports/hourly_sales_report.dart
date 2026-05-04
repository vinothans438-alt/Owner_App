import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

class HourlySalesReport extends StatefulWidget {
  final String startDate;
  final String endDate;

  const HourlySalesReport({
    super.key,
    required this.startDate,
    required this.endDate,
  });

  @override
  State<HourlySalesReport> createState() => _HourlySalesReportState();
}

class _HourlySalesReportState extends State<HourlySalesReport> {
  final ApiService api = ApiService();

  bool isLoading = false;
  String? error;

  Map<String, dynamic> reportData = {};
  String selectedOutlet = "ALL";

  final List<String> hours = [
    "0-2 HRS",
    "2-4 HRS",
    "4-6 HRS",
    "6-8 HRS",
    "8-10 HRS",
    "10-12 HRS",
    "12-14 HRS",
    "14-16 HRS",
    "16-18 HRS",
    "18-20 HRS",
    "20-22 HRS",
    "22-24 HRS"
  ];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  // ================= FETCH API =================
  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final res = await api.fetchHourlySales(
        startDate: widget.startDate,
        endDate: widget.endDate,
      );

      setState(() {
        reportData = Map<String, dynamic>.from(res);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  // ================= SAFE LIST =================
  List<Map<String, dynamic>> get hourlyList {
    final raw = reportData['hourlyMetrics'];
    if (raw is List) {
      return List<Map<String, dynamic>>.from(raw);
    }
    return [];
  }

  // ================= DYNAMIC OUTLETS =================
  List<String> get outlets {
    final list = hourlyList
        .map((e) => e['label']?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    list.sort();
    return list;
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return _errorWidget();
    }

    return Column(
      children: [
        _buildOutletSelector(),
        const SizedBox(height: 10),
        Expanded(child: _buildTable()),
      ],
    );
  }

  // ================= ERROR =================
  Widget _errorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Error: $error"),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: fetchData,
            child: const Text("Retry"),
          )
        ],
      ),
    );
  }

  // ================= OUTLET BUTTONS =================
  Widget _buildOutletSelector() {
    final buttons = ["ALL", ...outlets];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: buttons.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final outlet = buttons[index];
          final selected = selectedOutlet == outlet;

          return ChoiceChip(
            label: Text(
              outlet,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.black,
              ),
            ),
            selected: selected,
            selectedColor: Colors.black,
            backgroundColor: Colors.grey.shade200,
            onSelected: (_) {
              setState(() => selectedOutlet = outlet);
            },
          );
        },
      ),
    );
  }

  // ================= TABLE =================
  Widget _buildTable() {
    return Card(
      margin: const EdgeInsets.all(10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: DataTable(
            columnSpacing: 20,
            headingRowColor: WidgetStateProperty.all(Colors.grey.shade200),
            border: TableBorder.all(color: Colors.grey.shade300),
            columns: _buildColumns(),
            rows: _buildRows(),
          ),
        ),
      ),
    );
  }

  // ================= COLUMNS =================
  List<DataColumn> _buildColumns() {
    return [
      const DataColumn(
        label: Text("OUTLET", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      ...hours.map(
        (h) => DataColumn(
          label: Text(h, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
      const DataColumn(
        label: Text("TOTAL", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    ];
  }

  // ================= ROWS =================
  List<DataRow> _buildRows() {
    final data = hourlyList;

    final filtered = selectedOutlet == "ALL"
        ? data
        : data.where((e) => e['label'] == selectedOutlet).toList();

    // ✅ FIXED EMPTY STATE (NO CRASH)
    if (filtered.isEmpty) {
      return [
        DataRow(
          cells: List.generate(
            hours.length + 2,
            (index) {
              if (index == 0) {
                return const DataCell(Text("No Data"));
              }
              return const DataCell(Text("-"));
            },
          ),
        )
      ];
    }

    // ✅ SAFE ROW BUILDER
    return filtered.map((row) {
      final slots = row['slots'];

      final Map<String, dynamic> slotMap =
          slots is Map ? Map<String, dynamic>.from(slots) : {};

      double total = 0;
      final cells = <DataCell>[];

      // Outlet name
      cells.add(
        DataCell(Text(
          row['label'] ?? '-',
          style: const TextStyle(fontWeight: FontWeight.w600),
        )),
      );

      // Hour columns
      for (final h in hours) {
        final val = num.tryParse(slotMap[h]?.toString() ?? '0') ?? 0;

        total += val;

        cells.add(
          DataCell(Center(child: Text(val.toString()))),
        );
      }

      // Total column
      cells.add(
        DataCell(
          Text(
            (row['total'] ?? total).toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );

      // 🔥 FINAL SAFETY (prevents future crashes)
      while (cells.length < hours.length + 2) {
        cells.add(const DataCell(Text("-")));
      }

      return DataRow(cells: cells);
    }).toList();
  }
}
