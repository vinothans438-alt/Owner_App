import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  String get baseUrl {
    // For Flutter Web (Chrome on laptop)
    if (kIsWeb) {
      return "http://localhost/demo/public";
    }

    // For Windows desktop (your laptop app)
    return "http://localhost/demo/public";
  }

  // ================= COMMON GET =================
  Future<dynamic> _getRequest(Uri url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      debugPrint("🌐 API CALL: $url");

      final response = await http.get(
        url,
        headers: {
          "Accept": "application/json",
          if (token != null) "Authorization": "Bearer $token", // ✅ FIX
        },
      );

      debugPrint("📡 STATUS: ${response.statusCode}");
      debugPrint("📦 BODY: ${response.body}");

      final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;

      if (response.statusCode == 200 && body != null) {
        return body;
      }

      throw Exception(
          body?['message'] ?? "Server Error: ${response.statusCode}");
    } catch (e) {
      debugPrint("❌ API ERROR: $e");
      rethrow;
    }
  }

  // ================= DATE HELPERS =================
  String _formatDate(DateTime date) {
    return "${date.year}-${_two(date.month)}-${_two(date.day)}";
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  Map<String, String> getDateRange(String filter) {
    final now = DateTime.now();

    switch (filter) {
      case "Today":
        return {"start": _formatDate(now), "end": _formatDate(now)};

      case "Weekly":
        final start = now.subtract(Duration(days: now.weekday - 1));
        return {"start": _formatDate(start), "end": _formatDate(now)};

      case "Monthly":
        final start = DateTime(now.year, now.month, 1);
        return {"start": _formatDate(start), "end": _formatDate(now)};

      default:
        return {"start": _formatDate(now), "end": _formatDate(now)};
    }
  }

  // ================= DASHBOARD =================
  Future<Map<String, dynamic>> fetchDashboardStats() async {
    debugPrint("🔵 DASHBOARD API HIT");
    return fetchDailyReport();
  }

  // ================= DAILY REPORT =================
  Future<Map<String, dynamic>> fetchDailyReport({
    String date = "", // ✅ NOT required anymore
    String filter = "daily",
  }) async {
    final today = date.isEmpty ? _formatDate(DateTime.now()) : date;

    final url = Uri.parse(
      "${AppConstants.baseUrl}/api/reports/daily-summary",
    ).replace(queryParameters: {
      "date": today,
      "filter": filter,
      "location_id": "1",
    });

    final data = await _getRequest(url);
    return data as Map<String, dynamic>;
  }

  // ================= DAY REPORT =================
  Future<List<Map<String, dynamic>>> fetchDayReport({
    String? startDate,
    String? endDate,
    int? locationId,
  }) async {
    final url = Uri.parse(
      "${AppConstants.baseUrl}/api/comprehensive-sales-summary",
    ).replace(queryParameters: {
      "start_date": startDate ?? _formatDate(DateTime.now()),
      "end_date": endDate ?? _formatDate(DateTime.now()),
      if (locationId != null) "location_id": locationId.toString(),
    });

    final data = await _getRequest(url);

    final List locations = data['locations'] ?? [];
    final Map dayMetrics = data['dayMetrics'] ?? {};

    return locations.map<Map<String, dynamic>>((loc) {
      final id = loc['id']; // IMPORTANT KEEP THIS

      final m = dayMetrics[id.toString()] ?? {};

      return {
        "id": id,
        "name": loc['name'] ?? "Unknown",

        "bills": _toInt(m['bills']),
        "cash": _toDouble(m['cash']),
        "upi": _toDouble(m['upi']),
        "expense": _toDouble(m['expense']),

        "opening_balance": _toDouble(m['opening']),
        "closing_balance": _toDouble(m['closing']),

        "edit_bill": _toInt(m['edit']), // ✅ FIX
        "cancel": _toInt(m['cancel']), // ✅ FIX
        "return": _toInt(m['return']), // ✅ FIX

        "guest": _toInt(m['guest']), // ✅ FIXED
        "b2b_bill": _toInt(m['b2b']), // ✅ FIXED
      };
    }).toList();
  }

  // ================= ITEM WISE REPORT =================
  Future<Map<String, dynamic>> fetchItemReport({
    String? startDate,
    String? endDate,
  }) async {
    final url = Uri.parse(
      "${AppConstants.baseUrl}/api/comprehensive-sales-summary",
    ).replace(queryParameters: {
      "start_date": startDate ?? _formatDate(DateTime.now()),
      "end_date": endDate ?? _formatDate(DateTime.now()),
    });

    final data = await _getRequest(url);

    try {
      final List locations = data['locations'] ?? [];
      final List items = data['itemMetrics'] ?? [];

      if (locations.isEmpty || items.isEmpty) {
        return {"outlets": [], "products": []};
      }

      final Map<String, String> locationMap = {
        for (var l in locations) l['id'].toString(): l['name'].toString()
      };

      final products = items.map<Map<String, dynamic>>((item) {
        final Map<String, dynamic> outletMap = {};

        if (item['outlets'] is Map) {
          (item['outlets'] as Map).forEach((locId, val) {
            final name = locationMap[locId.toString()];
            if (name != null) {
              outletMap[name] = val;
            }
          });
        }

        return {
          "name": item['product_name'] ?? "",
          "outlets": outletMap,
          "total_qty": _toInt(item['total_qty']),
          "total_amt": _toDouble(item['total_amt']),
        };
      }).toList();

      return {
        "outlets": locations.map((l) => l['name'].toString()).toList(),
        "products": products,
      };
    } catch (e) {
      debugPrint("❌ ITEM REPORT ERROR: $e");
      throw Exception("Invalid Item Report Format");
    }
  }

  // ================= HOURLY SALES REPORT (NEW FIXED VERSION) =================
  Future<Map<String, dynamic>> fetchHourlySales({
    String? startDate,
    String? endDate,
  }) async {
    final url = Uri.parse(
      "${AppConstants.baseUrl}/api/hourly-sales-report",
    ).replace(queryParameters: {
      "start_date": startDate ?? _formatDate(DateTime.now()),
      "end_date": endDate ?? _formatDate(DateTime.now()),
    });

    final data = await _getRequest(url);

    try {
      // Expected:
      // { "outlets": { "SR PURAM": {"0-2 HRS": 100, ...} } }

      final outlets = data["outlets"];

      if (outlets == null || outlets is! Map) {
        return {"outlets": {}};
      }

      return {
        "outlets": Map<String, dynamic>.from(outlets),
      };
    } catch (e) {
      debugPrint("❌ HOURLY REPORT ERROR: $e");
      throw Exception("Invalid Hourly Report Format");
    }
  }

  // ================= SAFE PARSERS =================
  int _toInt(dynamic v) => v == null ? 0 : int.tryParse(v.toString()) ?? 0;

  double _toDouble(dynamic v) =>
      v == null ? 0.0 : double.tryParse(v.toString()) ?? 0.0;

  Future<List<Map<String, dynamic>>> fetchBillDetails({
    required int locationId,
    required String startDate,
    required String endDate,
    required String billType,
  }) async {
    final uri = Uri.parse(
      "${AppConstants.baseUrl}/api/reports/bill-details",
    ).replace(queryParameters: {
      "start_date": startDate,
      "end_date": endDate,
      "location_id": locationId.toString(),
      "bill_type": billType,
    });

    final data = await _getRequest(uri);

    debugPrint("🧾 FULL BILL RESPONSE: $data");

    List<dynamic> rawList = [];

    // ✅ CASE 1: API returns list directly
    if (data is List) {
      rawList = data;
    }

    // ✅ CASE 2: API returns nested map
    else if (data is Map<String, dynamic>) {
      rawList = (data['data'] ??
          data['bills'] ??
          data['result'] ??
          data['records'] ??
          []) as List;
    }

    debugPrint("📦 PARSED BILL COUNT: ${rawList.length}");

    return rawList.map<Map<String, dynamic>>((b) {
      debugPrint("➡️ BILL ITEM: $b");

      return {
        "bill_number": b['bill_number'] ?? b['bill_no'] ?? b['id'] ?? '',
        "time": b['time'] ?? b['date'] ?? '',
        "total": _toDouble(b['total'] ?? b['amount'] ?? b['grand_total']),
        "payment_method": b['payment_method'] ?? b['payment_mode'] ?? '',
        "items": b['items'] ?? [],
        "items_count": b['items_count'] ?? (b['items'] as List?)?.length ?? 0,
      };
    }).toList();
  }

//=============================== PURCHASE REPORT =================
  Future<List<Map<String, dynamic>>> fetchPurchaseReport({
    required String type,
    required String startDate,
    required String endDate,
  }) async {
    final url = Uri.parse(
      "${AppConstants.baseUrl}/api/purchase-report",
    ).replace(queryParameters: {
      "type": type,
      "start_date": startDate,
      "end_date": endDate,
    });

    final data = await _getRequest(url);

    debugPrint("📦 RAW PURCHASE RESPONSE: $data");
    debugPrint("📌 SELECTED TYPE: $type");

    if (data is Map<String, dynamic>) {
      // ================= PURCHASE RECEIVED =================
      if (type == "Purchase Received") {
        final List received = data["received"] ?? [];

        debugPrint("📊 RECEIVED COUNT: ${received.length}");

        return received.map<Map<String, dynamic>>((e) {
          return {
            "id": e["id"] ?? "",
            "invoice_no": e["invoice_no"] ?? "",
            "date": e["date"] ?? "",
            "vendor": e["vendor"] ?? "",
            "grand_total": e["grand_total"] ?? 0,
            "paid_amount": e["paid_amount"] ?? 0,
            "balance": e["balance"] ?? 0,
            "status": e["status"] ?? "Unpaid",
          };
        }).toList();
      }

      // ================= PURCHASE ORDERS =================
      if (type == "Purchase Orders") {
        final List orders = data["purchase_orders"] ?? [];

        debugPrint("📊 PURCHASE ORDERS COUNT: ${orders.length}");

        return orders.map<Map<String, dynamic>>((e) {
          return {
            "id": e["id"] ?? "",
            "date": e["date"] ?? "",
            "vendor": e["vendor"] ?? "",
            "item_count": e["item_count"] ?? 0,
            "total_qty": e["total_qty"] ?? 0,
            "expected_date": e["expected_date"] ?? "-",
            "status": e["status"] ?? "Pending",
          };
        }).toList();
      }

      // ================= STOCK =================
      if (type == "Raw Material Stock") {
        final List stock = data["stock"] ?? [];

        return stock.map<Map<String, dynamic>>((e) {
          return {
            "id": e["id"] ?? "",
            "name": e["name"] ?? "",
            "current_stock": e["current_stock"] ?? 0,
            "unit": e["unit"] ?? "",
            "status": e["status"] ?? "",
          };
        }).toList();
      }
    }

    return [];
  }

  // ================= SECTIONS API =================
  Future<List<Map<String, dynamic>>> fetchSections() async {
    final url = Uri.parse("${AppConstants.baseUrl}/api/sections");

    final data = await _getRequest(url);

    if (data is List) {
      return data.map<Map<String, dynamic>>((e) {
        return {
          "id": e["id"],
          "name": e["name"],
        };
      }).toList();
    }

    return [];
  }

  Future<Map<String, dynamic>> fetchProductionReport({
    required String startDate,
    required String endDate,
  }) async {
    final url = Uri.parse(
      "${AppConstants.baseUrl}/api/production-report",
    ).replace(queryParameters: {
      "start_date": startDate,
      "end_date": endDate,
    });

    final data = await _getRequest(url);

    debugPrint("📦 FULL PRODUCTION RESPONSE: $data");

    return data;
  }

// ================= GST REPORT =================
  Future<dynamic> fetchGSTReport({
    required String startDate,
    required String endDate,
  }) async {
    final uri = Uri.parse(
      "http://localhost/demo/public/api/reports/gst-report",
    ).replace(queryParameters: {
      "from_date": startDate, // ✅ FIXED
      "to_date": endDate, // ✅ FIXED
    });

    print("🌐 GST API CALL: $uri"); // debug

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load GST report");
    }
  }

