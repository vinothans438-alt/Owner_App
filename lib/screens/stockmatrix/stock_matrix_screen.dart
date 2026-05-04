import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import 'stock_batch_detail_screen.dart';

class StockMatrixScreen extends StatefulWidget {
  const StockMatrixScreen({Key? key}) : super(key: key);

  @override
  _StockMatrixScreenState createState() => _StockMatrixScreenState();
}

class _StockMatrixScreenState extends State<StockMatrixScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();

  // ✅ STATE VARIABLES
  List<dynamic> _sectionsList = [];
  List<dynamic> _rawMaterials = [];
  List<dynamic> _materialTypes = [];

  String _searchQuery = "";
  String _selectedSection = "All Sections";
  String _selectedMaterialType = "All Material Types";

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 3, vsync: this);

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      _loadDataForCurrentTab();
    });

    _loadSections();
    _loadMaterialTypes();
    _loadDataForCurrentTab();
  }

  // ================= DATA LOADING =================

  Future<void> _loadSections() async {
    try {
      final sections = await _apiService.fetchSections();
      if (mounted) {
        setState(() => _sectionsList = sections);
      }
    } catch (e) {
      debugPrint("Error loading sections: $e");
    }
  }

  Future<void> _loadMaterialTypes() async {
    try {
      final types = await _apiService.fetchMaterialTypes();
      debugPrint("🔥 TYPES RECEIVED IN UI: $types");

      if (mounted) {
        setState(() => _materialTypes = types);
      }
    } catch (e) {
      debugPrint("❌ Error loading material types: $e");
    }
  }

  void _loadDataForCurrentTab() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      if (_tabController.index == 0) {
        final data = await _apiService.fetchRawMaterialStock();
        setState(() {
          _rawMaterials = data;
          _isLoading = false;
        });
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error loading data: $e");
    }
  }

  // ================= DOWNLOAD HANDLER =================

  Future<void> _handleDownload(String format) async {
    final String downloadUrl =
        "${_apiService.baseUrl}/api/export-stock?format=$format";

    final Uri url = Uri.parse(downloadUrl);

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Could not launch download for $format")),
          );
        }
      }
    } catch (e) {
      debugPrint("Download error: $e");
    }
  }

  // ================= HELPERS =================

  String _getSectionName(dynamic item) {
    final section = item['section'];
    if (section is Map) return (section['name'] ?? "").toString();
    if (section is String) return section;
    if (item['section_name'] != null) return item['section_name'].toString();
    return "";
  }

  String _getMaterialTypeName(dynamic item) {
    // Check multiple paths depending on how Laravel joins the tables
    if (item['product_type'] != null && item['product_type'] is Map) {
      return (item['product_type']['name'] ?? "").toString();
    } else if (item['material_type'] != null && item['material_type'] is Map) {
      return (item['material_type']['name'] ?? "").toString();
    } else if (item['category'] != null) {
      return item['category'].toString();
    } else if (item['product_type_name'] != null) {
      return item['product_type_name'].toString();
    }
    return "";
  }

  // ================= MAIN BUILD =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black12,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black87),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/dashboard');
            }
          },
        ),
        title: const Text(
          "Available Stock Matrix",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.cloud_download_outlined,
                color: Colors.blueAccent),
            tooltip: "Export Data",
            offset: const Offset(0, 50),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: _handleDownload,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [
                    Icon(Icons.table_chart, color: Colors.green),
                    SizedBox(width: 12),
                    Text('Download Excel',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                    SizedBox(width: 12),
                    Text('Download PDF',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blueAccent,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: Colors.blueAccent,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "Raw Material"),
            Tab(text: "Packaging"),
            Tab(text: "Vendor"),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildResponsiveFilters(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.blueAccent))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRawMaterialContent(),
                      _buildEmptyState("Packaging Stock is currently empty",
                          Icons.inventory_2_outlined),
                      _buildEmptyState("Vendor Stock is currently empty",
                          Icons.local_shipping_outlined),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ================= FILTERS =================

  Widget _buildResponsiveFilters() {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth > 800;

        return Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: isDesktop
              ? Row(
                  children: [
                    Expanded(flex: 2, child: _buildSearchBar()),
                    const SizedBox(width: 16),
                    Expanded(flex: 1, child: _buildSectionDropdown()),
                    const SizedBox(width: 16),
                    Expanded(flex: 1, child: _buildMaterialTypeDropdown()),
                  ],
                )
              : Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildSectionDropdown()),
                        const SizedBox(width: 12),
                        Expanded(child: _buildMaterialTypeDropdown()),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildSearchBar(),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: "Search materials...",
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
    );
  }

  Widget _buildSectionDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedSection,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      items: [
        const DropdownMenuItem(
            value: "All Sections", child: Text("All Sections")),
        ..._sectionsList.map((section) {
          final name = (section['name'] ?? "").toString();
          if (name.isEmpty) return null;
          return DropdownMenuItem(
            value: name,
            child: Text(name, overflow: TextOverflow.ellipsis),
          );
        }).whereType<DropdownMenuItem<String>>(),
      ],
      onChanged: (val) => setState(() => _selectedSection = val!),
    );
  }

  Widget _buildMaterialTypeDropdown() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedMaterialType,
          isExpanded: true,
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          icon: const Icon(Icons.keyboard_arrow_down),
          items: [
            const DropdownMenuItem<String>(
              value: "All Material Types",
              child: Text(
                "All Material Types",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            ..._materialTypes.map((type) {
              final name = (type['name'] ?? '').toString().trim();

              if (name.isEmpty) return null;

              return DropdownMenuItem<String>(
                value: name,
                child: Text(
                  name.toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).whereType<DropdownMenuItem<String>>(),
          ],
          onChanged: (value) {
            setState(() {
              _selectedMaterialType = value!;
            });
          },
        ),
      ),
    );
  }

  // ================= CONTENT DATA =================

  // ================= CONTENT DATA =================

  Widget _buildRawMaterialContent() {
    final filteredData = _rawMaterials.where((item) {
      final name = (item['name'] ?? "").toString().toLowerCase();
      final sectionName = _getSectionName(item).toLowerCase().trim();
      final materialType = _getMaterialTypeName(item).toLowerCase().trim();

      final searchMatch = name.contains(_searchQuery);

      final sectionMatch = _selectedSection == "All Sections" ||
          sectionName == _selectedSection.toLowerCase().trim();

      final typeMatch = _selectedMaterialType == "All Material Types" ||
          materialType == _selectedMaterialType.toLowerCase().trim();

      return searchMatch && sectionMatch && typeMatch;
    }).toList();

    if (filteredData.isEmpty) {
      return _buildEmptyState(
        "No matching materials found",
        Icons.search_off_rounded,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth > 800;

        // ================= DESKTOP VIEW =================

        if (isDesktop) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              color: Colors.white,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingTextStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                    dataRowMinHeight: 55,
                    dataRowMaxHeight: 70,
                    columnSpacing: 40,
                    columns: const [
                      DataColumn(label: Text("MATERIAL NAME")),
                      DataColumn(label: Text("SECTION")),
                      DataColumn(label: Text("TYPE")),
                      DataColumn(label: Text("STOCK QUANTITY")),
                      DataColumn(label: Text("STATUS")),
                    ],
                    rows: filteredData.map((item) {
                      final qty =
                          double.tryParse((item['quantity'] ?? 0).toString()) ??
                              0;

                      final secName = _getSectionName(item);
                      final matType = _getMaterialTypeName(item);

                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              item['name'] ?? 'N/A',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          DataCell(
                            Text(secName.isNotEmpty ? secName : '-'),
                          ),

                          DataCell(
                            Text(matType.isNotEmpty ? matType : '-'),
                          ),

                          // ================= CLICKABLE QTY =================

                          DataCell(
                            InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        StockBatchDetailScreen(item: item),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.blue.shade200,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.open_in_new,
                                      size: 15,
                                      color: Colors.blue.shade700,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      qty.toString(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Colors.blue.shade900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          DataCell(_buildStatusBadge(qty)),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          );
        }

        // ================= MOBILE VIEW =================

        return ListView.builder(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 16,
          ),
          itemCount: filteredData.length,
          itemBuilder: (context, index) {
            final item = filteredData[index];

            final qty =
                double.tryParse((item['quantity'] ?? 0).toString()) ?? 0;

            final secName = _getSectionName(item);
            final matType = _getMaterialTypeName(item);

            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LEFT ICON

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.inventory_2_rounded,
                        color: Colors.blue.shade600,
                        size: 24,
                      ),
                    ),

                    const SizedBox(width: 16),

                    // CENTER DETAILS

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // MATERIAL NAME

                          Text(
                            item['name'] ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // SECTION

                          Row(
                            children: [
                              Icon(
                                Icons.category_outlined,
                                size: 14,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  secName.isNotEmpty
                                      ? secName
                                      : 'Uncategorized',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // MATERIAL TYPE

                          if (matType.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Icon(
                                  Icons.layers_outlined,
                                  size: 14,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    matType,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    // RIGHT SIDE

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // CLICKABLE QTY

                        InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    StockBatchDetailScreen(item: item),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.blue.shade200,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.touch_app_rounded,
                                  size: 16,
                                  color: Colors.blue.shade700,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  "Qty: $qty",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade900,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        _buildStatusBadge(qty),
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

  // ================= UI HELPERS =================

  Widget _buildStatusBadge(double qty) {
    Color color;
    String text;

    if (qty <= 0) {
      color = Colors.red;
      text = "Out of Stock";
    } else if (qty < 10) {
      color = Colors.orange;
      text = "Low Stock";
    } else {
      color = Colors.green;
      text = "In Stock";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style:
            TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: Colors.grey.shade100),
            child: Icon(icon, size: 60, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
