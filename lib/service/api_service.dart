// lib/service/api_service.dart
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://192.168.1.7:8000/api";
  static String? token;

  // Timeout duration
  static const Duration timeoutDuration = Duration(seconds: 15);

  /// Helper: Generate headers
  static Map<String, String> get headers {
    return {
      "Accept": "application/json",
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  // Helper method untuk handle response
  static Map<String, dynamic> _handleResponse(http.Response response) {
    final data = json.decode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw ApiException(
        data['message'] ?? 'Request failed with status ${response.statusCode}',
        statusCode: response.statusCode,
        responseData: data,
      );
    }
  }

  // Helper method untuk handle request dengan timeout
  static Future<Map<String, dynamic>> _handleRequest(
      Future<http.Response> request) async {
    try {
      final response = await request.timeout(timeoutDuration);
      return _handleResponse(response);
    } on http.ClientException catch (e) {
      throw ApiException('Network error: $e');
    } on TimeoutException {
      throw ApiException('Request timeout');
    } on FormatException {
      throw ApiException('Invalid response format');
    }
  }

  // ======================
  // AUTH
  // ======================

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await _handleRequest(
      http.post(
        Uri.parse("$baseUrl/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      ),
    );

    if (response["token"] != null) {
      token = response["token"];
    }

    return response;
  }

  static Future<Map<String, dynamic>> register(
    Map<String, dynamic> body,
  ) async {
    return await _handleRequest(
      http.post(
        Uri.parse("$baseUrl/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      ),
    );
  }

  static Future<Map<String, dynamic>> logout() async {
    final response = await _handleRequest(
      http.post(
        Uri.parse("$baseUrl/logout"),
        headers: headers,
      ),
    );

    token = null;
    return response;
  }

  // ======================
  // GET USER DETAIL (ME)
  // ======================
  static Future<Map<String, dynamic>> getMyDetail() async {
    return await _handleRequest(
      http.get(
        Uri.parse("$baseUrl/me"),
        headers: headers,
      ),
    );
  }

  static Future<Map<String, dynamic>> updateMyDetail(
    Map<String, dynamic> body,
  ) async {
    return await _handleRequest(
      http.put(
        Uri.parse("$baseUrl/me/update"),
        headers: headers,
        body: jsonEncode(body),
      ),
    );
  }

  // ======================
  // GENERIC CRUD METHOD
  // ======================
  static Future<Map<String, dynamic>> getAll(String endpoint) async {
    return await _handleRequest(
      http.get(
        Uri.parse("$baseUrl/$endpoint"),
        headers: headers,
      ),
    );
  }

  static Future<Map<String, dynamic>> getById(String endpoint, int id) async {
    return await _handleRequest(
      http.get(
        Uri.parse("$baseUrl/$endpoint/$id"),
        headers: headers,
      ),
    );
  }

  static Future<Map<String, dynamic>> create(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    return await _handleRequest(
      http.post(
        Uri.parse("$baseUrl/$endpoint/create"),
        headers: headers,
        body: jsonEncode(body),
      ),
    );
  }

  static Future<Map<String, dynamic>> update(
    String endpoint,
    int id,
    Map<String, dynamic> body,
  ) async {
    return await _handleRequest(
      http.put(
        Uri.parse("$baseUrl/$endpoint/$id/update"),
        headers: headers,
        body: jsonEncode(body),
      ),
    );
  }

  static Future<Map<String, dynamic>> delete(String endpoint, int id) async {
    return await _handleRequest(
      http.delete(
        Uri.parse("$baseUrl/$endpoint/$id/delete"),
        headers: headers,
      ),
    );
  }

  // ======================
  // PEMINJAMAN
  // ======================
  static Future<Map<String, dynamic>> getMyPeminjaman() async {
    return await _handleRequest(
      http.get(
        Uri.parse("$baseUrl/peminjaman/me"),
        headers: headers,
      ),
    );
  }

  static Future<Map<String, dynamic>> getActivePeminjaman() async {
    return await _handleRequest(
      http.get(
        Uri.parse("$baseUrl/peminjaman/active"),
        headers: headers,
      ),
    );
  }

  static Future<Map<String, dynamic>> createPeminjaman(
    Map<String, dynamic> body,
  ) async {
    return await _handleRequest(
      http.post(
        Uri.parse("$baseUrl/peminjaman"),
        headers: headers,
        body: jsonEncode(body),
      ),
    );
  }

  static Future<Map<String, dynamic>> returnProduct(int id) async {
    return await _handleRequest(
      http.post(
        Uri.parse("$baseUrl/peminjaman/$id/return"),
        headers: headers,
      ),
    );
  }

  static Future<Map<String, dynamic>> checkPin(String pin) async {
    return await _handleRequest(
      http.post(
        Uri.parse("$baseUrl/peminjaman/check-pin"),
        headers: headers,
        body: jsonEncode({"pin": pin}),
      ),
    );
  }

  // ======================
  // NEW ADDITIONAL METHODS
  // ======================

  // Check connection to server
  static Future<bool> checkConnection() async {
    try {
      final response = await http
          .get(
            Uri.parse("$baseUrl"),
          )
          .timeout(Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Get user profile with detailed information
  static Future<Map<String, dynamic>> getProfile() async {
    return await _handleRequest(
      http.get(
        Uri.parse("$baseUrl/profile"),
        headers: headers,
      ),
    );
  }

  // Change password
  static Future<Map<String, dynamic>> changePassword(
    String currentPassword,
    String newPassword,
    String newPasswordConfirmation,
  ) async {
    return await _handleRequest(
      http.post(
        Uri.parse("$baseUrl/change-password"),
        headers: headers,
        body: jsonEncode({
          "current_password": currentPassword,
          "new_password": newPassword,
          "new_password_confirmation": newPasswordConfirmation,
        }),
      ),
    );
  }

  // Upload profile picture
  static Future<Map<String, dynamic>> uploadProfilePicture(
    List<int> imageBytes,
    String fileName,
  ) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse("$baseUrl/upload-profile-picture"),
    );

    request.headers.addAll(headers);
    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: fileName,
      ),
    );

    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    return json.decode(responseData);
  }

  // Get available products for borrowing
  static Future<Map<String, dynamic>> getAvailableProducts() async {
    return await _handleRequest(
      http.get(
        Uri.parse("$baseUrl/products/available"),
        headers: headers,
      ),
    );
  }

  // Get borrowing history
  static Future<Map<String, dynamic>> getBorrowingHistory() async {
    return await _handleRequest(
      http.get(
        Uri.parse("$baseUrl/peminjaman/history"),
        headers: headers,
      ),
    );
  }

  // Get notifications
  static Future<Map<String, dynamic>> getNotifications() async {
    return await _handleRequest(
      http.get(
        Uri.parse("$baseUrl/notifications"),
        headers: headers,
      ),
    );
  }

  // Mark notification as read
  static Future<Map<String, dynamic>> markNotificationAsRead(int id) async {
    return await _handleRequest(
      http.post(
        Uri.parse("$baseUrl/notifications/$id/read"),
        headers: headers,
      ),
    );
  }

  // Get statistics (for dashboard)
  static Future<Map<String, dynamic>> getStatistics() async {
    return await _handleRequest(
      http.get(
        Uri.parse("$baseUrl/statistics"),
        headers: headers,
      ),
    );
  }

  // Search products
  static Future<Map<String, dynamic>> searchProducts(String query) async {
    return await _handleRequest(
      http.get(
        Uri.parse("$baseUrl/products/search?q=$query"),
        headers: headers,
      ),
    );
  }

  // Get categories
  static Future<Map<String, dynamic>> getCategories() async {
    return await _handleRequest(
      http.get(
        Uri.parse("$baseUrl/categories"),
        headers: headers,
      ),
    );
  }

  // ======================
  // TOKEN MANAGEMENT
  // ======================

  static String? getToken() {
    return token;
  }

  static void setToken(String newToken) {
    token = newToken;
  }

  static void clearToken() {
    token = null;
  }

  static bool get isLoggedIn => token != null;
}

// Custom Exception Class
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? responseData;

  ApiException(this.message, {this.statusCode, this.responseData});

  @override
  String toString() {
    return 'ApiException: $message${statusCode != null ? ' ($statusCode)' : ''}';
  }
}
