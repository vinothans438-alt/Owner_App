import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/responsive_scaffold.dart';
import '../../services/api_service.dart';

class ProductionScreen extends StatefulWidget {
  const ProductionScreen({super.key});

  @override
  State<ProductionScreen> createState() => _ProductionScreenState();
}

class _ProductionScreenState extends State<ProductionScreen> {
  Map<String, dynamic> summary = {};

  final ApiService _apiService = ApiService();

  // ================= DYNAMIC SECTIONS =================
  List<String> sections = ["All"];
  String selectedSection = "All";

  // ================= SAMPLE DATA (REPLACE WITH API) =================
  List<Map<String, dynamic>> productionData = [];

  List<Map<String, dynamic>> transferData = [];
  List<Map<String, dynamic>> disputeData = [];

  // ================= DATE FILTER =================
  String selectedFilter = "today";
  DateTime? fromDate;
  DateTime? toDate;

  // ================= DROPDOWN =================
  String selectedReportType = "Produced Stock";

  // ================= SEARCH =================
  final TextEditingController searchController = TextEditingController();

  // ================= INIT =================
  @override
  void initState() {
    super.initState();
    _loadData(); // ✅ data load
  }

  // ================= MOCK LOAD SECTIONS =================
  /* Future<void> _loadSections() async {
    // 🔥 Replace with API later
    final res = ["Bakery", "Donation", "Kaaram", "Sweet", "Murukku"];

    setState(() {
      sections = ["All", ...res];
    });
  }*/

  // ================= MOCK LOAD DATA =================
  Future<void> _loadData() async {
    try {
      final now = DateTime.now();

      String startDate;
      String endDate;

      if (selectedFilter == "today") {
        startDate = DateFormat('yyyy-MM-dd').format(now);
        endDate = startDate;
      } else if (selectedFilter == "weekly") {
        final start = _startOfWeek(now);
        startDate = DateFormat('yyyy-MM-dd').format(start);
        endDate = DateFormat('yyyy-MM-dd').format(now);
      } else if (selectedFilter == "monthly") {
        final start = DateTime(now.year, now.month, 1);
        startDate = DateFormat('yyyy-MM-dd').format(start);
        endDate = DateFormat('yyyy-MM-dd').format(now);
      } else if (selectedFilter == "custom" &&
          fromDate != null &&
          toDate != null) {
        startDate = DateFormat('yyyy-MM-dd').format(fromDate!);
        endDate = DateFormat('yyyy-MM-dd').format(toDate!);
      } else {
        startDate = DateFormat('yyyy-MM-dd').format(now);
        endDate = startDate;
      }

      final res = await _apiService.fetchProductionReport(
        startDate: startDate,
        endDate: endDate,
      );

      final apiSections = res['sections'] ?? [];
      final productionMap = res['production'] is Map ? res['production'] : {};
      final transfers = res['transfers'] ?? [];
      final disputes = res['disputes'] ?? [];

      setState(() {
        /// ✅ Sections
        sections = ["All", ...apiSections.map((e) => e.toString())];

        /// ✅ Summary
        summary = res['summary'] ?? {};

        /// ================= PRODUCTION =================
        productionData = [];
        productionMap.forEach((section, items) {
          for (var item in items) {
            productionData.add({
              "name": item['name'],
              "qty": item['total_qty'].toString(),
              "section": section,
              "unit": item['unit'] ?? "",
            });
          }
        });

        /// ================= TRANSFERS =================
        transferData = [];
        for (var outlet in transfers) {
          for (var item in outlet['items']) {
            transferData.add({
              "name": item['name'],
              "qty": item['quantity'].toString(),
              "section": item['section'],
              "outlet": outlet['outlet_name'],
            });
          }
        }

        /// ================= DISPUTES =================
        disputeData = [];
        for (var d in disputes) {
          disputeData.add({
            "name": d['product'],
            "qty": d['transferred_qty'].toString(),
            "section": d['section'],
            "status": d['status'],
            "note": d['note'],
            "outlet": d['outlet'],
          });
        }
      });
    } catch (e) {
      debugPrint("❌ Production API Error: $e");
    }
  }

  // ================= FORMAT =================
  String formatDisplayDate(DateTime date) {
    return DateFormat('MM/dd/yyyy').format(date);
  }

