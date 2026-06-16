import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants.dart';

/// Thrown for any non-2xx backend response. Carries the backend's
/// `{ message, errorCode }` so the UI can show a meaningful message.
class ApiException implements Exception {
  ApiException(this.message, {this.code, this.statusCode});
  final String message;
  final String? code;
  final int? statusCode;
  @override
  String toString() => message;
}

/// Thin REST client for the ParkFlow backend. Attaches the bearer token,
/// decodes JSON, and maps errors to [ApiException].
class ApiClient {
  ApiClient({String? baseUrl, this.token})
      : baseUrl = baseUrl ?? PFConstants.apiBaseUrl;

  final String baseUrl;
  String? token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
      };

  Future<dynamic> get(String path) => _send('GET', path);
  Future<dynamic> post(String path, Map<String, dynamic> body) =>
      _send('POST', path, body);
  Future<dynamic> put(String path, Map<String, dynamic> body) =>
      _send('PUT', path, body);
  Future<dynamic> patch(String path, [Map<String, dynamic> body = const {}]) =>
      _send('PATCH', path, body);
  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> _send(String method, String path,
      [Map<String, dynamic>? body]) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.Request(method, uri)..headers.addAll(_headers);
    if (body != null) request.body = jsonEncode(body);

    final http.Response res;
    try {
      final streamed =
          await request.send().timeout(const Duration(seconds: 20));
      res = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw ApiException('Request timed out', code: 'TIMEOUT');
    } catch (e) {
      throw ApiException('Network error: $e', code: 'NETWORK');
    }

    final dynamic decoded =
        res.body.isEmpty ? null : _tryDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) return decoded;

    final message = decoded is Map && decoded['message'] != null
        ? decoded['message'].toString()
        : 'Request failed (${res.statusCode})';
    final code = decoded is Map ? decoded['errorCode'] as String? : null;
    throw ApiException(message, code: code, statusCode: res.statusCode);
  }

  dynamic _tryDecode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }
}
