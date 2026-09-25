import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  Future<dynamic> get(String endpoint, {Map<String, String>? headers}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers ?? {'Content-Type': 'application/json'},
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('GET request failed: $e');
    }
  }

  Future<dynamic> post(String endpoint, {dynamic body, Map<String, String>? headers}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers ?? {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      if (e is Exception && e.toString().startsWith('Exception: ')) rethrow;
      throw Exception('POST request failed: $e');
    }
  }

  Future<dynamic> put(String endpoint, {dynamic body, Map<String, String>? headers}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers ?? {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      if (e is Exception && e.toString().startsWith('Exception: ')) rethrow;
      throw Exception('PUT request failed: $e');
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      var message = 'Request failed (${response.statusCode}).';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['message'] is String) {
          message = decoded['message'] as String;
        }
      } catch (_) {
        // Keep the status-based message when the response is not JSON.
      }
      throw Exception(message);
    }
  }
}