  DateTime _startOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday % 7));
  }

  DateTime _endOfWeek(DateTime date) {
    return _startOfWeek(date).add(const Duration(days: 6));
  }

  String getDisplayDate() {
    final now = DateTime.now();

    if (selectedFilter == "today") {
      return formatDisplayDate(now);
    } else if (selectedFilter == "weekly") {
      return "${formatDisplayDate(_startOfWeek(now))} - ${formatDisplayDate(_endOfWeek(now))}";
    } else if (selectedFilter == "monthly") {
      return "${formatDisplayDate(DateTime(now.year, now.month, 1))} - ${formatDisplayDate(now)}";
    } else if (selectedFilter == "custom" &&
        fromDate != null &&
        toDate != null) {
      return "${formatDisplayDate(fromDate!)} - ${formatDisplayDate(toDate!)}";
    }
    return "";
  }

  // ================= DATE PICKER =================
  Future<void> _pickDateRange() async {
    DateTime tempFrom = fromDate ?? DateTime.now();
    DateTime tempTo = toDate ?? DateTime.now();

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
              subtitle: Text(formatDisplayDate(tempFrom)),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: tempFrom,
                  firstDate: DateTime(2023),
                  lastDate: now,
                );
                if (picked != null) tempFrom = picked;
              },
            ),
            ListTile(
              title: const Text("To Date"),
              subtitle: Text(formatDisplayDate(tempTo)),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: tempTo,
                  firstDate: DateTime(2023),
                  lastDate: now,
                );
                if (picked != null) tempTo = picked;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              setState(() {
                fromDate = tempFrom;
                toDate = tempTo;
                selectedFilter = "custom";
              });
              Navigator.pop(context);
            },
            child: const Text("Apply"),
          ),
        ],
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: "Production Report",
      body: Column(
        children: [
          _buildHeader(),
          _buildSummaryCards(),
          _buildTabs(),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  // ================= HEADER =================
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          /// FILTER
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _chip("Today", "today"),
              _chip("Weekly", "weekly"),
              _chip("Monthly", "monthly"),
              _chip("Custom", "custom"),

              /// ✅ Show date directly (no big button)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(getDisplayDate()),
              ),

              /// ✅ Small icon instead of big button
              /*  if (selectedFilter == "custom")
                IconButton(
                  icon: const Icon(Icons.date_range),
                  onPressed: _pickDateRange,
                ),*/
            ],
          ),

          const SizedBox(height: 10),

          /// DROPDOWN + SEARCH
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: selectedReportType,
                  items: ["Produced Stock", "Transfers", "Disputes"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) {
                    setState(() => selectedReportType = val!);
                    _loadData();
                  },
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: "Search...",
                    prefixIcon: Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _chip(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: selectedFilter == value,
      onSelected: (_) async {
        setState(() => selectedFilter = value);

        if (value == "custom") {
          await _pickDateRange();
        }

        _loadData(); // ✅ IMPORTANT (reload API)
      },
    );
  }

  // ================= SUMMARY =================
  Widget _buildSummaryCards() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
              child: _card("Produced", "${summary['total_produced'] ?? 0}",
                  Colors.blue)),
          const SizedBox(width: 8),
          Expanded(
              child: _card("Transfers", "${summary['total_transferred'] ?? 0}",
                  Colors.green)),
          const SizedBox(width: 8),
          Expanded(
              child: _card("Disputes", "${summary['active_disputes'] ?? 0}",
                  Colors.red)),
        ],
      ),
    );
  }

  Widget _card(String t, String v, Color c) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(t),
          Text(v, style: const TextStyle(fontWeight: FontWeight.bold))
        ],
      ),
    );
  }

  // ================= TABS =================
  Widget _buildTabs() {
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: sections.length,
        itemBuilder: (_, i) {
          final tab = sections[i];
          final isSelected = selectedSection == tab;

          return GestureDetector(
            onTap: () {
              setState(() => selectedSection = tab);
              _loadData();
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  tab,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: const Row(
        children: [
          Expanded(flex: 3, child: Text("Item")),
          Expanded(flex: 2, child: Text("Section")),
          Expanded(
            flex: 2,
            child: Center(child: Text("Unit")),
          ),
          Expanded(
            flex: 2,
            child: Text("Qty", textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  // ================= LIST =================
  Widget _buildList() {
    List data = [];

    if (selectedReportType == "Produced Stock") {
      data = productionData;
    } else if (selectedReportType == "Transfers") {
      data = transferData;
    } else if (selectedReportType == "Disputes") {
      data = disputeData;
    }

    List filtered = data.where((e) {
      final matchSection = selectedSection == "All" ||
          (e["section"] ?? "").toString() == selectedSection;

      final matchSearch = e["name"]
          .toString()
          .toLowerCase()
          .contains(searchController.text.toLowerCase());

      return matchSection && matchSearch;
    }).toList();

    if (filtered.isEmpty) {
      return const Center(child: Text("No Data Found"));
    }

    return Column(
      children: [
        /// ✅ SINGLE HEADER (Production + Transfers)
        if (selectedReportType != "Disputes") _buildTableHeader(),

        /// 🔥 LIST
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: filtered.length,
            itemBuilder: (_, i) {
              final item = filtered[i];

              /// ❌ DISPUTES (KEEP CARD)
              if (selectedReportType == "Disputes") {
                return Card(
                  child: ListTile(
                    title: Text(item["name"] ?? ""),
                    subtitle: Text(
                      "Outlet: ${item["outlet"] ?? ""}\n"
                      "Status: ${item["status"] ?? ""}\n"
                      "Note: ${item["note"] ?? ""}",
                    ),
                    trailing: Text(item["qty"] ?? ""),
                  ),
                );
              }

              /// ✅ COMMON TABLE ROW (Production + Transfers)
              return Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  children: [
                    /// ITEM
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(
                          item["name"] ?? "",
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),

                    /// SECTION
                    Expanded(
                      flex: 2,
                      child: Text(
                        item["section"] ?? "-",
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    /// UNIT (CENTER ALIGN FIX)
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Text(item["unit"] ?? "-"),
                      ),
                    ),

                    /// QTY (RIGHT ALIGN)
                    Expanded(
                      flex: 2,
                      child: Text(
                        item["qty"] ?? "0",
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
