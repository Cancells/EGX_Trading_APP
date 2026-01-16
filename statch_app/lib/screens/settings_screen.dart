import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; // Added for support email
import '../services/preferences_service.dart';
import '../services/pin_service.dart';
// import '../services/currency_service.dart'; // Removed Currency Service
import 'security_gate_screen.dart'; // Ensure this import exists or points to your PinSetupScreen location
import 'profile_screen.dart';
import 'legal_screen.dart';
import 'about_screen.dart'; // Ensure you have this or remove the import

/// Settings Screen with theme and security options (Currency removed)
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Using PreferencesService from context or instance depending on your setup.
  // Assuming singleton usage based on your previous code structure.
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
    // Initialize services access
    final prefs = Provider.of<PreferencesService>(context, listen: false);
    _prefsService = prefs;
    
    // Load initial state
    _notificationsEnabled = prefs.notificationsEnabled;
    _priceAlertsEnabled = prefs.priceAlertsEnabled;
    _securityEnabled = prefs.isPinEnabled; // Updated to match PreferencesService naming if needed
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

  Future<void> _toggleSecurity(bool value) async {
    if (value && !_prefsService.isPinEnabled) {
      // Need to set up PIN first. Using generic PinSetupScreen route.
      // Make sure PinSetupScreen is imported and available.
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => const PinSetupScreen(isChanging: false),
        ),
      );
      
      // If user cancelled PIN setup, don't enable security
      if (result != true && !_prefsService.isPinEnabled) {
        setState(() => _securityEnabled = false);
        return;
      }
    } else if (!value) {
      // Disabling security
      await _prefsService.disablePin();
    }
    
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

  // Simplified Theme Picker that respects System Settings (Material You standard)
  void _showThemePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Appearance',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Theme follows your system settings',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              
              // Simple info tile since we are using DynamicColorBuilder
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.brightness_auto_rounded,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                title: const Text('System Default'),
                subtitle: const Text('Uses device Dark Mode & Colors'),
                trailing: Icon(
                  Icons.check_circle_rounded,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'To change the theme, please adjust your device Display settings.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                ),
              ),
              const SizedBox(height: 32),
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
        builder: (context) => const PinSetupScreen(isChanging: true),
      ),
    ).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
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
            subtitle: _prefsService.userName.isEmpty ? 'User' : _prefsService.userName,
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
            icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            title: 'Theme',
            subtitle: 'System (Dynamic)',
            trailing: const Icon(Icons.chevron_right_rounded, size: 20),
            onTap: _showThemePicker,
            isDark: isDark,
          ),
          
          const SizedBox(height: 24),
          
          // Currency Section REMOVED as requested
          
          // Security Section
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
          if (_securityEnabled)
            _buildSettingTile(
              context,
              icon: Icons.pin_rounded,
              title: _prefsService.isPinEnabled ? 'Change PIN' : 'Set PIN',
              subtitle: _prefsService.isPinEnabled ? 'Update your 4-digit PIN' : 'Create a 4-digit PIN',
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
              activeColor: colorScheme.primary,
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
              activeColor: colorScheme.primary,
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
            icon: Icons.description_outlined,
            title: 'Legal',
            subtitle: 'Terms, Privacy & Service Usage',
            trailing: const Icon(Icons.chevron_right_rounded, size: 20),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LegalScreen()),
            ),
            isDark: isDark,
          ),
          
          // Contact Support
          _buildSettingTile(
            context,
            icon: Icons.mail_outline_rounded,
            title: 'Contact Support',
            subtitle: 'Help & Feedback',
            trailing: const Icon(Icons.chevron_right_rounded, size: 20),
            onTap: () async {
              final Uri emailLaunchUri = Uri(
                scheme: 'mailto',
                path: 'support@statch.com',
                queryParameters: {'subject': 'Statch App Support'},
              );
              if (await canLaunchUrl(emailLaunchUri)) {
                await launchUrl(emailLaunchUri);
              }
            },
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
                  // Use dynamic colors instead of hardcoded AppTheme
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

// Ensure PinSetupScreen is available if not imported from another file
// This is a placeholder bridge if the original pin screen file is named differently
class PinSetupScreen extends StatelessWidget {
  final bool isChanging;
  const PinSetupScreen({super.key, this.isChanging = false});

  @override
  Widget build(BuildContext context) {
    // If you have a real PinScreen, return it here.
    // Otherwise this is a placeholder to prevent build errors.
    return Scaffold(
      appBar: AppBar(title: Text(isChanging ? 'Change PIN' : 'Set PIN')),
      body: const Center(child: Text('PIN Setup Screen')),
    );
  }
}