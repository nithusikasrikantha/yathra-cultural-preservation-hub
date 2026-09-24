import '../config/api_config.dart';
import '../utils/api_endpoints.dart';
import 'api_service.dart';

class AuthService {
  AuthService({ApiService? apiService})
    : _apiService = apiService ?? ApiService(baseUrl: ApiConfig.baseUrl);

  final ApiService _apiService;

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
}
