import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const String _pinKey = 'anas_locker_pin';
  static const String _saltKey = 'anas_locker_salt';

  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  /// Sets the locker PIN with hashing and salt for secure storage
  Future<bool> setPin(String pin) async {
    try {
      // Generate a random salt
      final salt = _generateSalt();

      // Hash the PIN with salt
      final hashedPin = _hashPin(pin, salt);

      // Store both hash and salt
      await _storage.write(key: _pinKey, value: hashedPin);
      await _storage.write(key: _saltKey, value: salt);

      return true;
    } catch (e) {
      debugPrint("Error setting PIN: $e");
      return false;
    }
  }

  /// Verifies the provided PIN against the stored hash
  Future<bool> verifyPin(String pin) async {
    try {
      final storedHash = await _storage.read(key: _pinKey);
      final salt = await _storage.read(key: _saltKey);

      if (storedHash == null || salt == null) {
        return false;
      }

      // Hash the provided PIN with the stored salt
      final providedHash = _hashPin(pin, salt);

      return providedHash == storedHash;
    } catch (e) {
      debugPrint("Error verifying PIN: $e");
      return false;
    }
  }

  /// Checks if a PIN has been set
  Future<bool> hasPinSet() async {
    try {
      final pinExists = await _storage.read(key: _pinKey);
      return pinExists != null;
    } catch (e) {
      debugPrint("Error checking PIN existence: $e");
      return false;
    }
  }

  /// Clears the stored PIN
  Future<bool> clearPin() async {
    try {
      await _storage.delete(key: _pinKey);
      await _storage.delete(key: _saltKey);
      return true;
    } catch (e) {
      debugPrint("Error clearing PIN: $e");
      return false;
    }
  }

  /// Generates a random salt for PIN hashing
  String _generateSalt() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    return base64Encode(utf8.encode(random)).substring(0, 16);
  }

  /// Hashes a PIN with salt using SHA-256
  String _hashPin(String pin, String salt) {
    return sha256.convert(utf8.encode('$pin$salt')).toString();
  }
}
