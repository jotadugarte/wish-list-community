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

  @override
  String toString() => 'ApiException($statusCode): $message';
}

typedef ApiTransport = Future<ApiResponse> Function(RecordedApiRequest request);

// HTTP client for /api/v1 attaching Bearer tokens and mapping 401/404/409/422 errors.
// Traceability: [REQ-ARCH-001], [REQ-AUTH-001], [REQ-ARCH-003], [REQ-BLOCK-001]
class ApiClient {
  final String baseUrl;
  final TokenStorage tokenStorage;
  final ApiTransport _transport;

  ApiClient({
    required this.baseUrl,
    required this.tokenStorage,
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
      throw ArgumentError('Pre-condition failed: path must start with /api/v1/');
    }

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

    final req = RecordedApiRequest(
      method: method.toUpperCase(),
      path: path,
      headers: headers,
      queryParams: queryParams,
      body: body,
    );

    final response = await _transport(req);
    if (!response.isSuccess) {
      final errMsg = (response.body['error'] ?? 'Request failed').toString();
      throw ApiException(statusCode: response.statusCode, message: errMsg);
    }
    return response;
  }

  static ApiTransport _defaultHttpTransport(String baseUrl) {
    return (RecordedApiRequest req) async {
      final client = HttpClient();
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
        final decoded = rawText.trim().isEmpty
            ? <String, dynamic>{}
            : (jsonDecode(rawText) as Map<String, dynamic>);
        return ApiResponse(statusCode: httpRes.statusCode, body: decoded);
      } finally {
        client.close();
      }
    };
  }
}
