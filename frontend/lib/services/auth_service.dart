import '../config/api_config.dart';
import '../utils/api_endpoints.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';

class AuthService {
  AuthService({ApiService? apiService})
    : _apiService = apiService ?? ApiService(baseUrl: ApiConfig.baseUrl);

  final ApiService _apiService;
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final result = await _apiService.post(
      ApiEndpoints.register,
      body: {'name': name, 'email': email, 'password': password},
    );
    if (result is! Map<String, dynamic>) {
      throw Exception('The server returned an invalid registration response.');
    }
    return result;
  }

  Future<Map<String, dynamic>> login({required String email, required String password}) async {
    final result = await _apiService.post(
      ApiEndpoints.login,
      body: {'email': email, 'password': password},
    );
    if (result is! Map<String, dynamic> || result['token'] is! String || result['user'] is! Map<String, dynamic>) {
      throw Exception('The server returned an invalid login response.');
    }
    await _storage.write(key: _tokenKey, value: result['token'] as String);
    return result;
  }

  Future<Map<String, dynamic>> updateRole(String role) async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null || token.isEmpty) throw Exception('Please log in again.');
    final result = await _apiService.put(
      ApiEndpoints.updateRole,
      body: {'role': role},
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );
    if (result is! Map<String, dynamic> || result['user'] is! Map<String, dynamic> || result['token'] is! String) {
      throw Exception('The server returned an invalid role response.');
    }
    await _storage.write(key: _tokenKey, value: result['token'] as String);
    return result;
  }

  Future<void> logout() => _storage.delete(key: _tokenKey);
}
