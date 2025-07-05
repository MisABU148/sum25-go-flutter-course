import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

import '../models/message.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8080';
  static const Duration timeout = Duration(seconds: 30);
  late http.Client _client;

  ApiService() {
    _client = http.Client();
  }

  void dispose() {
    _client.close();
  }

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  T _handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final statusCode = response.statusCode;

    if (statusCode >= 200 && statusCode < 300) {
      final Map<String, dynamic> decoded = json.decode(response.body);
      return fromJson(decoded);
    } else if (statusCode >= 400 && statusCode < 500) {
      final message = json.decode(response.body)['message'] ?? 'Client error';
      throw ApiException('Client error: $message');
    } else if (statusCode >= 500 && statusCode < 600) {
      throw ServerException('Server error: ${response.statusCode}');
    } else {
      throw ApiException('Unexpected error: ${response.statusCode}');
    }
  }

  Future<List<Message>> getMessages() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/api/messages'), headers: _getHeaders())
          .timeout(timeout);

      final data = _handleResponse<Map<String, dynamic>>(
        response,
        (json) => json,
      );

      final List<dynamic> messagesJson = data['data'];
      return messagesJson.map((e) => Message.fromJson(e)).toList();
    } on TimeoutException {
      throw NetworkException('Request timed out');
    } on http.ClientException catch (e) {
      throw NetworkException(e.toString());
    }
  }

  Future<Message> createMessage(CreateMessageRequest request) async {
    final validationError = request.validate();
    if (validationError != null) {
      throw ValidationException(validationError);
    }

    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/api/messages'),
            headers: _getHeaders(),
            body: json.encode(request.toJson()),
          )
          .timeout(timeout);

      final data = _handleResponse<Map<String, dynamic>>(
        response,
        (json) => json,
      );

      return Message.fromJson(data['data']);
    } on TimeoutException {
      throw NetworkException('Request timed out');
    }
  }

  Future<Message> updateMessage(int id, UpdateMessageRequest request) async {
    final validationError = request.validate();
    if (validationError != null) {
      throw ValidationException(validationError);
    }

    try {
      final response = await _client
          .put(
            Uri.parse('$baseUrl/api/messages/$id'),
            headers: _getHeaders(),
            body: json.encode(request.toJson()),
          )
          .timeout(timeout);

      final data = _handleResponse<Map<String, dynamic>>(
        response,
        (json) => json,
      );

      return Message.fromJson(data['data']);
    } on TimeoutException {
      throw NetworkException('Request timed out');
    }
  }

  Future<void> deleteMessage(int id) async {
    try {
      final response = await _client
          .delete(
            Uri.parse('$baseUrl/api/messages/$id'),
            headers: _getHeaders(),
          )
          .timeout(timeout);

      if (response.statusCode != 204) {
        throw ApiException('Failed to delete message');
      }
    } on TimeoutException {
      throw NetworkException('Request timed out');
    }
  }

  Future<HTTPStatusResponse> getHTTPStatus(int statusCode) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl/api/status/$statusCode'),
            headers: _getHeaders(),
          )
          .timeout(timeout);

      final data = _handleResponse<Map<String, dynamic>>(
        response,
        (json) => json,
      );

      return HTTPStatusResponse.fromJson(data['data']);
    } on TimeoutException {
      throw NetworkException('Request timed out');
    }
  }

  Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/api/health'), headers: _getHeaders())
          .timeout(timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body);
      } else {
        throw ApiException('Health check failed: ${response.statusCode}');
      }
    } on TimeoutException {
      throw NetworkException('Request timed out');
    }
  }
}

// Custom Exceptions
class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}

class NetworkException extends ApiException {
  NetworkException(String message) : super(message);
}

class ServerException extends ApiException {
  ServerException(String message) : super(message);
}

class ValidationException extends ApiException {
  ValidationException(String message) : super(message);
}
