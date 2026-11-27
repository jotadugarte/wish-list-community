import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:wish_list_mobile/core/network/token_storage.dart';

class RecordedApiRequest {
  final String method;
  final String path;
  final Map<String, String> headers;
  final Map<String, dynamic>? queryParams;
  final Map<String, dynamic>? body;

  const RecordedApiRequest({
    required this.method,
    required this.path,
    required this.headers,
    this.queryParams,
    this.body,
  });
}

class ApiResponse {
  final int statusCode;
  final Map<String, dynamic> body;

  const ApiResponse({required this.statusCode, required this.body});

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException({required this.statusCode, required this.message});

  // statusCode 0 means the request never reached the server (timeout / no network).
  bool get isNetworkError => statusCode == 0;
  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

typedef ApiTransport = Future<ApiResponse> Function(RecordedApiRequest request);

// HTTP client for /api/v1 attaching Bearer tokens, enforcing bounded request time,
// mapping 401/404/409/422 errors, and clearing the session on expired tokens.
// Traceability: [REQ-ARCH-001], [REQ-AUTH-001], [REQ-ARCH-003], [REQ-BLOCK-001]
class ApiClient {
  static const Duration defaultRequestTimeout = Duration(seconds: 15);
  static const Duration connectTimeout = Duration(seconds: 10);

  final String baseUrl;
  final TokenStorage tokenStorage;
  final Duration requestTimeout;
  final ApiTransport _transport;

  // Invoked after a 401 on an authenticated request, once the local token is cleared.
  void Function()? onUnauthorized;

  ApiClient({
    required this.baseUrl,
    required this.tokenStorage,
    this.requestTimeout = defaultRequestTimeout,
    ApiTransport? transport,
  }) : _transport = transport ?? _defaultHttpTransport(baseUrl);

  // [REQ-AUTH-001] Executes an API v1 request with optional Bearer token authentication.
  Future<ApiResponse> request({
    required String method,
    required String path,
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    if (!path.startsWith('/api/v1/')) {
      throw ArgumentError(
        'Pre-condition failed: path must start with /api/v1/',
      );
    }

    final req = RecordedApiRequest(
      method: method.toUpperCase(),
      path: path,
      headers: await _buildHeaders(authenticated),
      queryParams: queryParams,
      body: body,
    );

    final response = await _send(req);
    if (response.statusCode == 401 && authenticated) {
      await tokenStorage.clearToken();
      onUnauthorized?.call();
    }
    if (!response.isSuccess) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _errorMessageFromBody(response.body),
      );
    }
    return response;
  }

  Future<Map<String, String>> _buildHeaders(bool authenticated) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (authenticated) {
      final token = await tokenStorage.readToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // [REQ-ARCH-001] Bounded execution: every request ends within requestTimeout.
  Future<ApiResponse> _send(RecordedApiRequest req) async {
    try {
      return await _transport(req).timeout(requestTimeout);
    } on TimeoutException {
      throw const ApiException(statusCode: 0, message: 'Request timed out');
    } on SocketException catch (e) {
      throw ApiException(statusCode: 0, message: e.message);
    }
  }

  static ApiTransport _defaultHttpTransport(String baseUrl) {
    return (RecordedApiRequest req) async {
      final client = HttpClient()..connectionTimeout = connectTimeout;
      try {
        final uri = Uri.parse('$baseUrl${req.path}').replace(
          queryParameters: req.queryParams?.map(
            (k, v) => MapEntry(k, v.toString()),
          ),
        );
        final httpReq = await client.openUrl(req.method, uri);
        req.headers.forEach(httpReq.headers.set);
        if (req.body != null) {
          httpReq.write(jsonEncode(req.body));
        }
        final httpRes = await httpReq.close();
        final rawText = await httpRes.transform(utf8.decoder).join();
        return ApiResponse(
          statusCode: httpRes.statusCode,
          body: _decodeBody(rawText),
        );
      } finally {
        client.close(force: true);
      }
    };
  }

  // Tolerates empty or non-JSON bodies (e.g. HTML 502 pages from a proxy).
  static Map<String, dynamic> _decodeBody(String raw) {
    if (raw.trim().isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } on FormatException {
      return <String, dynamic>{};
    }
  }

  // Prefers singular `error`, then first entry of `errors` (API 4xx shapes).
  static String _errorMessageFromBody(Map<String, dynamic> body) {
    final single = body['error'];
    if (single != null && single.toString().isNotEmpty) {
      return single.toString();
    }
    final list = body['errors'];
    if (list is List && list.isNotEmpty) {
      return list.first.toString();
    }
    return 'Request failed';
  }
}
