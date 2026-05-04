class AdminSummaryDummy {
  static const Map<String, dynamic> summary = {
    'totalEmployees': '145',
    'absentToday': '7',
    'newJoinings': '2',
    'presentToday': '138',
  };

  static const List<Map<String, dynamic>> employeeRoles = [
    {'role': 'Sales Staff', 'count': '65'},
    {'role': 'Production', 'count': '45'},
    {'role': 'Logistics', 'count': '20'},
    {'role': 'Management', 'count': '15'},
  ];

  static const List<Map<String, dynamic>> employeeAttendance = [
    {'department': 'Production', 'total': 45, 'present': 42},
  ];
}
