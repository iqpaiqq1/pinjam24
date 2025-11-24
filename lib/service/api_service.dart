import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // UBAH INI SESUAI BACKEND ANDA
  // Jika backend di localhost:8888 gunakan ini
  static String baseUrl = "http://172.22.128.1:8888/api";

  static String? _token;

  static set token(String? token) {
    _token = token;
    print('✅ Token set: ${token?.substring(0, 20)}...');
  }

  static String? get token => _token;

  static Map<String, String> get _headers {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
      print('🔐 Request dengan token: ${_token!.substring(0, 20)}...');
    } else {
      print('⚠️ Request tanpa token');
    }
    return headers;
  }

  // ============ AUTH CONTROLLER ============

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final url = '$baseUrl/register';
      print('DEBUG: Calling API: $url');
      print('DEBUG: Body: ${jsonEncode({
            'name': name,
            'email': email,
            'password': password
          })}');

      final response = await http
          .post(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout - Backend tidak merespon');
        },
      );

      print('DEBUG: Status Code: ${response.statusCode}');
      print('DEBUG: Response Body: ${response.body}');

      if (response.body.isEmpty) {
        return {
          'success': false,
          'message': 'Server mengembalikan response kosong'
        };
      }

      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        return {
          'success': false,
          'message': 'Format response tidak valid: ${response.body}'
        };
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'Registrasi berhasil',
          'user': data['user'] ?? data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? data['error'] ?? 'Registrasi gagal',
        };
      }
    } catch (e) {
      print('DEBUG: Exception: $e');
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final url = '$baseUrl/login';
      print('DEBUG: Calling API: $url');

      final response = await http
          .post(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode({'email': email, 'password': password}),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout - Backend tidak merespon');
        },
      );

      print('DEBUG: Status Code: ${response.statusCode}');
      print('DEBUG: Response Body: ${response.body}');

      if (response.body.isEmpty) {
        return {
          'success': false,
          'message': 'Server mengembalikan response kosong'
        };
      }

      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        return {
          'success': false,
          'message': 'Format response tidak valid: ${response.body}'
        };
      }

      if (response.statusCode == 200) {
        // SIMPAN TOKEN
        if (data['token'] != null) {
          _token = data['token'];
          print('✅ Token berhasil disimpan: ${_token!.substring(0, 20)}...');
        }

        return {
          'success': true,
          'message': data['message'] ?? 'Login berhasil',
          'user': data['user'] ?? data['data'],
          'token': data['token'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? data['error'] ?? 'Login gagal',
        };
      }
    } catch (e) {
      print('DEBUG: Exception: $e');
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> logout() async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/logout'),
        headers: _headers,
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _token = null;
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Logout gagal'};
      }
    } catch (e) {
      _token = null; // Tetap hapus token meskipun error
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // ============ ADMIN CONTROLLER ============

  static Future<Map<String, dynamic>> getAdminProfile() async {
    try {
      print('🔍 Getting admin profile...');
      final response = await http
          .get(
        Uri.parse('$baseUrl/admin'),
        headers: _headers,
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengambil profil admin',
        };
      }
    } catch (e) {
      print('❌ Error: $e');
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateAdminProfile({
    String? name,
    String? email,
    String? password,
    String? phone,
  }) async {
    try {
      Map<String, dynamic> body = {};
      if (name != null) body['name'] = name;
      if (email != null) body['email'] = email;
      if (password != null) body['password'] = password;
      if (phone != null) body['phone'] = phone;

      final response = await http
          .put(
        Uri.parse('$baseUrl/admin/update'),
        headers: _headers,
        body: jsonEncode(body),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal update profil admin',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> getUserDetail(int userId) async {
    try {
      final response = await http
          .get(
        Uri.parse('$baseUrl/user/$userId/detail'),
        headers: _headers,
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengambil detail user',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // ============ USER CONTROLLER ============

  static Future<Map<String, dynamic>> getAllUsers() async {
    try {
      final response = await http
          .get(
        Uri.parse('$baseUrl/user'),
        headers: _headers,
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'users': data['user'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengambil data user',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> getUserById(int id) async {
    try {
      final response = await http
          .get(
        Uri.parse('$baseUrl/user/$id'),
        headers: _headers,
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'user': data['user'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengambil user',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> createUser({
    required String name,
    required String email,
    required String password,
    required int roleId,
  }) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/user/create-user'),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role_id': roleId,
        }),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'user': data['user'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal membuat user',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateUser({
    required int id,
    String? name,
    String? email,
    String? password,
    int? roleId,
  }) async {
    try {
      Map<String, dynamic> body = {};
      if (name != null) body['name'] = name;
      if (email != null) body['email'] = email;
      if (password != null) body['password'] = password;
      if (roleId != null) body['role_id'] = roleId;

      final response = await http
          .put(
        Uri.parse('$baseUrl/user/$id/update'),
        headers: _headers,
        body: jsonEncode(body),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'user': data['user'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal update user',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteUser(int id) async {
    try {
      final response = await http
          .delete(
        Uri.parse('$baseUrl/user/$id/delete'),
        headers: _headers,
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal menghapus user',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // ============ USER DETAIL (ME) CONTROLLER ============

  static Future<Map<String, dynamic>> getUserDetailProfile() async {
    try {
      print('🔍 Getting user profile...');
      final response = await http
          .get(
        Uri.parse('$baseUrl/me'),
        headers: _headers,
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengambil profil user',
        };
      }
    } catch (e) {
      print('❌ Error: $e');
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateUserDetailProfile({
    String? name,
    String? email,
    String? password,
    String? identityNumber,
    String? phone,
    int? statusId,
    int? classId,
    int? majorId,
  }) async {
    try {
      Map<String, dynamic> body = {};
      if (name != null) body['name'] = name;
      if (email != null) body['email'] = email;
      if (password != null) body['password'] = password;
      if (identityNumber != null) body['identity_number'] = identityNumber;
      if (phone != null) body['phone'] = phone;
      if (statusId != null) body['status_id'] = statusId;
      if (classId != null) body['class_id'] = classId;
      if (majorId != null) body['major_id'] = majorId;

      final response = await http
          .put(
        Uri.parse('$baseUrl/me/update'),
        headers: _headers,
        body: jsonEncode(body),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal update profil user',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // ============ CATEGORY CONTROLLER ============

  static Future<Map<String, dynamic>> getCategories() async {
    try {
      print('🔍 Getting categories...');
      final response = await http
          .get(
        Uri.parse('$baseUrl/categories'),
        headers: _headers,
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      print('Status: ${response.statusCode}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'message': 'Gagal mengambil kategori'};
      }
    } catch (e) {
      print('❌ Error: $e');
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> createCategory(
      String categoryName) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/categories/create'),
        headers: _headers,
        body: jsonEncode({'category_name': categoryName}),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Gagal membuat kategori',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> getCategoryById(int id) async {
    try {
      final response = await http
          .get(
        Uri.parse('$baseUrl/categories/$id'),
        headers: _headers,
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Gagal mengambil kategori',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateCategory(
      int id, String categoryName) async {
    try {
      final response = await http
          .put(
        Uri.parse('$baseUrl/categories/$id/update'),
        headers: _headers,
        body: jsonEncode({'category_name': categoryName}),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Gagal update kategori',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteCategory(int id) async {
    try {
      final response = await http
          .delete(
        Uri.parse('$baseUrl/categories/$id/delete'),
        headers: _headers,
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Kategori berhasil dihapus'};
      } else {
        return {'success': false, 'message': 'Gagal menghapus kategori'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // ============ CLASS CONTROLLER ============

  static Future<Map<String, dynamic>> getClasses() async {
    try {
      print('🔍 Getting classes...');
      final response = await http
          .get(
        Uri.parse('$baseUrl/class'),
        headers: _headers,
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      print('Status: ${response.statusCode}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'message': 'Gagal mengambil kelas'};
      }
    } catch (e) {
      print('❌ Error: $e');
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> createClass(String className) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/class/create'),
        headers: _headers,
        body: jsonEncode({'class_name': className}),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Gagal membuat kelas',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> getClassById(int id) async {
    try {
      final response = await http
          .get(
        Uri.parse('$baseUrl/class/$id'),
        headers: _headers,
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Gagal mengambil kelas',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateClass(
      int id, String className) async {
    try {
      final response = await http
          .put(
        Uri.parse('$baseUrl/class/$id/update'),
        headers: _headers,
        body: jsonEncode({'class_name': className}),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Gagal update kelas',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteClass(int id) async {
    try {
      final response = await http
          .delete(
        Uri.parse('$baseUrl/class/$id/delete'),
        headers: _headers,
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Kelas berhasil dihapus'};
      } else {
        return {'success': false, 'message': 'Gagal menghapus kelas'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // ============ LOCATION CONTROLLER ============

  static Future<Map<String, dynamic>> getLocations() async {
    try {
      print('🔍 Getting locations...');
      final response = await http
          .get(
        Uri.parse('$baseUrl/location/'),
        headers: _headers,
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      print('Status: ${response.statusCode}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'message': 'Gagal mengambil lokasi'};
      }
    } catch (e) {
      print('❌ Error: $e');
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> createLocation(
      String locationName) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/location/create'),
        headers: _headers,
        body: jsonEncode({'location_name': locationName}),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Gagal membuat lokasi',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> getLocationById(int id) async {
    try {
      final response = await http
          .get(
        Uri.parse('$baseUrl/location/$id'),
        headers: _headers,
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Gagal mengambil lokasi',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateLocation(
      int id, String locationName) async {
    try {
      final response = await http
          .put(
        Uri.parse('$baseUrl/location/$id/update'),
        headers: _headers,
        body: jsonEncode({'location_name': locationName}),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Gagal update lokasi',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteLocation(int id) async {
    try {
      final response = await http
          .delete(
        Uri.parse('$baseUrl/location/$id/delete'),
        headers: _headers,
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Lokasi berhasil dihapus'};
      } else {
        return {'success': false, 'message': 'Gagal menghapus lokasi'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // ============ MAJOR CONTROLLER ============

  static Future<Map<String, dynamic>> getMajors() async {
    try {
      print('🔍 Getting majors...');
      final response = await http
          .get(
        Uri.parse('$baseUrl/major'),
        headers: _headers,
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      print('Status: ${response.statusCode}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'message': 'Gagal mengambil jurusan'};
      }
    } catch (e) {
      print('❌ Error: $e');
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> createMajor(String majorName) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/major/create'),
        headers: _headers,
        body: jsonEncode({'major_name': majorName}),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Gagal membuat jurusan',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> getMajorById(int id) async {
    try {
      final response = await http
          .get(
        Uri.parse('$baseUrl/major/$id'),
        headers: _headers,
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Gagal mengambil jurusan',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateMajor(
      int id, String majorName) async {
    try {
      final response = await http
          .put(
        Uri.parse('$baseUrl/major/$id/update'),
        headers: _headers,
        body: jsonEncode({'major_name': majorName}),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Gagal update jurusan',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteMajor(int id) async {
    try {
      final response = await http
          .delete(
        Uri.parse('$baseUrl/major/$id/delete'),
        headers: _headers,
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Jurusan berhasil dihapus'};
      } else {
        return {'success': false, 'message': 'Gagal menghapus jurusan'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // ============ ROLE CONTROLLER ============

  static Future<Map<String, dynamic>> getRoles() async {
    try {
      print('🔍 Getting roles...');
      final response = await http
          .get(
        Uri.parse('$baseUrl/role'),
        headers: _headers,
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      print('Status: ${response.statusCode}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'message': 'Gagal mengambil role'};
      }
    } catch (e) {
      print('❌ Error: $e');
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> createRole(String roleName) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/role/create'),
        headers: _headers,
        body: jsonEncode({'role_name': roleName}),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Gagal membuat role',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> getRoleById(int id) async {
    try {
      final response = await http
          .get(
        Uri.parse('$baseUrl/role/$id'),
        headers: _headers,
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Gagal mengambil role',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateRole(
      int id, String roleName) async {
    try {
      final response = await http
          .put(
        Uri.parse('$baseUrl/role/$id/update'),
        headers: _headers,
        body: jsonEncode({'role_name': roleName}),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Gagal update role',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteRole(int id) async {
    try {
      final response = await http
          .delete(
        Uri.parse('$baseUrl/role/$id/delete'),
        headers: _headers,
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Role berhasil dihapus'};
      } else {
        return {'success': false, 'message': 'Gagal menghapus role'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // ============ STATUS CONTROLLER ============

  static Future<Map<String, dynamic>> getStatuses() async {
    try {
      print('🔍 Getting statuses...');
      final response = await http
          .get(
        Uri.parse('$baseUrl/status'),
        headers: _headers,
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      print('Status: ${response.statusCode}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'message': 'Gagal mengambil status'};
      }
    } catch (e) {
      print('❌ Error: $e');
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> createStatus(String statusName) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/status/create'),
        headers: _headers,
        body: jsonEncode({'status_name': statusName}),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Gagal membuat status',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> getStatusById(int id) async {
    try {
      final response = await http
          .get(
        Uri.parse('$baseUrl/status/$id'),
        headers: _headers,
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Gagal mengambil status',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateStatus(
      int id, String statusName) async {
    try {
      final response = await http
          .put(
        Uri.parse('$baseUrl/status/$id/update'),
        headers: _headers,
        body: jsonEncode({'status_name': statusName}),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Gagal update status',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteStatus(int id) async {
    try {
      final response = await http
          .delete(
        Uri.parse('$baseUrl/status/$id/delete'),
        headers: _headers,
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Status berhasil dihapus'};
      } else {
        return {'success': false, 'message': 'Gagal menghapus status'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // ============ PRODUCT CONTROLLER ============

  static Future<Map<String, dynamic>> getProducts() async {
    try {
      print('🔍 Getting products...');
      print('URL: $baseUrl/product/');
      print('Headers: $_headers');

      final response = await http
          .get(
        Uri.parse('$baseUrl/product/'),
        headers: _headers,
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout - Backend tidak merespon');
        },
      );

      print('✅ Status: ${response.statusCode}');
      print('📦 Body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengambil produk'
        };
      }
    } catch (e) {
      print('❌ Error getting products: $e');
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> getProductById(int id) async {
    try {
      final response = await http
          .get(
        Uri.parse('$baseUrl/product/$id'),
        headers: _headers,
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Gagal mengambil produk',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> createProduct(
    Map<String, dynamic> productData,
  ) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/product/create'),
        headers: _headers,
        body: jsonEncode(productData),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Gagal membuat produk',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateProduct(
    int id,
    Map<String, dynamic> productData,
  ) async {
    try {
      final response = await http
          .put(
        Uri.parse('$baseUrl/product/$id/update'),
        headers: _headers,
        body: jsonEncode(productData),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Gagal update produk',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteProduct(int id) async {
    try {
      final response = await http
          .delete(
        Uri.parse('$baseUrl/product/$id/delete'),
        headers: _headers,
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Gagal menghapus produk',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // ============ PEMINJAMAN CONTROLLER ============

  static Future<Map<String, dynamic>> getAllPeminjaman({
    String? search,
    int? productId,
    int? locationId,
    String? status,
    String? startDate,
    String? endDate,
  }) async {
    try {
      var url = '$baseUrl/peminjaman/';
      var params = <String>[];

      if (search != null) params.add('search=$search');
      if (productId != null) params.add('product_id=$productId');
      if (locationId != null) params.add('location_id=$locationId');
      if (status != null) params.add('status=$status');
      if (startDate != null) params.add('start_date=$startDate');
      if (endDate != null) params.add('end_date=$endDate');

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final response = await http
          .get(
        Uri.parse(url),
        headers: _headers,
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {'success': false, 'message': 'Gagal mengambil data peminjaman'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> getMyPeminjaman() async {
    try {
      print('🔍 Getting my peminjaman...');
      final response = await http
          .get(
        Uri.parse('$baseUrl/peminjaman/me'),
        headers: _headers,
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': 'Gagal mengambil history peminjaman',
        };
      }
    } catch (e) {
      print('❌ Error: $e');
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> getActivePeminjaman() async {
    try {
      final response = await http
          .get(
        Uri.parse('$baseUrl/peminjaman/active'),
        headers: _headers,
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': 'Gagal mengambil peminjaman aktif',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> createPeminjaman({
    required int productId,
    required int locationId,
    required String startDate,
    required String endDate,
    required String pinCode,
    required int qty,
    String? note,
    int? idPinjam,
    String? overridePin,
  }) async {
    try {
      Map<String, dynamic> body = {
        'product_id': productId,
        'location_id': locationId,
        'start_date': startDate,
        'end_date': endDate,
        'pin_code': pinCode,
        'qty': qty,
      };

      if (note != null) body['note'] = note;
      if (idPinjam != null) body['id_pinjam'] = idPinjam;
      if (overridePin != null) body['override_pin'] = overridePin;

      print('🔍 Creating peminjaman...');
      print('Body: ${jsonEncode(body)}');

      final response = await http
          .post(
        Uri.parse('$baseUrl/peminjaman/create'),
        headers: _headers,
        body: jsonEncode(body),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      print('Status: ${response.statusCode}');
      print('Response: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal membuat peminjaman',
        };
      }
    } catch (e) {
      print('❌ Error: $e');
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> returnPeminjaman(
    int id,
    String pinCode,
  ) async {
    try {
      final response = await http
          .put(
        Uri.parse('$baseUrl/peminjaman/$id/return'),
        headers: _headers,
        body: jsonEncode({'pin_code': pinCode}),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengembalikan peminjaman',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> getProductBorrowedInfo(
      int productId) async {
    try {
      print('📊 Getting borrowed info for product $productId...');
      final response = await http
          .get(
        Uri.parse('$baseUrl/product/$productId/borrowed-info'),
        headers: _headers,
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengambil info borrowed',
        };
      }
    } catch (e) {
      print('❌ Error: $e');
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// WORKAROUND: Get borrowed info dari peminjaman aktif
  /// Digunakan jika backend belum punya endpoint borrowed-info
  static Future<Map<String, dynamic>> getProductBorrowedInfoWorkaround(
      int productId) async {
    try {
      print('📊 Getting borrowed info (workaround) for product $productId...');

      // Get all active peminjaman
      final response = await getActivePeminjaman();

      if (response['success'] != true) {
        return {
          'success': false,
          'message': 'Gagal mengambil data peminjaman aktif',
        };
      }

      final List<dynamic> loans = response['data'] ?? [];

      // Filter by product_id dan sum qty
      int totalBorrowed = 0;
      for (var loan in loans) {
        final loanProductId = loan['product_id'] ?? loan['product']?['id'];
        final status = loan['status']?.toString().toLowerCase();

        if (loanProductId == productId && status == 'dipinjam') {
          totalBorrowed += (loan['qty'] ?? 0) as int;
        }
      }

      return {
        'success': true,
        'data': {
          'product_id': productId,
          'total_borrowed': totalBorrowed,
        },
      };
    } catch (e) {
      print('❌ Error: $e');
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }
}
