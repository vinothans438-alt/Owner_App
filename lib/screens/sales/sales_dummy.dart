class SalesDummy {
  static const Map<String, dynamic> summary = {
    'totalSales': '₹ 45,600',
    'cashSales': '₹ 15,000',
    'upiSales': '₹ 25,600',
    'transferSales': '₹ 5,000',
    'orders': '124',
    'avgOrderValue': '₹ 367',
  };

  static const List<Map<String, dynamic>> outletSales = [
    {'outlet': 'Main Branch', 'amount': '₹ 22,000'},
    {'outlet': 'South City Mall', 'amount': '₹ 14,600'},
    {'outlet': 'Airport Kiosk', 'amount': '₹ 9,000'},
  ];

  static const List<Map<String, dynamic>> categorySales = [
    {'category': 'Cakes', 'amount': '₹ 18,000'},
    {'category': 'Pastries', 'amount': '₹ 12,000'},
    {'category': 'Breads', 'amount': '₹ 8,600'},
    {'category': 'Beverages', 'amount': '₹ 7,000'},
  ];
}
