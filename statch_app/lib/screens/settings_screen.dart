import 'package:flutter/material.dart';
import '../services/preferences_service.dart';
import '../theme/app_theme.dart';

/// Settings Screen with theme and notification toggles
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
  
  late bool _isDarkMode;
  late bool _notificationsEnabled;
  late bool _priceAlertsEnabled;

  @override
  void initState() {
    super.initState();
    _isDarkMode = _prefsService.isDarkMode;
    _notificationsEnabled = _prefsService.notificationsEnabled;
    _priceAlertsEnabled = _prefsService.priceAlertsEnabled;
  }

  Future<void> _toggleDarkMode(bool value) async {
    setState(() {
      _isDarkMode = value;
    });
    await _prefsService.setDarkMode(value);
    widget.onThemeToggle();
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() {
      _notificationsEnabled = value;
    });
    await _prefsService.setNotificationsEnabled(value);
  }

  Future<void> _togglePriceAlerts(bool value) async {
    setState(() {
      _priceAlertsEnabled = value;
    });
    await _prefsService.setPriceAlertsEnabled(value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
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
              activeColor: AppTheme.robinhoodGreen,
            ),
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
              activeColor: AppTheme.robinhoodGreen,
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
              activeColor: AppTheme.robinhoodGreen,
            ),
            isDark: isDark,
          ),
          
          const SizedBox(height: 24),
          
          // Market Section
          _buildSectionHeader(context, 'Market'),
          _buildSettingTile(
            context,
            icon: Icons.currency_exchange_rounded,
            title: 'Currency',
            subtitle: 'Egyptian Pound (EGP)',
            trailing: const Icon(Icons.chevron_right_rounded, size: 20),
            onTap: () {},
            isDark: isDark,
          ),
          _buildSettingTile(
            context,
            icon: Icons.access_time_rounded,
            title: 'Market Hours',
            subtitle: 'EGX: 10:00 AM - 2:30 PM',
            trailing: const Icon(Icons.chevron_right_rounded, size: 20),
            onTap: () {},
            isDark: isDark,
          ),
          
          const SizedBox(height: 24),
          
          // Security Section
          _buildSectionHeader(context, 'Security'),
          _buildSettingTile(
            context,
            icon: Icons.fingerprint_rounded,
            title: 'Biometric Lock',
            subtitle: 'Secure app with fingerprint',
            trailing: Switch(
              value: false,
              onChanged: (value) {},
              activeColor: AppTheme.robinhoodGreen,
            ),
            isDark: isDark,
          ),
          _buildSettingTile(
            context,
            icon: Icons.lock_outline_rounded,
            title: 'Change PIN',
            subtitle: 'Update your security PIN',
            trailing: const Icon(Icons.chevron_right_rounded, size: 20),
            onTap: () {},
            isDark: isDark,
          ),
          
          const SizedBox(height: 24),
          
          // Data Section
          _buildSectionHeader(context, 'Data'),
          _buildSettingTile(
            context,
            icon: Icons.cloud_sync_rounded,
            title: 'Sync Data',
            subtitle: 'Last synced: Just now',
            trailing: const Icon(Icons.chevron_right_rounded, size: 20),
            onTap: () {},
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
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
                  margin: const EdgeInsets.all(16),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.robinhoodGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
