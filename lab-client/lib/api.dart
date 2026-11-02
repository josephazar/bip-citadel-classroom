import 'dart:convert';
import 'package:http/http.dart' as http;
import 'platform.dart';

class LabResponse {
  const LabResponse(this.status, this.data);
  final int status;
  final Map<String, dynamic> data;
}

class LabApi {
  LabApi(this.endpoint, this.client);
  final Uri endpoint;
  final http.Client client;
  String? token;
  static Future<LabApi> create() async {
    final value = const String.fromEnvironment('API_URL');
    final endpoint = Uri.parse(value.isEmpty ? defaultApi : value);
    return LabApi(endpoint, await buildClient(endpoint));
  }

  Future<LabResponse> request(
    String path, {
    Map<String, String> headers = const {},
    Map<String, Object>? body,
  }) async {
    final relative = Uri.parse(path);
    if (relative.hasScheme ||
        relative.hasAuthority ||
        !path.startsWith('/') ||
        path.startsWith('//')) {
      throw ArgumentError('Use a path on this classroom API.');
    }
    final uri = endpoint.resolveUri(relative);
    final h = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      ...headers,
    };
    final response =
        await (body == null
                ? client.get(uri, headers: h)
                : client.post(uri, headers: h, body: jsonEncode(body)))
            .timeout(const Duration(seconds: 10));
    final data = jsonDecode(response.body);
    return LabResponse(
      response.statusCode,
      data is Map<String, dynamic> ? data : {'response': data},
    );
  }

  void close() => client.close();
}
