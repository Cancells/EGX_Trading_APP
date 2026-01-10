import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/statch_logo.dart';
import 'legal_screen.dart';

/// About Screen with app version and credits
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            
            // App Logo
            Hero(
              tag: 'statch_logo',
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.robinhoodGreen.withValues(alpha: 0.2),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const AnimatedStatchLogo(size: 80),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // App Name
            Text(
              'Statch',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Version
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.robinhoodGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Version 2.0.0',
                style: TextStyle(
                  color: AppTheme.robinhoodGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Description
            Text(
              'Egyptian Market Trading App',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.mutedText,
              ),
            ),
            
            const SizedBox(height: 48),
            
            // Features Section
            _buildSection(
              context,
              title: 'Features',
              items: [
                const _FeatureItem(
                  icon: Icons.show_chart_rounded,
                  title: 'Real-time Charts',
                  description: 'Track EGX 30 and 60+ Egyptian stocks',
                ),
                const _FeatureItem(
                  icon: Icons.workspace_premium_rounded,
                  title: 'Egyptian Gold Prices',
                  description: 'Live 24K, 21K, 18K & Gold Pound prices',
                ),
                const _FeatureItem(
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'Portfolio Tracking',
                  description: 'Track stocks & gold investments with P/L',
                ),
                const _FeatureItem(
                  icon: Icons.construction_rounded,
                  title: 'Workmanship Toggle',
                  description: 'Calculate shop buying prices',
                ),
                const _FeatureItem(
                  icon: Icons.palette_rounded,
                  title: 'Themes',
                  description: 'Light, Dark, and Material You support',
                ),
              ],
              isDark: isDark,
            ),
            
            const SizedBox(height: 32),
            
            // Credits Section
            _buildCreditsCard(context, isDark),
            
            const SizedBox(height: 32),
            
            // Legal Section
            _buildSection(
              context,
              title: 'Legal',
              items: [
                _LegalItem(
                  title: 'Terms & Conditions',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LegalScreen()),
                  ),
                ),
                _LegalItem(
                  title: 'Service Usage & Data Delay',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LegalScreen()),
                  ),
                ),
                _LegalItem(
                  title: 'Licenses',
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'Statch',
                    applicationVersion: '2.0.0',
                  ),
                ),
              ],
              isDark: isDark,
            ),
            
            const SizedBox(height: 48),
            
            // Footer
            Text(
              '© 2026 Statch. All rights reserved.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.mutedText,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Made with ❤️ for Egyptian Investors',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.mutedText,
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> items,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.mutedText,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final isLast = entry.key == items.length - 1;
              return Column(
                children: [
                  entry.value,
                  if (!isLast)
                    Divider(
                      height: 1,
                      indent: 60,
                      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCreditsCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.robinhoodGreen.withValues(alpha: 0.15),
            AppTheme.robinhoodGreen.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.robinhoodGreen.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.robinhoodGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.code_rounded,
                  color: AppTheme.robinhoodGreen,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Built with Flutter',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Powered by Dart & Material 3',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(context, 'Charts', 'fl_chart'),
              _buildStatItem(context, 'Storage', 'shared_preferences'),
              _buildStatItem(context, 'Fonts', 'google_fonts'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.mutedText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.robinhoodGreen,
          ),
        ),
      ],
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(
            icon,
            size: 24,
            color: AppTheme.robinhoodGreen,
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
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.mutedText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _LegalItem({
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.description_outlined, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20),
          ],
        ),
      ),
    );
  }
}
