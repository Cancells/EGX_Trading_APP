import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../services/pin_service.dart';
import '../theme/app_theme.dart';
import '../widgets/statch_logo.dart';

/// Security Gate Screen with biometric and PIN authentication
class SecurityGateScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const SecurityGateScreen({
    super.key,
    required this.onAuthenticated,
  });

  @override
  State<SecurityGateScreen> createState() => _SecurityGateScreenState();
}

class _SecurityGateScreenState extends State<SecurityGateScreen>
    with SingleTickerProviderStateMixin {
  final PinService _pinService = PinService();
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  
  String _enteredPin = '';
  bool _isLoading = false;
  bool _isLockedOut = false;
  int _remainingLockoutSeconds = 0;
  String? _errorMessage;
  bool _showPinEntry = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
    _initSecurity();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _initSecurity() async {
    await _pinService.init();
    
    // Check lockout status
    _isLockedOut = await _pinService.isLockedOut();
    if (_isLockedOut) {
      _startLockoutTimer();
      setState(() => _showPinEntry = true);
      return;
    }

    // Try biometric first if enabled
    if (_pinService.isBiometricEnabled) {
      await _authenticateWithBiometrics();
    } else if (_pinService.isPinSet) {
      setState(() => _showPinEntry = true);
    } else {
      // No security set, proceed
      widget.onAuthenticated();
    }
  }

  void _startLockoutTimer() {
    _remainingLockoutSeconds = _pinService.remainingLockoutSeconds;
    if (_remainingLockoutSeconds > 0) {
      Future.doWhile(() async {
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          setState(() {
            _remainingLockoutSeconds--;
            if (_remainingLockoutSeconds <= 0) {
              _isLockedOut = false;
            }
          });
        }
        return _remainingLockoutSeconds > 0 && mounted;
      });
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    setState(() => _isLoading = true);
    
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!canCheckBiometrics || !isDeviceSupported) {
        setState(() {
          _showPinEntry = true;
          _isLoading = false;
        });
        return;
      }

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access Statch',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (didAuthenticate) {
        widget.onAuthenticated();
      } else {
        setState(() => _showPinEntry = true);
      }
    } on PlatformException catch (e) {
      debugPrint('Biometric error: $e');
      setState(() => _showPinEntry = true);
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _onPinDigitEntered(String digit) {
    if (_isLockedOut || _enteredPin.length >= 4) return;
    
    HapticFeedback.lightImpact();
    setState(() {
      _enteredPin += digit;
      _errorMessage = null;
    });

    if (_enteredPin.length == 4) {
      _verifyPin();
    }
  }

  void _onPinDelete() {
    if (_enteredPin.isEmpty) return;
    
    HapticFeedback.lightImpact();
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _errorMessage = null;
    });
  }

  Future<void> _verifyPin() async {
    setState(() => _isLoading = true);

    final isValid = await _pinService.verifyPin(_enteredPin);

    if (isValid) {
      widget.onAuthenticated();
    } else {
      _shakeController.forward().then((_) => _shakeController.reset());
      HapticFeedback.heavyImpact();
      
      final isNowLockedOut = await _pinService.isLockedOut();
      
      setState(() {
        _enteredPin = '';
        _isLoading = false;
        _isLockedOut = isNowLockedOut;
        
        if (isNowLockedOut) {
          _errorMessage = 'Too many attempts. Try again later.';
          _startLockoutTimer();
        } else {
          final remaining = PinService.maxAttempts - _pinService.failedAttempts;
          _errorMessage = 'Incorrect PIN. $remaining attempts remaining.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              
              // Logo
              const AnimatedStatchLogo(size: 80),
              const SizedBox(height: 24),
              
              Text(
                'Welcome Back',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _showPinEntry ? 'Enter your PIN to continue' : 'Authenticating...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.mutedText,
                ),
              ),
              
              const Spacer(),

              if (_showPinEntry) ...[
                // PIN Dots
                AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(_shakeAnimation.value * ((_shakeController.value * 10).toInt() % 2 == 0 ? 1 : -1), 0),
                      child: child,
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final isFilled = index < _enteredPin.length;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFilled
                              ? AppTheme.robinhoodGreen
                              : Colors.transparent,
                          border: Border.all(
                            color: isFilled
                                ? AppTheme.robinhoodGreen
                                : (isDark ? Colors.white30 : Colors.black26),
                            width: 2,
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 16),

                // Error Message
                if (_errorMessage != null)
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: AppTheme.robinhoodRed,
                      fontSize: 14,
                    ),
                  ),

                // Lockout Timer
                if (_isLockedOut && _remainingLockoutSeconds > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Try again in ${_remainingLockoutSeconds}s',
                      style: const TextStyle(
                        color: AppTheme.mutedText,
                        fontSize: 14,
                      ),
                    ),
                  ),

                const SizedBox(height: 32),

                // Number Pad
                _buildNumberPad(isDark),

                const SizedBox(height: 24),

                // Biometric Button
                if (_pinService.isBiometricEnabled && !_isLockedOut)
                  TextButton.icon(
                    onPressed: _authenticateWithBiometrics,
                    icon: const Icon(Icons.fingerprint_rounded),
                    label: const Text('Use Biometrics'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.robinhoodGreen,
                    ),
                  ),
              ] else if (_isLoading) ...[
                const CircularProgressIndicator(
                  color: AppTheme.robinhoodGreen,
                ),
              ],

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberPad(bool isDark) {
    final buttons = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'del'],
    ];

    return Column(
      children: buttons.map((row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((value) {
              if (value.isEmpty) {
                return const SizedBox(width: 80);
              }
              return _buildPadButton(value, isDark);
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPadButton(String value, bool isDark) {
    final isDelete = value == 'del';
    final isDisabled = _isLockedOut || _isLoading;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled
              ? null
              : () {
                  if (isDelete) {
                    _onPinDelete();
                  } else {
                    _onPinDigitEntered(value);
                  }
                },
          borderRadius: BorderRadius.circular(40),
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
            ),
            child: Center(
              child: isDelete
                  ? Icon(
                      Icons.backspace_outlined,
                      size: 24,
                      color: isDisabled
                          ? AppTheme.mutedText
                          : (isDark ? Colors.white : Colors.black),
                    )
                  : Text(
                      value,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                        color: isDisabled
                            ? AppTheme.mutedText
                            : (isDark ? Colors.white : Colors.black),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// PIN Setup Screen
class PinSetupScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const PinSetupScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final PinService _pinService = PinService();
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  String? _errorMessage;

  void _onDigitEntered(String digit) {
    HapticFeedback.lightImpact();
    
    setState(() {
      _errorMessage = null;
      if (_isConfirming) {
        if (_confirmPin.length < 4) {
          _confirmPin += digit;
          if (_confirmPin.length == 4) {
            _verifyAndSave();
          }
        }
      } else {
        if (_pin.length < 4) {
          _pin += digit;
          if (_pin.length == 4) {
            _isConfirming = true;
          }
        }
      }
    });
  }

  void _onDelete() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_isConfirming) {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        } else {
          _isConfirming = false;
          _pin = _pin.substring(0, _pin.length - 1);
        }
      } else {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        }
      }
    });
  }

  Future<void> _verifyAndSave() async {
    if (_pin == _confirmPin) {
      await _pinService.setPin(_pin);
      widget.onComplete();
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _errorMessage = 'PINs do not match. Try again.';
        _confirmPin = '';
        _isConfirming = false;
        _pin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentPin = _isConfirming ? _confirmPin : _pin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set PIN'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              
              const Icon(
                Icons.lock_outline_rounded,
                size: 64,
                color: AppTheme.robinhoodGreen,
              ),
              const SizedBox(height: 24),
              
              Text(
                _isConfirming ? 'Confirm Your PIN' : 'Create a PIN',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isConfirming
                    ? 'Enter the same PIN again'
                    : 'Choose a 4-digit PIN for quick access',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.mutedText,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // PIN Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < currentPin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled ? AppTheme.robinhoodGreen : Colors.transparent,
                      border: Border.all(
                        color: isFilled
                            ? AppTheme.robinhoodGreen
                            : (isDark ? Colors.white30 : Colors.black26),
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppTheme.robinhoodRed),
                ),
              ],

              const Spacer(),

              // Number Pad (same as SecurityGateScreen)
              _buildNumberPad(isDark),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberPad(bool isDark) {
    final buttons = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'del'],
    ];

    return Column(
      children: buttons.map((row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((value) {
              if (value.isEmpty) return const SizedBox(width: 80);
              return _buildPadButton(value, isDark);
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPadButton(String value, bool isDark) {
    final isDelete = value == 'del';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (isDelete) {
              _onDelete();
            } else {
              _onDigitEntered(value);
            }
          },
          borderRadius: BorderRadius.circular(40),
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
            ),
            child: Center(
              child: isDelete
                  ? const Icon(Icons.backspace_outlined, size: 24)
                  : Text(
                      value,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
