import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:async';


class ApiClient {
  // ========================================
  // إعدادات الاتصال بالسيرفر
  // ========================================
  // اختر طريقة الاتصال المناسبة:
  // 1. USB: useUsbReverse = true + adb reverse tcp:5153 tcp:5153
  // 2. Wi-Fi: useUsbReverse = false + عنوان IP الجهاز
  // 3. محاكي Android: استخدم 10.0.2.2
  static const bool useUsbReverse = false; 
  static const bool isEmulator = false; 
  static const String _wifiIpAddress = '192.168.100.8';
  static const String _emulatorAddress = '10.0.2.2';
  static const String _port = '5301'; // التجربة بالمنفذ 5301 مرة أخرى
  static const String _apiTimeout = '60'; 

  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:$_port/api';
    try {
      if (Platform.isAndroid) {
        if (useUsbReverse) return 'http://localhost:$_port/api'; 
        if (isEmulator) return 'http://$_emulatorAddress:$_port/api';
        return 'http://$_wifiIpAddress:$_port/api'; 
      }
      // استخدام localhost بدلاً من 127.0.0.1 لضمان التوافق
      if (Platform.isWindows) return 'http://localhost:$_port/api';
    } catch (_) {}
    return 'http://localhost:$_port/api';
  }

  // ---------------------------------------------------------
  final SharedPreferences prefs;
  ApiClient(this.prefs);

  Future<Map<String, String>> _getHeaders() async {
    final token = prefs.getString('auth_token');
    if (token == null) {
      debugPrint('🔑 [ Auth ] Warning: No auth_token found in preferences.');
    } else {
      debugPrint('🔑 [ Auth ] Token found (${token.substring(0, _min(token.length, 10))}...)');
    }
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  int _min(int a, int b) => a < b ? a : b;

  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    debugPrint('🌐 [ apiClient.GET ] -> $url');
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(url, headers: headers)
          .timeout(Duration(seconds: int.parse(_apiTimeout)));
      
      debugPrint('📡 [ Response ] Status: ${response.statusCode}');
      return response;
    } catch (e) {
      debugPrint('❌ [ Network Error ] GET failed for $url: ${e.toString()}');
      rethrow;
    }
  }

  Future<http.Response> post(String endpoint, dynamic data) async {
    final url = Uri.parse('$baseUrl$endpoint');
    debugPrint('🚀 [ apiClient.POST ] -> $url');
    debugPrint('📦 [ Payload ] -> ${jsonEncode(data)}');
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(url, headers: headers, body: jsonEncode(data))
          .timeout(Duration(seconds: int.parse(_apiTimeout)));
      
      debugPrint('📡 [ Response ] Status: ${response.statusCode}');
      if (response.statusCode >= 400) {
        debugPrint('⚠️ [ Server Error ] Body: ${response.body}');
      }
      return response;
    } catch (e) {
      if (e is SocketException) {
        debugPrint('🚫 [ Connection Refused ] تأكد من تشغيل السيرفر على $baseUrl ومن مطابقة عنوان IP.');
      }
      debugPrint('❌ [ Network Error ] POST failed for $url: ${e.toString()}');
      rethrow;
    }
  }

  Future<http.Response> put(String endpoint, dynamic data) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl$endpoint');
      debugPrint('PUT: $url');
      return await http
          .put( 
            url,
            headers: headers,
            body: jsonEncode(data),
          )
          .timeout(Duration(seconds: int.parse(_apiTimeout)));
    } catch (e) {
      debugPrint('خطأ PUT: $endpoint - ${e.toString()}');
      throw Exception('خطأ الاتصال: ${e.toString()}');
    }
  }

  // Helper to check for success
  bool isSuccess(http.Response response) =>
      response.statusCode >= 200 && response.statusCode < 300;
}
