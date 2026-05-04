class ProductionDummy {
  static const Map<String, dynamic> summary = {
    'totalProduced': '1,240 Units',
    'availableStock': '450 Units',
    'wasteSummary': '12.5 kg',
    'efficiency': '92%',
  };

  static const List<Map<String, dynamic>> sectionProduction = [
    {'section': 'Bread & Buns', 'items': '450', 'status': 'Completed'},
    {'section': 'Cakes & Pastries', 'items': '120', 'status': 'In Progress'},
    {'section': 'Cookies & Biscuits', 'items': '670', 'status': 'Completed'},
  ];

  static const List<Map<String, dynamic>> activeProduction = [
    {'item': 'Chocolate Truffle Cake', 'quantity': '20 kg', 'status': 'Baking', 'progress': 0.6},
    {'item': 'Sandwich Bread', 'quantity': '100 loaves', 'status': 'Proofing', 'progress': 0.4},
  ];
}
