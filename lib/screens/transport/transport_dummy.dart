class TransportDummy {
  static const Map<String, dynamic> summary = {
    'activeTrips': '8',
    'fuelExpense': '₹ 15,400',
    'totalVehicles': '12',
    'pendingDeliveries': '4',
  };

  static const List<Map<String, dynamic>> trips = [
    {'route': 'Route A (North City)', 'vehicle': 'V-101', 'driver': 'Ramesh', 'status': 'Delivered'},
    {'route': 'Route B (South City)', 'vehicle': 'V-102', 'driver': 'Suresh', 'status': 'In Transit'},
    {'route': 'Route C (East City)', 'vehicle': 'V-103', 'driver': 'Dinesh', 'status': 'Dispatched'},
  ];

  static const List<Map<String, dynamic>> activeRoutes = [
    {'route': 'Route A (North City)', 'status': 'On Time'},
  ];
}
