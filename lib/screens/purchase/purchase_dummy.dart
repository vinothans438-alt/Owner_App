class PurchaseDummy {
  static const Map<String, dynamic> summary = {
    'totalPurchase': '₹ 85,000',
    'pendingOrders': '3',
    'lowStockRM': '5 Items',
    'activeVendors': '12',
  };

  static const List<Map<String, dynamic>> purchaseOrders = [
    {'poNumber': 'PO-2024-001', 'vendor': 'National Flour Mills', 'amount': '₹ 15,000', 'status': 'Approved', 'date': '12 Mar'},
    {'poNumber': 'PO-2024-002', 'vendor': 'Dairy Fresh Co.', 'amount': '₹ 12,500', 'status': 'Pending', 'date': '14 Mar'},
    {'poNumber': 'PO-2024-003', 'vendor': 'Sweet Supplies Ltd.', 'amount': '₹ 8,000', 'status': 'Transit', 'date': '15 Mar'},
  ];

  static const List<Map<String, dynamic>> recentOrders = [
    {'vendor': 'National Flour Mills', 'item': 'Maida 50kg Bags', 'amount': '₹ 15,000', 'status': 'Delivered'},
  ];
}
