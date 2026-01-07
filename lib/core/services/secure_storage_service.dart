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
  Future<bool> setPin(String pin) async {
    try {
      final salt = _generateSalt();
      final hashedPin = _hashPin(pin, salt);
      await _storage.write(key: _pinKey, value: hashedPin);
      await _storage.write(key: _saltKey, value: salt);
      return true;
    } catch (e) {
      debugPrint("Error setting PIN: $e");
      return false;
    }
  }
  Future<bool> verifyPin(String pin) async {
    try {
      final storedHash = await _storage.read(key: _pinKey);
      final salt = await _storage.read(key: _saltKey);
      if (storedHash == null || salt == null) {
        return false;
      }
      final providedHash = _hashPin(pin, salt);
      return providedHash == storedHash;
    } catch (e) {
      debugPrint("Error verifying PIN: $e");
      return false;
    }
  }
  Future<bool> hasPinSet() async {
    try {
      final pinExists = await _storage.read(key: _pinKey);
      return pinExists != null;
    } catch (e) {
      debugPrint("Error checking PIN existence: $e");
      return false;
    }
  }
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
  String _generateSalt() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    return base64Encode(utf8.encode(random)).substring(0, 16);
  }
  String _hashPin(String pin, String salt) {
    return sha256.convert(utf8.encode('$pin$salt')).toString();
  }
}

