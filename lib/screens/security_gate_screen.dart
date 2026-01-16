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
    
    _isLockedOut = await _pinService.isLockedOut();
    if (_isLockedOut) {
      _startLockoutTimer();
      setState(() => _showPinEntry = true);
      return;
    }

    if (_pinService.isBiometricEnabled) {
      await _authenticateWithBiometrics();
    } else if (_pinService.isPinSet) {
      setState(() => _showPinEntry = true);
    } else {
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
      if (!canCheckBiometrics) {
        setState(() { _showPinEntry = true; _isLoading = false; });
        return;
      }

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access Statch',
        options: const AuthenticationOptions(stickyAuth: true),
      );

      if (didAuthenticate) {
        widget.onAuthenticated();
      } else {
        setState(() => _showPinEntry = true);
      }
    } catch (e) {
      setState(() => _showPinEntry = true);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _onPinDigitEntered(String digit) {
    if (_isLockedOut || _enteredPin.length >= 4) return;
    HapticFeedback.lightImpact();
    setState(() {
      _enteredPin += digit;
      _errorMessage = null;
    });
    if (_enteredPin.length == 4) _verifyPin();
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
          _errorMessage = 'Incorrect PIN.';
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
              const AnimatedStatchLogo(size: 80),
              const SizedBox(height: 24),
              Text('Welcome Back', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_showPinEntry ? 'Enter your PIN' : 'Authenticating...', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedText)),
              const Spacer(),
              if (_showPinEntry) ...[
                _buildPinDots(isDark),
                const SizedBox(height: 16),
                if (_errorMessage != null) Text(_errorMessage!, style: const TextStyle(color: AppTheme.robinhoodRed, fontSize: 14)),
                if (_isLockedOut) Text('Try again in ${_remainingLockoutSeconds}s', style: const TextStyle(color: AppTheme.mutedText)),
                const SizedBox(height: 32),
                _buildNumberPad(isDark),
                const SizedBox(height: 24),
                if (_pinService.isBiometricEnabled && !_isLockedOut)
                  TextButton.icon(
                    onPressed: _authenticateWithBiometrics,
                    icon: const Icon(Icons.fingerprint_rounded),
                    label: const Text('Use Biometrics'),
                    style: TextButton.styleFrom(foregroundColor: AppTheme.robinhoodGreen),
                  ),
              ] else if (_isLoading)
                const CircularProgressIndicator(color: AppTheme.robinhoodGreen),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinDots(bool isDark) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) => Transform.translate(
        offset: Offset(_shakeAnimation.value * ((_shakeController.value * 10).toInt() % 2 == 0 ? 1 : -1), 0),
        child: child,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (index) {
          final isFilled = index < _enteredPin.length;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            width: 20, height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFilled ? AppTheme.robinhoodGreen : Colors.transparent,
              border: Border.all(color: isFilled ? AppTheme.robinhoodGreen : (isDark ? Colors.white30 : Colors.black26), width: 2),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNumberPad(bool isDark) {
    return Column(children: [
      ['1', '2', '3'], ['4', '5', '6'], ['7', '8', '9'], ['', '0', 'del']
    ].map((row) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: row.map((val) => val.isEmpty ? const SizedBox(width: 80) : _buildPadButton(val, isDark)).toList()))).toList());
  }

  Widget _buildPadButton(String value, bool isDark) {
    final isDelete = value == 'del';
    final isDisabled = _isLockedOut || _isLoading;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: InkWell(
        onTap: isDisabled ? null : () => isDelete ? _onPinDelete() : _onPinDigitEntered(value),
        borderRadius: BorderRadius.circular(40),
        child: Container(
          width: 72, height: 72,
          decoration: BoxDecoration(shape: BoxShape.circle, color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)),
          child: Center(child: isDelete 
            ? Icon(Icons.backspace_outlined, color: isDisabled ? AppTheme.mutedText : (isDark ? Colors.white : Colors.black)) 
            : Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w500, color: isDisabled ? AppTheme.mutedText : (isDark ? Colors.white : Colors.black)))),
        ),
      ),
    );
  }
}

