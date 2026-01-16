import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/preferences_service.dart';
import '../services/pin_service.dart';
import '../services/currency_service.dart';
import '../theme/dynamic_theme.dart';
import '../theme/app_theme.dart'; // REQUIRED IMPORT for ThemeSetting extension
import 'security_gate_screen.dart';
import 'profile_screen.dart';
import 'about_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late PreferencesService _prefsService; 
  final PinService _pinService = PinService();
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  bool _notificationsEnabled = true;
  bool _priceAlertsEnabled = true;
  bool _securityEnabled = false;
  bool _biometricEnabled = false;
  bool _canCheckBiometrics = false;

  @override
  void initState() {
    super.initState();
    final prefs = Provider.of<PreferencesService>(context, listen: false);
    _prefsService = prefs;
    
    _notificationsEnabled = prefs.notificationsEnabled;
    _priceAlertsEnabled = prefs.priceAlertsEnabled;
    _securityEnabled = _pinService.isPinSet;
    _biometricEnabled = _pinService.isBiometricEnabled;
    
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      _canCheckBiometrics = await _localAuth.canCheckBiometrics;
      if (mounted) setState(() {});
    } catch (_) {
      _canCheckBiometrics = false;
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    await _prefsService.setNotificationsEnabled(value);
  }

  Future<void> _togglePriceAlerts(bool value) async {
    setState(() => _priceAlertsEnabled = value);
    await _prefsService.setPriceAlertsEnabled(value);
  }

  static void _emptyCallback() {}

  Future<void> _toggleSecurity(bool value) async {
    if (value && !_pinService.isPinSet) {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => const PinSetupScreen(onComplete: _emptyCallback, isChanging: false),
        ),
      );
      
      if (result != true && !_pinService.isPinSet) {
        setState(() => _securityEnabled = false);
        return;
      }
    } else if (!value) {
      await _pinService.removePin();
    }
    
    setState(() => _securityEnabled = value);
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      try {
        final authenticated = await _localAuth.authenticate(
          localizedReason: 'Enable biometric authentication',
          options: const AuthenticationOptions(biometricOnly: true),
        );
        if (!authenticated) return;
      } catch (_) {
        return;
      }
    }
    
    await _pinService.setBiometricEnabled(value);
    setState(() => _biometricEnabled = value);
  }

  String _formatLastUpdate(DateTime date) {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final themeProvider = Provider.of<DynamicThemeProvider>(context);
    final currencyService = Provider.of<CurrencyService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _buildSectionHeader(context, 'Account'),
          _buildSettingTile(
            context,
            icon: Icons.person_outline_rounded,
            title: 'Profile',
            subtitle: _prefsService.userName.isEmpty ? 'User' : _prefsService.userName,
            trailing: const Icon(Icons.chevron_right_rounded, size: 20),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ).then((_) => setState(() {})),
            isDark: isDark,
          ),
          
          const SizedBox(height: 24),
          
          _buildSectionHeader(context, 'Appearance'),
          _buildSettingTile(
            context,
            icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            title: 'Theme',
            subtitle: themeProvider.themeSetting.label, 
            trailing: const Icon(Icons.chevron_right_rounded, size: 20),
            onTap: () {
              // Simple toggle logic
              if (themeProvider.themeSetting == ThemeSetting.light) {
                themeProvider.setThemeSetting(ThemeSetting.dark);
              } else {
                themeProvider.setThemeSetting(ThemeSetting.light);
              }
            },
            isDark: isDark,
          ),
          
          const SizedBox(height: 24),
          
          _buildSectionHeader(context, 'Currency'),
          _buildSettingTile(
            context,
            icon: Icons.attach_money_rounded,
            title: 'Base Currency',
            subtitle: '${currencyService.baseCurrency.name} (${currencyService.baseCurrency.symbol})',
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<Currency>(
                value: currencyService.baseCurrency,
                onChanged: (Currency? newValue) {
                  if (newValue != null) {
                    currencyService.setBaseCurrency(newValue);
                  }
                },
                items: Currency.values.map((Currency currency) {
                  return DropdownMenuItem<Currency>(
                    value: currency,
                    child: Text(currency.code),
                  );
                }).toList(),
              ),
            ),
            isDark: isDark,
          ),
          _buildSettingTile(
            context,
            icon: Icons.refresh_rounded,
            title: 'Exchange Rates',
            subtitle: currencyService.lastUpdate != null
                ? 'Updated ${_formatLastUpdate(currencyService.lastUpdate!)}'
                : 'Tap to update',
            trailing: currencyService.isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => currencyService.fetchExchangeRates(),
                  ),
            isDark: isDark,
          ),

          const SizedBox(height: 24),
          
          _buildSectionHeader(context, 'Security'),
          _buildSettingTile(
            context,
            icon: Icons.lock_outline_rounded,
            title: 'App Lock',
            subtitle: 'Require PIN on launch',
            trailing: Switch(
              value: _securityEnabled,
              onChanged: _toggleSecurity,
              activeColor: colorScheme.primary,
            ),
            isDark: isDark,
          ),
          if (_securityEnabled && _canCheckBiometrics)
            _buildSettingTile(
              context,
              icon: Icons.fingerprint_rounded,
              title: 'Biometric Authentication',
              subtitle: 'Use fingerprint or face to unlock',
              trailing: Switch(
                value: _biometricEnabled,
                onChanged: _toggleBiometric,
                activeColor: colorScheme.primary,
              ),
              isDark: isDark,
            ),
          
          const SizedBox(height: 24),
          
          _buildSectionHeader(context, 'About'),
          _buildSettingTile(
            context,
            icon: Icons.info_outline_rounded,
            title: 'About Statch',
            subtitle: 'Version 2.0.0',
            trailing: const Icon(Icons.chevron_right_rounded, size: 20),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            ),
            isDark: isDark,
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
    required bool isDark,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark 
                      ? colorScheme.surfaceContainerHighest 
                      : colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 22, color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}