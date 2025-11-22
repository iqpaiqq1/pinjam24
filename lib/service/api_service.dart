// lib/service/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://192.168.1.7:8000/api";
  static String? token;

  /// Helper: Generate headers
  static Map<String, String> get headers {
    return {
      "Accept": "application/json",
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  // ======================
  // AUTH
  // ======================

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data["token"] != null) {
        token = data["token"];
      }

      return data;
    } catch (e) {
      return {"error": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> register(
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );
      return json.decode(response.body);
    } catch (e) {
      return {"error": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> logout() async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/logout"),
        headers: headers,
      );

      if (response.statusCode == 200) {
        token = null;
        return {"success": true, "message": "Logout berhasil"};
      }

      return json.decode(response.body);
    } catch (e) {
      return {"error": e.toString()};
    }
  }

  // ======================
  // GET USER DETAIL (ME)
  // ======================
  static Future<Map<String, dynamic>> getMyDetail() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/me"),
        headers: headers,
      );
      return json.decode(response.body);
    } catch (e) {
      return {"error": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateMyDetail(
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/me/update"),
        headers: headers,
        body: jsonEncode(body),
      );
      return json.decode(response.body);
    } catch (e) {
      return {"error": e.toString()};
    }
  }

  // ======================
  // GENERIC CRUD METHOD
  // ======================
  static Future<Map<String, dynamic>> getAll(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/$endpoint"),
        headers: headers,
      );
      return json.decode(response.body);
    } catch (e) {
      return {"error": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getById(String endpoint, int id) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/$endpoint/$id"),
        headers: headers,
      );
      return json.decode(response.body);
    } catch (e) {
      return {"error": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> create(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/$endpoint/create"),
        headers: headers,
        body: jsonEncode(body),
      );
      return json.decode(response.body);
    } catch (e) {
      return {"error": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> update(
    String endpoint,
    int id,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/$endpoint/$id/update"),
        headers: headers,
        body: jsonEncode(body),
      );
      return json.decode(response.body);
    } catch (e) {
      return {"error": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> delete(String endpoint, int id) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/$endpoint/$id/delete"),
        headers: headers,
      );
      return json.decode(response.body);
    } catch (e) {
      return {"error": e.toString()};
    }
  }

  // ======================
  // PEMINJAMAN
  // ======================
  static Future<Map<String, dynamic>> getMyPeminjaman() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/peminjaman/me"),
        headers: headers,
      );
      return json.decode(response.body);
    } catch (e) {
      return {"error": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getActivePeminjaman() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/peminjaman/active"),
        headers: headers,
      );
      return json.decode(response.body);
    } catch (e) {
      return {"error": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> createPeminjaman(
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/peminjaman"),
        headers: headers,
        body: jsonEncode(body),
      );
      return json.decode(response.body);
    } catch (e) {
      return {"error": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> returnProduct(int id) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/peminjaman/$id/return"),
        headers: headers,
      );
      return json.decode(response.body);
    } catch (e) {
      return {"error": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> checkPin(String pin) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/peminjaman/check-pin"),
        headers: headers,
        body: jsonEncode({"pin": pin}),
      );
      return json.decode(response.body);
    } catch (e) {
      return {"error": e.toString()};
    }
  }

  // Method untuk cek token
  static String? getToken() {
    return token;
  }

  // Method untuk set token manual
  static void setToken(String newToken) {
    token = newToken;
  }

  // Clear token (untuk logout)
  static void clearToken() {
    token = null;
  }
}
