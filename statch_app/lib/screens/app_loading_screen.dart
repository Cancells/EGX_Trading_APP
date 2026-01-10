import 'dart:async';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../services/gold_service.dart';
import '../services/market_data_service.dart';
import '../services/preferences_service.dart';
import '../services/pin_service.dart';
import '../services/cache_service.dart';
import '../theme/app_theme.dart';
import '../widgets/statch_logo.dart';

/// App Loading Screen with breathing animation
/// Handles initial data fetching and biometric check
class AppLoadingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback? onSecurityRequired;

  const AppLoadingScreen({
    super.key,
    required this.onComplete,
    this.onSecurityRequired,
  });

  @override
  State<AppLoadingScreen> createState() => _AppLoadingScreenState();
}

class _AppLoadingScreenState extends State<AppLoadingScreen>
    with SingleTickerProviderStateMixin {
  final MarketDataService _marketService = MarketDataService();
  final GoldService _goldService = GoldService();
  final PinService _pinService = PinService();
  final CacheService _cacheService = CacheService();
  final LocalAuthentication _localAuth = LocalAuthentication();

  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;
  
  double _loadingProgress = 0.0;
  String _loadingMessage = 'Initializing...';
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startLoading();
  }

  void _initAnimations() {
    _breathingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _breathingAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _breathingController,
      curve: Curves.easeInOut,
    ));

    _breathingController.repeat(reverse: true);
  }

  Future<void> _startLoading() async {
    try {
      // Step 1: Auto-cleanup cache (silent, in background)
      _updateProgress(0.1, 'Optimizing storage...');
      await _cacheService.autoCleanup();
      
      // Step 2: Check biometrics availability
      _updateProgress(0.2, 'Checking security...');
      await _checkBiometrics();
      
      // Step 3: Initialize market data
      _updateProgress(0.4, 'Loading market data...');
      _marketService.startStreaming();
      
      // Step 4: Fetch gold prices
      _updateProgress(0.6, 'Fetching gold prices...');
      await _goldService.init();
      
      // Step 5: Final initialization
      _updateProgress(0.8, 'Almost ready...');
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Complete
      _updateProgress(1.0, 'Welcome to Statch!');
      await Future.delayed(const Duration(milliseconds: 500));
      
      setState(() => _isComplete = true);
      
      // Check if security is required
      if (_pinService.isSecurityEnabled && 
          (_pinService.isPinSet || _pinService.isBiometricEnabled)) {
        widget.onSecurityRequired?.call();
      } else {
        widget.onComplete();
      }
    } catch (e) {
      // On error, still proceed but log it
      debugPrint('Loading error: $e');
      _updateProgress(1.0, 'Ready');
      await Future.delayed(const Duration(milliseconds: 300));
      widget.onComplete();
    }
  }

  Future<void> _checkBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      debugPrint('Biometrics available: $canCheck, Device supported: $isDeviceSupported');
    } catch (e) {
      debugPrint('Biometric check error: $e');
    }
  }

  void _updateProgress(double progress, String message) {
    if (mounted) {
      setState(() {
        _loadingProgress = progress;
        _loadingMessage = message;
      });
    }
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            
            // Breathing Logo Animation
            Center(
              child: AnimatedBuilder(
                animation: _breathingAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _breathingAnimation.value,
                    child: child,
                  );
                },
                child: const StatchLogo(size: 100),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // App Name
            Text(
              'Statch',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Egyptian Market Trading',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.mutedText,
              ),
            ),
            
            const Spacer(flex: 2),
            
            // Loading Message
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _loadingMessage,
                key: ValueKey(_loadingMessage),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.mutedText,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Progress Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _loadingProgress,
                  backgroundColor: isDark 
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(
                    _isComplete ? AppTheme.robinhoodGreen : AppTheme.robinhoodGreen.withValues(alpha: 0.8),
                  ),
                  minHeight: 4,
                ),
              ),
            ),
            
            const SizedBox(height: 48),
            
            // Version
            Text(
              'Version 2.0.0',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.mutedText.withValues(alpha: 0.5),
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
