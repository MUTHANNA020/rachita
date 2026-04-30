import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/providers/app_settings_provider.dart';
import '../../../core/database/database_helper.dart';

final authRepositoryProvider = Provider((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthRepository(ApiClient(prefs), prefs);
});

class AuthRepository {
  final ApiClient apiClient;
  final SharedPreferences prefs;

  AuthRepository(this.apiClient, this.prefs);

  Future<bool> login(String username, String password) async {
    final response = await apiClient.post('/Auth/login', {
      'username': username,
      'password': password,
    });

    if (apiClient.isSuccess(response)) {
      final decoded = jsonDecode(response.body);
      final token = decoded['token'];
      final clinicId = decoded['clinicId']; // Ensure your backend sends this
      
      // Save auth info
      await prefs.setString('auth_token', token);
      await prefs.setString('clinic_id', clinicId.toString());
      
      // حفظ معلومات الحساب الإضافية
      await prefs.setString('username', decoded['username'] ?? username);
      if (decoded['email'] != null) {
        await prefs.setString('user_email', decoded['email']);
      }
      if (decoded['clinicName'] != null) {
        await prefs.setString('clinic_name', decoded['clinicName']);
      }
      
      // Reset out the old DB and initialize the new one scoped to this clinic
      await DatabaseHelper.instance.resetDb();
      await DatabaseHelper.instance.database; 

      return true;
    }
    return false;
  }

  Future<bool> register(String clinicName, String fullName, String username, String password) async {
    final response = await apiClient.post('/Auth/register-clinic', {
      'clinicName': clinicName,
      'fullName': fullName,
      'username': username,
      'password': password,
    });
    
    if (apiClient.isSuccess(response)) {
      try {
        final decoded = jsonDecode(response.body);
        final token = decoded['token'];
        final clinicId = decoded['clinicId'];
        
        // Save auth info for immediate session start
        await prefs.setString('auth_token', token);
        await prefs.setString('clinic_id', clinicId.toString());
        await prefs.setString('username', username);
        await prefs.setString('clinic_name', clinicName);
        
        // Setup fresh database for this new clinic
        await DatabaseHelper.instance.resetDb();
        await DatabaseHelper.instance.database;
        
        return true;
      } catch (e) {
        debugPrint("Error processing registration response: $e");
      }
      return true; // Still true because the request succeeded
    }
    return false;
  }

  bool isAuthenticated() => prefs.containsKey('auth_token');
  
  void logout() {
    prefs.remove('auth_token');
    prefs.remove('clinic_id');
    // Clear and close current user's DB connection
    DatabaseHelper.instance.resetDb();
  }
}
