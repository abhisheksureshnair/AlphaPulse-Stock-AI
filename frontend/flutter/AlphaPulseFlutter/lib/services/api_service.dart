import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static String get baseUrl {
    const configuredUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (configuredUrl.isNotEmpty) {
      return configuredUrl;
    }

    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8000';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return 'http://127.0.0.1:8000';
      case TargetPlatform.fuchsia:
        return 'http://127.0.0.1:8000';
    }
  }

  static Future<Map<String, dynamic>> fetchStockData(String symbol) async {
    final response = await http.get(Uri.parse('$baseUrl/stock/$symbol'));
    return _decodeMapResponse(response, 'Failed to load stock data for $symbol');
  }

  static Future<List<Map<String, dynamic>>> fetchStocks(List<String> symbols) async {
    final response = await http.get(
      Uri.parse('$baseUrl/stocks?symbols=${symbols.join(',')}'),
    );
    final data = _decodeMapResponse(response, 'Failed to load tracked stocks');
    final stocks = data['stocks'];
    if (stocks is! List) {
      throw Exception('Invalid stock list response from backend.');
    }

    return stocks
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static Future<Map<String, dynamic>> fetchQuantAnalysis(String symbol) async {
    final response = await http.get(
      Uri.parse('$baseUrl/quant-analysis/$symbol'),
    );
    return _decodeMapResponse(response, 'Failed to get quant analysis');
  }

  static Future<Map<String, dynamic>> fetchPessimisticAnalysis(String symbol) async {
    final response = await http.get(
      Uri.parse('$baseUrl/bear-analysis/$symbol'),
      headers: await _getHeaders(),
    );
    return _decodeMapResponse(response, 'Failed to get pessimistic analysis');
  }

  static Future<List<Map<String, dynamic>>> fetchStocks() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/stocks'), headers: await _getHeaders());
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['stocks']);
      }
      throw Exception('Failed to load stocks');
    } catch (e) {
      throw Exception('Error fetching stocks: $e');
    }
  }

  static Future<Map<String, dynamic>> fetchRecommendation(double budget, {String strategy = 'aggressive', String? symbol, bool explainSimple = false}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/recommend'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'budget': budget,
        'strategy': strategy,
        'symbol': symbol,
        'explain_simple': explainSimple,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 429) {
      throw Exception('Rate limit exceeded. Please wait a minute before asking the AI again.');
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to get recommendation');
    }
  }

  static Future<Map<String, dynamic>> fetchPortfolio() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/portfolio'), headers: await _getHeaders());
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to load portfolio');
    } catch (e) {
      throw Exception('Error fetching portfolio: $e');
    }
  }

  static Future<void> buyStock(String ticker, double price, int quantity) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/buy'),
        headers: headers,
        body: json.encode({
          'ticker': ticker,
          'price': price,
          'quantity': quantity,
        }),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to record purchase');
      }
    } catch (e) {
      throw Exception('Error buying stock: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> fetchAlerts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/alerts'), headers: await _getHeaders());
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      throw Exception('Failed to load alerts');
    } catch (e) {
      throw Exception('Error fetching alerts: $e');
    }
  }

  static Future<void> createAlert(String ticker, String condition, double targetValue) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/alerts'),
        headers: headers,
        body: json.encode({
          'ticker': ticker,
          'condition': condition,
          'target_value': targetValue,
        }),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to create alert');
      }
    } catch (e) {
      throw Exception('Error creating alert: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> fetchHistory() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/history'), headers: await _getHeaders());
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      throw Exception('Failed to load history');
    } catch (e) {
      throw Exception('Error fetching history: $e');
    }
  }

  static Future<Map<String, dynamic>> scanMarket({String strategy = 'aggressive'}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/scan?strategy=$strategy'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to scan market');
    } catch (e) {
      throw Exception('Error scanning market: $e');
    }
  }

  static Future<Map<String, dynamic>> fetchOptimisticAnalysis(String symbol) async {
    final response = await http.get(
      Uri.parse('$baseUrl/ai-analysis/$symbol'),
    );
    return _decodeMapResponse(response, 'Failed to get optimistic analysis');
  }

  static Map<String, dynamic> _decodeMapResponse(http.Response response, String fallbackMessage) {
    final dynamic body = response.body.isEmpty ? <String, dynamic>{} : json.decode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body is Map<String, dynamic>) {
        return body;
      }
      if (body is Map) {
        return Map<String, dynamic>.from(body);
      }
      throw Exception('Unexpected response format from backend.');
    }

    final message = body is Map && body['detail'] != null ? body['detail'].toString() : fallbackMessage;
    throw Exception(message);
  }

  static Future<Map<String, String>> _getHeaders() async {
    final String? token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
