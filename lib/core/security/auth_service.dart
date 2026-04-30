class AuthService {
  // Simplified AuthService: Security disabled by user request
  
  static Future<bool> hasPinSetup() async {
    return false;
  }

  static Future<void> savePin(String pin) async {
    // No-op: security disabled
  }

  static Future<bool> verifyPin(String pin) async {
    return true; // Transparently allow
  }

  static Future<bool> unlockWithBiometric() async {
    return true; // Transparently allow
  }
}
