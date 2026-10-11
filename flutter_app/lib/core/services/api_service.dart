import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5000/api',
  );

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (authenticated) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw StateError('Please sign in before using this feature.');
      }
      final token = await user.getIdToken();
      if (token == null || token.isEmpty) {
        throw StateError('Your session expired. Please sign in again.');
      }
      headers['Authorization'] = 'Bearer $token';
    }

    final uri = Uri.parse('$baseUrl$path');
    final response = switch (method) {
      'GET' => await http.get(uri, headers: headers),
      _ => await http.post(
          uri,
          headers: headers,
          body: jsonEncode(body ?? const <String, dynamic>{}),
        ),
    };

    final decoded = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map
          ? decoded['error']?.toString() ?? decoded['message']?.toString()
          : null;
      throw Exception(message ?? 'Request failed (${response.statusCode}).');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Unexpected response from the security service.');
    }
    return decoded;
  }

  Future<Map<String, dynamic>> scanEmail(String content) =>
      _request('POST', '/scan/email', body: {'content': content});

  Future<Map<String, dynamic>> scanUrl(String url) =>
      _request('POST', '/scan/url', body: {'url': url});

  Future<Map<String, dynamic>> checkBreach(String identifier) =>
      _request('POST', '/breach/check', body: {'identifier': identifier});

  Future<Map<String, dynamic>> getCyberScore() => _request('POST', '/score');

  Future<Map<String, dynamic>> sendChatMessage(String message) =>
      _request('POST', '/chat', body: {'message': message});

  Future<Map<String, dynamic>> getAdminMetrics() =>
      _request('GET', '/admin/metrics');

  Future<List<Map<String, dynamic>>> getAdminUsers() async {
    final data = await _request('GET', '/admin/users');
    final users = (data['users'] ?? []) as List<dynamic>;
    return users
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