/// PIN Setup Screen (Updated with isChanging support)
class PinSetupScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final bool isChanging;

  const PinSetupScreen({
    super.key,
    required this.onComplete,
    this.isChanging = false,
  });

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final PinService _pinService = PinService();
  
  // Stages: 0 = Enter Old (if changing), 1 = Enter New, 2 = Confirm New
  int _stage = 0;
  
  String _oldPin = '';
  String _newPin = '';
  String _confirmPin = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // If not changing, skip stage 0 (Old PIN)
    _stage = widget.isChanging ? 0 : 1;
  }

  void _onDigitEntered(String digit) {
    HapticFeedback.lightImpact();
    setState(() {
      _errorMessage = null;
      if (_stage == 0) {
        if (_oldPin.length < 4) {
          _oldPin += digit;
          if (_oldPin.length == 4) _verifyOldPin();
        }
      } else if (_stage == 1) {
        if (_newPin.length < 4) {
          _newPin += digit;
          if (_newPin.length == 4) setState(() => _stage = 2);
        }
      } else if (_stage == 2) {
        if (_confirmPin.length < 4) {
          _confirmPin += digit;
          if (_confirmPin.length == 4) _verifyAndSave();
        }
      }
    });
  }

  void _onDelete() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_stage == 0) {
        if (_oldPin.isNotEmpty) _oldPin = _oldPin.substring(0, _oldPin.length - 1);
      } else if (_stage == 1) {
        if (_newPin.isNotEmpty) _newPin = _newPin.substring(0, _newPin.length - 1);
      } else if (_stage == 2) {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        } else {
          // Go back to entering new pin
          _stage = 1;
          _newPin = _newPin.substring(0, _newPin.length - 1);
        }
      }
    });
  }

  Future<void> _verifyOldPin() async {
    final isValid = await _pinService.verifyPin(_oldPin);
    if (isValid) {
      setState(() {
        _stage = 1; // Move to enter new PIN
      });
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _errorMessage = 'Incorrect old PIN';
        _oldPin = '';
      });
    }
  }

  Future<void> _verifyAndSave() async {
    if (_newPin == _confirmPin) {
      await _pinService.setPin(_newPin);
      widget.onComplete();
      if (mounted) Navigator.pop(context, true);
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _errorMessage = 'PINs do not match. Try again.';
        _confirmPin = '';
        _stage = 1; // Go back to enter new pin
        _newPin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    String title = 'Create a PIN';
    String subtitle = 'Choose a 4-digit PIN';
    String currentInput = _newPin;

    if (_stage == 0) {
      title = 'Verify Identity';
      subtitle = 'Enter your current PIN';
      currentInput = _oldPin;
    } else if (_stage == 1) {
      title = widget.isChanging ? 'New PIN' : 'Create a PIN';
      subtitle = 'Enter your new 4-digit PIN';
      currentInput = _newPin;
    } else {
      title = 'Confirm PIN';
      subtitle = 'Enter the PIN again to confirm';
      currentInput = _confirmPin;
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Icon(Icons.lock_outline_rounded, size: 64, color: AppTheme.robinhoodGreen),
              const SizedBox(height: 24),
              Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedText)),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < currentInput.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled ? AppTheme.robinhoodGreen : Colors.transparent,
                      border: Border.all(color: isFilled ? AppTheme.robinhoodGreen : (isDark ? Colors.white30 : Colors.black26), width: 2),
                    ),
                  );
                }),
              ),
              if (_errorMessage != null) ...[const SizedBox(height: 16), Text(_errorMessage!, style: const TextStyle(color: AppTheme.robinhoodRed))],
              const Spacer(),
              _buildNumberPad(isDark),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberPad(bool isDark) {
    return Column(children: [
      ['1', '2', '3'], ['4', '5', '6'], ['7', '8', '9'], ['', '0', 'del']
    ].map((row) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: row.map((val) => val.isEmpty ? const SizedBox(width: 80) : _buildPadButton(val, isDark)).toList()))).toList());
  }

  Widget _buildPadButton(String value, bool isDark) {
    final isDelete = value == 'del';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: InkWell(
        onTap: () => isDelete ? _onDelete() : _onDigitEntered(value),
        borderRadius: BorderRadius.circular(40),
        child: Container(
          width: 72, height: 72,
          decoration: BoxDecoration(shape: BoxShape.circle, color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)),
          child: Center(child: isDelete ? const Icon(Icons.backspace_outlined, size: 24) : Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500))),
        ),
      ),
    );
  }
}