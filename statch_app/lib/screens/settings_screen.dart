import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import '../services/preferences_service.dart';
import '../services/pin_service.dart';
import '../services/currency_service.dart';
import '../theme/app_theme.dart';
import '../theme/dynamic_theme.dart';
import 'security_gate_screen.dart';
import 'profile_screen.dart';
import 'about_screen.dart';

/// Settings Screen with theme, security, and currency options
class SettingsScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;

  const SettingsScreen({
    super.key,
    required this.onThemeToggle,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final PreferencesService _prefsService = PreferencesService();
  final PinService _pinService = PinService();
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  late bool _isDarkMode;
  late bool _notificationsEnabled;
  late bool _priceAlertsEnabled;
  late bool _securityEnabled;
  late bool _biometricEnabled;
  bool _canCheckBiometrics = false;

  @override
  void initState() {
    super.initState();
    _isDarkMode = _prefsService.isDarkMode;
    _notificationsEnabled = _prefsService.notificationsEnabled;
    _priceAlertsEnabled = _prefsService.priceAlertsEnabled;
    _securityEnabled = _pinService.isSecurityEnabled;
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

  Future<void> _toggleDarkMode(bool value) async {
    setState(() => _isDarkMode = value);
    await _prefsService.setDarkMode(value);
    widget.onThemeToggle();
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    await _prefsService.setNotificationsEnabled(value);
  }

  Future<void> _togglePriceAlerts(bool value) async {
    setState(() => _priceAlertsEnabled = value);
    await _prefsService.setPriceAlertsEnabled(value);
  }

  Future<void> _toggleSecurity(bool value) async {
    if (value && !_pinService.isPinSet) {
      // Need to set up PIN first
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => PinSetupScreen(
            onComplete: () => Navigator.pop(context, true),
          ),
        ),
      );
      if (result != true) return;
    }
    
    await _pinService.setSecurityEnabled(value);
    setState(() => _securityEnabled = value);
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      // Verify biometric first
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

  void _showCurrencyPicker() {
    final currencyService = context.read<CurrencyService>();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Select Currency',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'All values will be converted to selected currency',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.mutedText,
                ),
              ),
              const SizedBox(height: 16),
              ...Currency.values.map((currency) {
                final isSelected = currency == currencyService.baseCurrency;
                return ListTile(
                  onTap: () {
                    currencyService.setBaseCurrency(currency);
                    Navigator.pop(context);
                  },
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.robinhoodGreen.withValues(alpha: 0.1)
                          : (isDark ? AppTheme.darkCard : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        currency.symbol,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? AppTheme.robinhoodGreen
                              : null,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    currency.name,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppTheme.robinhoodGreen : null,
                    ),
                  ),
                  subtitle: Text(currency.code),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: AppTheme.robinhoodGreen,
                        )
                      : null,
                );
              }),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _setupPin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PinSetupScreen(
          onComplete: () {
            Navigator.pop(context);
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.white),
                    SizedBox(width: 12),
                    Text('PIN updated successfully'),
                  ],
                ),
                backgroundColor: AppTheme.robinhoodGreen,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyService = context.watch<CurrencyService>();
    final themeProvider = context.watch<DynamicThemeProvider>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // Profile Section
          _buildSectionHeader(context, 'Account'),
          _buildSettingTile(
            context,
            icon: Icons.person_outline_rounded,
            title: 'Profile',
            subtitle: _prefsService.userName,
            trailing: const Icon(Icons.chevron_right_rounded, size: 20),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ).then((_) => setState(() {})),
            isDark: isDark,
          ),
          
          const SizedBox(height: 24),
          
          // Appearance Section
          _buildSectionHeader(context, 'Appearance'),
          _buildSettingTile(
            context,
            icon: Icons.dark_mode_rounded,
            title: 'Dark Mode',
            subtitle: 'Use dark theme',
            trailing: Switch(
              value: _isDarkMode,
              onChanged: _toggleDarkMode,
              activeTrackColor: AppTheme.robinhoodGreen,
            ),
            isDark: isDark,
          ),
          if (themeProvider.supportsDynamicColor)
            _buildSettingTile(
              context,
              icon: Icons.palette_outlined,
              title: 'Dynamic Colors',
              subtitle: 'Use Material You wallpaper colors',
              trailing: Switch(
                value: themeProvider.useDynamicColor,
                onChanged: (value) => themeProvider.toggleDynamicColor(value),
                activeTrackColor: AppTheme.robinhoodGreen,
              ),
              isDark: isDark,
            ),
          
          const SizedBox(height: 24),
          
          // Currency Section
          _buildSectionHeader(context, 'Currency'),
          _buildSettingTile(
            context,
            icon: Icons.currency_exchange_rounded,
            title: 'Base Currency',
            subtitle: '${currencyService.baseCurrency.name} (${currencyService.baseCurrency.symbol})',
            trailing: const Icon(Icons.chevron_right_rounded, size: 20),
            onTap: _showCurrencyPicker,
            isDark: isDark,
          ),
          _buildSettingTile(
            context,
            icon: Icons.sync_rounded,
            title: 'Exchange Rates',
            subtitle: currencyService.lastUpdate != null
                ? 'Updated ${_formatLastUpdate(currencyService.lastUpdate!)}'
                : 'Not yet updated',
            trailing: currencyService.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    onPressed: () => currencyService.fetchExchangeRates(),
                  ),
            isDark: isDark,
          ),
          
          const SizedBox(height: 24),
          
          // Security Section
          _buildSectionHeader(context, 'Security'),
          _buildSettingTile(
            context,
            icon: Icons.lock_outline_rounded,
            title: 'App Lock',
            subtitle: 'Require authentication on launch',
            trailing: Switch(
              value: _securityEnabled,
              onChanged: _toggleSecurity,
              activeTrackColor: AppTheme.robinhoodGreen,
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
                activeTrackColor: AppTheme.robinhoodGreen,
              ),
              isDark: isDark,
            ),
          if (_securityEnabled)
            _buildSettingTile(
              context,
              icon: Icons.pin_rounded,
              title: _pinService.isPinSet ? 'Change PIN' : 'Set PIN',
              subtitle: _pinService.isPinSet ? 'Update your 4-digit PIN' : 'Create a 4-digit PIN',
              trailing: const Icon(Icons.chevron_right_rounded, size: 20),
              onTap: _setupPin,
              isDark: isDark,
            ),
          
          const SizedBox(height: 24),
          
          // Notifications Section
          _buildSectionHeader(context, 'Notifications'),
          _buildSettingTile(
            context,
            icon: Icons.notifications_outlined,
            title: 'Push Notifications',
            subtitle: 'Receive market updates',
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: _toggleNotifications,
              activeTrackColor: AppTheme.robinhoodGreen,
            ),
            isDark: isDark,
          ),
          _buildSettingTile(
            context,
            icon: Icons.trending_up_rounded,
            title: 'Price Alerts',
            subtitle: 'Get notified on price changes',
            trailing: Switch(
              value: _priceAlertsEnabled,
              onChanged: _togglePriceAlerts,
              activeTrackColor: AppTheme.robinhoodGreen,
            ),
            isDark: isDark,
          ),
          
          const SizedBox(height: 24),
          
          // About Section
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
          _buildSettingTile(
            context,
            icon: Icons.delete_outline_rounded,
            title: 'Clear Cache',
            subtitle: 'Free up storage space',
            trailing: const Icon(Icons.chevron_right_rounded, size: 20),
            onTap: () => _showClearCacheDialog(context),
            isDark: isDark,
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  String _formatLastUpdate(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppTheme.mutedText,
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
                  color: isDark ? AppTheme.darkCard : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 22),
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
                        color: AppTheme.mutedText,
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

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Cache'),
        content: const Text(
          'This will clear all cached data. Your personal settings will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.white),
                      SizedBox(width: 12),
                      Text('Cache cleared successfully'),
                    ],
                  ),
                  backgroundColor: AppTheme.robinhoodGreen,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.robinhoodGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
