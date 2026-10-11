import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/api_config.dart';
import '../models/connection_model.dart';
import '../models/user_model.dart';
import '../utils/api_endpoints.dart';
import 'api_service.dart';

class CultureConnectService {
  CultureConnectService({ApiService? api})
    : _api = api ?? ApiService(baseUrl: ApiConfig.baseUrl);
  final ApiService _api;
  static const _storage = FlutterSecureStorage();

  Future<Map<String, String>> get _headers async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null || token.isEmpty) throw Exception('Please log in again.');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<String?> get currentUserId => _storage.read(key: 'auth_user_id');

  Future<List<User>> getElders() async {
    final response = await _api.get(
      ApiEndpoints.connectionElders,
      headers: await _headers,
    );
    return ((response['items'] as List?) ?? [])
        .map((item) => User.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<List<Connection>> getConnections() async {
    final response = await _api.get(
      ApiEndpoints.connections,
      headers: await _headers,
    );
    return ((response['items'] as List?) ?? [])
        .map(
          (item) => Connection.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> getNotifications() async {
    final response = await _api.get(
      ApiEndpoints.connectionNotifications,
      headers: await _headers,
    );
    return ((response['items'] as List?) ?? [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Connection> request(
    String elderId,
    String communityId,
    String communityName,
  ) async {
    final response = await _api.post(
      ApiEndpoints.connections,
      headers: await _headers,
      body: {
        'elderId': elderId,
        'communityId': communityId,
        'communityName': communityName,
      },
    );
    return Connection.fromJson(
      Map<String, dynamic>.from(response['connection'] as Map),
    );
  }

  Future<void> respond(String id, String status) async {
    await _api.put(
      '${ApiEndpoints.connections}/$id/status',
      headers: await _headers,
      body: {'status': status},
    );
  }

  Future<List<Map<String, dynamic>>> getMessages(String id) async {
    final response = await _api.get(
      '${ApiEndpoints.connections}/$id/messages',
      headers: await _headers,
    );
    return ((response['items'] as List?) ?? [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> sendMessage(String id, String text) async {
    final response = await _api.post(
      '${ApiEndpoints.connections}/$id/messages',
      headers: await _headers,
      body: {'text': text},
    );
    return Map<String, dynamic>.from(response['message'] as Map);
  }

  Future<Map<String, dynamic>> getWorkspace(String id) async =>
      Map<String, dynamic>.from(
        await _api.get(
          '${ApiEndpoints.connections}/$id/workspace',
          headers: await _headers,
        ),
      );

  Future<Map<String, dynamic>> saveWorkspace(
    String id, {
    required String title,
    required String content,
    required String instructions,
  }) async => Map<String, dynamic>.from(
    await _api.put(
      '${ApiEndpoints.connections}/$id/workspace',
      headers: await _headers,
      body: {'title': title, 'content': content, 'instructions': instructions},
    ),
  );

  Future<Map<String, dynamic>> publish(String id) async =>
      Map<String, dynamic>.from(
        await _api.post(
          '${ApiEndpoints.connections}/$id/publish',
          headers: await _headers,
          body: {},
        ),
      );
}
