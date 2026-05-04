import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/api_service.dart';
import 'reports/bill_view_screen.dart';
import 'reports/bill_items_widget.dart';

class BillDetailsScreen extends StatefulWidget {
  final String outletName;
  final int locationId;
  final String startDate;
  final String endDate;
  final String billType;

  const BillDetailsScreen({
    super.key,
    required this.outletName,
    required this.locationId,
    required this.startDate,
    required this.endDate,
    required this.billType,
  });

  @override
  State<BillDetailsScreen> createState() => _BillDetailsScreenState();
}

class _BillDetailsScreenState extends State<BillDetailsScreen> {
  // ================= INFO CHIP =================
  Widget _infoChip(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(title,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> bills = [];
  double grandTotal = 0.0;
  bool isLoading = true;

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  // ================= LOAD BILLS =================
  Future<void> _loadBills() async {
    setState(() {
      isLoading = true;
    });

    try {
      final data = await _apiService.fetchBillDetails(
        locationId: widget.locationId,
        startDate: widget.startDate,
        endDate: widget.endDate,
        billType: widget.billType,
      );

      _processBills(data);

      setState(() {
        bills = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  // ================= PROCESS TOTAL =================
  void _processBills(List<Map<String, dynamic>> data) {
    grandTotal = data.fold(0.0, (sum, b) {
      return sum + (double.tryParse(b['total']?.toString() ?? '') ?? 0.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Bills - ${widget.outletName}"),
        backgroundColor: Colors.blue.shade800,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  // ================= MAIN UI =================
  Widget _buildBody() {
    return Column(
      children: [
        // 🔵 HEADER CARD
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade800, Colors.blue.shade400],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.outletName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "${widget.startDate} → ${widget.endDate}",
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _infoChip("Bills", bills.length.toString()),
                  _infoChip("Total", _formatCurrency(grandTotal)),
                ],
              )
            ],
          ),
        ),

        // 📋 BILL LIST
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: bills.length,
            itemBuilder: (context, index) {
              final bill = bills[index];

              final billNumber = bill['bill_number'] ??
                  bill['billNo'] ??
                  bill['invoice_no'] ??
                  bill['id'] ??
                  'N/A';

              final amount =
                  double.tryParse(bill['total']?.toString() ?? '') ?? 0.0;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: ExpansionTile(
                  tilePadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  childrenPadding: const EdgeInsets.all(12),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Bill #$billNumber",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _formatCurrency(amount),
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        bill['time'] ?? '',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  children: [
                    BillItemsWidget(bill: bill),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BillViewScreen(bill: bill),
                          ),
                        );
                      },
                      child: const Text("View Full Bill"),
                    )
                  ],
                ),
              );
            },
          ),
        ),

        // 💰 STICKY TOTAL BAR
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Grand Total",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                _formatCurrency(grandTotal),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ================= FORMAT =================
  String _formatCurrency(dynamic value) {
    final val = double.tryParse(value.toString()) ?? 0;
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    ).format(val);
  }
}
