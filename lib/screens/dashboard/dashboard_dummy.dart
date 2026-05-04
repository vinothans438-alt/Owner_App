class DashboardDummy {
  static const Map<String, dynamic> summary = {
    'totalSales': '₹ 1,24,500',
    'productionSummary': '85%',
    'todayOrders': '142',
    'purchaseOverview': '₹ 45,000',
    'absentEmployees': '3',
    'otherExpenses': '₹ 12,000',
    'guestBillCount': '210',
    'highestOutlet': 'Main Branch',
    'lowestOutlet': 'South City Mall',
  };

  static const List<Map<String, String>> alerts = [
    {
      'title': 'Low stock',
      'message': 'Butter and Flour running low at Main Branch',
      'type': 'warning',
    },
    {
      'title': 'High wastage',
      'message': '15% cake wastage reported yesterday',
      'type': 'error',
    },
    {
      'title': 'Transfer delay',
      'message': 'Delivery to South City Mall delayed by 2 hours',
      'type': 'info',
    },
  ];
}