// ================= STOCK MATRIX =================
  Future<List<dynamic>> fetchPackagingStock() async {
    debugPrint("🟢 STOCK MATRIX SCREEN LOADED");

    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/packaging-stock'),
        headers: {
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint("❌ Packaging Error: $e");
    }

    return [];
  }

  Future<List<dynamic>> fetchVendorStock() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/vendor-stock'),
        headers: {
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint("❌ Vendor Error: $e");
    }

    return [];
  }

  Future<List<dynamic>> fetchRawMaterialStock({String search = ""}) async {
    try {
      final String fullUrl =
          "http://localhost/demo/public/api/available-stock?search=$search";

      debugPrint("🚀 CALLING STOCK MATRIX API: $fullUrl");

      final response = await http.get(
        Uri.parse(fullUrl),
        headers: {
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return [];
      }
    } catch (e) {
      debugPrint("❌ ERROR: $e");
      return [];
    }
  }

  Future<List<dynamic>> fetchMaterialTypes() async {
    final url = Uri.parse('$baseUrl/api/product-types');

    final data = await _getRequest(url);

    debugPrint("📦 MATERIAL TYPES DATA: $data");

    if (data is List) {
      return data;
    } else {
      return [];
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/outlet/login"),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      debugPrint("📡 LOGIN STATUS: ${response.statusCode}");
      debugPrint("📦 LOGIN RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final token = data['token'] ?? data['access_token'];

        if (token == null) {
          debugPrint("❌ TOKEN NOT FOUND IN RESPONSE");
          return false;
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", token); // ✅ FIXED

        debugPrint("✅ TOKEN SAVED: $token");

        return true;
      } else {
        debugPrint("❌ LOGIN FAILED");
        return false;
      }
    } catch (e) {
      debugPrint("❌ LOGIN ERROR: $e");
      return false;
    }
  }
}
