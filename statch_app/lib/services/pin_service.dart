import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing PIN security
class PinService {
  static final PinService _instance = PinService._internal();
  factory PinService() => _instance;
  PinService._internal();

  static const String _keyPinHash = 'pin_hash';
  static const String _keyPinEnabled = 'pin_enabled';
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyFailedAttempts = 'failed_attempts';
  static const String _keyLockoutUntil = 'lockout_until';
  static const String _keySecurityEnabled = 'security_enabled';
  
  static const int maxAttempts = 5;
  static const int lockoutMinutes = 5;

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Check if security is enabled
  bool get isSecurityEnabled => _prefs?.getBool(_keySecurityEnabled) ?? false;
  
  Future<void> setSecurityEnabled(bool value) async {
    await _prefs?.setBool(_keySecurityEnabled, value);
  }

  /// Check if PIN is set
  bool get isPinSet => _prefs?.getString(_keyPinHash) != null;

  /// Check if biometric is enabled
  bool get isBiometricEnabled => _prefs?.getBool(_keyBiometricEnabled) ?? false;

  Future<void> setBiometricEnabled(bool value) async {
    await _prefs?.setBool(_keyBiometricEnabled, value);
  }

  /// Hash PIN for secure storage
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Set PIN
  Future<void> setPin(String pin) async {
    final hash = _hashPin(pin);
    await _prefs?.setString(_keyPinHash, hash);
    await _prefs?.setBool(_keyPinEnabled, true);
    await _resetFailedAttempts();
  }

  /// Verify PIN
  Future<bool> verifyPin(String pin) async {
    if (await isLockedOut()) {
      return false;
    }

    final storedHash = _prefs?.getString(_keyPinHash);
    if (storedHash == null) return false;

    final inputHash = _hashPin(pin);
    final isValid = storedHash == inputHash;

    if (isValid) {
      await _resetFailedAttempts();
    } else {
      await _incrementFailedAttempts();
    }

    return isValid;
  }

  /// Remove PIN
  Future<void> removePin() async {
    await _prefs?.remove(_keyPinHash);
    await _prefs?.setBool(_keyPinEnabled, false);
    await _resetFailedAttempts();
  }

  /// Get failed attempts count
  int get failedAttempts => _prefs?.getInt(_keyFailedAttempts) ?? 0;

  /// Check if locked out
  Future<bool> isLockedOut() async {
    final lockoutUntil = _prefs?.getInt(_keyLockoutUntil);
    if (lockoutUntil == null) return false;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (now < lockoutUntil) {
      return true;
    } else {
      // Lockout expired, reset
      await _resetFailedAttempts();
      return false;
    }
  }

  /// Get remaining lockout time in seconds
  int get remainingLockoutSeconds {
    final lockoutUntil = _prefs?.getInt(_keyLockoutUntil);
    if (lockoutUntil == null) return 0;

    final now = DateTime.now().millisecondsSinceEpoch;
    final remaining = ((lockoutUntil - now) / 1000).ceil();
    return remaining > 0 ? remaining : 0;
  }

  Future<void> _incrementFailedAttempts() async {
    final attempts = failedAttempts + 1;
    await _prefs?.setInt(_keyFailedAttempts, attempts);

    if (attempts >= maxAttempts) {
      final lockoutUntil = DateTime.now()
          .add(const Duration(minutes: lockoutMinutes))
          .millisecondsSinceEpoch;
      await _prefs?.setInt(_keyLockoutUntil, lockoutUntil);
    }
  }

  Future<void> _resetFailedAttempts() async {
    await _prefs?.setInt(_keyFailedAttempts, 0);
    await _prefs?.remove(_keyLockoutUntil);
  }
}
