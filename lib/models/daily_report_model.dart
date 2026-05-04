class DailyReport {
  final String date;
  final double totalSales;
  final int totalOrders;
  final double totalWastage;

  DailyReport({
    required this.date,
    required this.totalSales,
    required this.totalOrders,
    required this.totalWastage,
  });

  factory DailyReport.fromJson(Map<String, dynamic> json) {
    return DailyReport(
      date: json['date'],
      totalSales: (json['total_sales'] as num).toDouble(),
      totalOrders: json['total_orders'],
      totalWastage: (json['total_wastage'] as num).toDouble(),
    );
  }
}