class AccountantSummaryDummy {
  static const Map<String, dynamic> summary = {
    'totalRevenue': '₹ 12,50,000',
    'totalExpenses': '₹ 8,20,000',
    'netProfit': '₹ 4,30,000',
    'cashInHand': '₹ 1,15,000',
    'bankBalance': '₹ 8,50,000',
    'unpaidInvoices': '18',
  };

  static const List<Map<String, dynamic>> recentTransactions = [
    {'date': 'Today, 10:30 AM', 'description': 'Supplier Payment - National Flour Mills', 'type': 'Debit', 'amount': '₹ 1,20,000'},
    {'date': 'Today, 09:15 AM', 'description': 'Main Branch Daily Deposit', 'type': 'Credit', 'amount': '₹ 85,000'},
    {'date': 'Yesterday', 'description': 'Electricity Bill', 'type': 'Debit', 'amount': '₹ 18,500'},
    {'date': 'Yesterday', 'description': 'South City Mall Deposit', 'type': 'Credit', 'amount': '₹ 42,000'},
  ];

  static const List<Map<String, dynamic>> expenseBreakdown = [
    {'category': 'Raw Materials', 'amount': '₹ 4,50,000', 'percentage': 55},
    {'category': 'Salaries', 'amount': '₹ 2,10,000', 'percentage': 25},
    {'category': 'Utilities', 'amount': '₹ 85,000', 'percentage': 10},
    {'category': 'Transport & Fuel', 'amount': '₹ 45,000', 'percentage': 5},
    {'category': 'Misc & Maint', 'amount': '₹ 30,000', 'percentage': 5},
  ];
}
