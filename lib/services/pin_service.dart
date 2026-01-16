import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PinService {
  static final PinService _instance = PinService._internal();
  factory PinService() => _instance;
  PinService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  SharedPreferences? _prefs;

  static const String _keyPin = 'user_pin';
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyLockoutTime = 'pin_lockout_timestamp';
  static const String _keyFailedAttempts = 'pin_failed_attempts';
  
  static const int maxAttempts = 5;
  static const int lockoutDurationSeconds = 30;

  bool _isPinSet = false;
  bool get isPinSet => _isPinSet;

  bool _isBiometricEnabled = false;
  bool get isBiometricEnabled => _isBiometricEnabled;

  // Add this getter to fix AppLoadingScreen error
  bool get isSecurityEnabled => _isPinSet; 

  int _failedAttempts = 0;
  int get failedAttempts => _failedAttempts;

  DateTime? _lockoutEndTime;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Check if PIN exists in secure storage
    final pin = await _secureStorage.read(key: _keyPin);
    _isPinSet = pin != null && pin.isNotEmpty;

    // Load non-sensitive preferences
    _isBiometricEnabled = _prefs?.getBool(_keyBiometricEnabled) ?? false;
    _failedAttempts = _prefs?.getInt(_keyFailedAttempts) ?? 0;
    
    final lockoutTimestamp = _prefs?.getInt(_keyLockoutTime);
    if (lockoutTimestamp != null) {
      _lockoutEndTime = DateTime.fromMillisecondsSinceEpoch(lockoutTimestamp);
      if (DateTime.now().isAfter(_lockoutEndTime!)) {
        _resetLockout();
      }
    }
  }

  /// Sets a new PIN
  Future<void> setPin(String pin) async {
    await _secureStorage.write(key: _keyPin, value: pin);
    _isPinSet = true;
    _resetLockout();
  }

  /// Removes the PIN (Disables Security)
  Future<void> removePin() async {
    await _secureStorage.delete(key: _keyPin);
    _isPinSet = false;
    // Also disable biometrics if PIN is removed
    await setBiometricEnabled(false);
  }

  /// Verifies the entered PIN
  Future<bool> verifyPin(String enteredPin) async {
    if (await isLockedOut()) return false;

    final storedPin = await _secureStorage.read(key: _keyPin);
    if (storedPin == enteredPin) {
      _resetLockout();
      return true;
    } else {
      await _incrementFailedAttempts();
      return false;
    }
  }

  /// Toggle Biometric
  Future<void> setBiometricEnabled(bool enabled) async {
    _isBiometricEnabled = enabled;
    await _prefs?.setBool(_keyBiometricEnabled, enabled);
  }

  Future<void> _incrementFailedAttempts() async {
    _failedAttempts++;
    await _prefs?.setInt(_keyFailedAttempts, _failedAttempts);

    if (_failedAttempts >= maxAttempts) {
      _lockoutEndTime = DateTime.now().add(const Duration(seconds: lockoutDurationSeconds));
      await _prefs?.setInt(_keyLockoutTime, _lockoutEndTime!.millisecondsSinceEpoch);
    }
  }

  Future<void> _resetLockout() async {
    _failedAttempts = 0;
    _lockoutEndTime = null;
    await _prefs?.remove(_keyFailedAttempts);
    await _prefs?.remove(_keyLockoutTime);
  }

  Future<bool> isLockedOut() async {
    if (_lockoutEndTime != null) {
      if (DateTime.now().isBefore(_lockoutEndTime!)) {
        return true;
      } else {
        await _resetLockout();
        return false;
      }
    }
    return false;
  }

  int get remainingLockoutSeconds {
    if (_lockoutEndTime == null) return 0;
    final diff = _lockoutEndTime!.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }
}