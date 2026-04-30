class EncryptionService {
  // Simplified EncryptionService: Encryption disabled by user request
  
  static const String _cachedKey = "disabled_security_key";

  static void setPinKey(String pin) {
    // No-op
  }

  static String getDatabasePassword() {
    return _cachedKey;
  }

  static String hashPin(String pin) {
    return pin; // No hashing
  }
}
