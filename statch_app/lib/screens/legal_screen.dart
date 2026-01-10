import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Legal View Screen containing About, Terms & Conditions, and Service Usage
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Legal'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildAboutCard(context, isDark),
          const SizedBox(height: 20),
          _buildTermsCard(context, isDark),
          const SizedBox(height: 20),
          _buildServiceUsageCard(context, isDark),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context, bool isDark) {
    return _LegalCard(
      isDark: isDark,
      icon: Icons.info_outline_rounded,
      title: 'About Statch',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.robinhoodGreen,
                      AppTheme.robinhoodGreen.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Statch',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Version 2.0.0',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.mutedText,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Our Mission',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Statch is designed to empower Egyptian investors with real-time market insights, '
            'comprehensive portfolio tracking, and live gold price updates. Our goal is to make '
            'financial information accessible, beautiful, and easy to understand.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.mutedText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Features',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildFeatureItem(context, '• Real-time EGX 30 index tracking'),
          _buildFeatureItem(context, '• Live Egyptian gold prices (24K, 21K, 18K, Gold Pound)'),
          _buildFeatureItem(context, '• Portfolio management with P/L tracking'),
          _buildFeatureItem(context, '• Workmanship calculator for gold buying'),
          _buildFeatureItem(context, '• Multi-currency support (EGP, USD, EUR)'),
          _buildFeatureItem(context, '• Biometric security protection'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.robinhoodGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.favorite_rounded,
                  color: AppTheme.robinhoodGreen,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Made with care for Egyptian investors',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.robinhoodGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppTheme.mutedText,
        ),
      ),
    );
  }

  Widget _buildTermsCard(BuildContext context, bool isDark) {
    return _LegalCard(
      isDark: isDark,
      icon: Icons.description_outlined,
      title: 'Terms & Conditions',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTermsSection(
            context,
            '1. Acceptance of Terms',
            'By downloading, accessing, or using Statch, you agree to be bound by these Terms and Conditions. '
            'If you do not agree to these terms, please do not use the application.',
          ),
          _buildTermsSection(
            context,
            '2. Disclaimer of Investment Advice',
            'Statch provides market data and portfolio tracking tools for informational purposes only. '
            'The information provided does not constitute investment advice, financial advice, trading advice, '
            'or any other sort of advice. You should not treat any of the app\'s content as such. '
            'We do not recommend that any securities be bought, sold, or held by you.',
          ),
          _buildTermsSection(
            context,
            '3. Limitation of Liability',
            'Statch and its developers shall not be liable for any losses, damages, or claims arising from: '
            '(a) your use of or reliance on the information provided; '
            '(b) any investment decisions you make; '
            '(c) technical issues, delays, or interruptions in service; '
            '(d) accuracy of market data or gold prices displayed.',
          ),
          _buildTermsSection(
            context,
            '4. Data Usage & Privacy',
            'We collect minimal data necessary for app functionality: '
            '• Portfolio data is stored locally on your device '
            '• No personal financial data is transmitted to external servers '
            '• Settings and preferences are stored locally '
            '• Market data is fetched from third-party providers',
          ),
          _buildTermsSection(
            context,
            '5. Third-Party Data',
            'Market data, stock prices, and exchange rates are provided by third-party services. '
            'We do not guarantee the accuracy, completeness, or timeliness of this data.',
          ),
          _buildTermsSection(
            context,
            '6. Modifications',
            'We reserve the right to modify these terms at any time. Continued use of the app '
            'after changes constitutes acceptance of the new terms.',
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.robinhoodRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: AppTheme.robinhoodRed,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Investment involves risk. Past performance is not indicative of future results. '
                    'Always do your own research before making investment decisions.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.robinhoodRed,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.mutedText,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceUsageCard(BuildContext context, bool isDark) {
    return _LegalCard(
      isDark: isDark,
      icon: Icons.timer_outlined,
      title: 'Service Usage & Data Delay',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.goldPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.goldPrimary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.goldPrimary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.schedule_rounded,
                    color: AppTheme.goldPrimary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '15-Minute Data Delay',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppTheme.goldPrimary : const Color(0xFF8B6914),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Market data may be delayed by up to 15 minutes',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Important Information',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            context,
            Icons.show_chart_rounded,
            'Stock Prices',
            'EGX stock prices are fetched from financial data providers and may experience '
            'delays of up to 15 minutes from real-time market prices.',
          ),
          _buildInfoItem(
            context,
            Icons.workspace_premium_rounded,
            'Gold Prices',
            'Gold prices are calculated based on international gold futures (GC=F) and '
            'USD/EGP exchange rates. Prices update every 10 seconds when the app is active.',
          ),
          _buildInfoItem(
            context,
            Icons.currency_exchange_rounded,
            'Exchange Rates',
            'Currency exchange rates are updated every 30 minutes from public APIs. '
            'Rates may differ slightly from bank rates.',
          ),
          _buildInfoItem(
            context,
            Icons.security_rounded,
            'Trading Hours',
            'The Egyptian Stock Exchange operates Sunday through Thursday, 10:00 AM to 2:30 PM EET. '
            'Data shown outside these hours reflects the last trading session.',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.05) 
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppTheme.mutedText,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'For real-time trading, please use your broker\'s official platform.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.mutedText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.robinhoodGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.mutedText,
                    height: 1.4,
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

/// Reusable legal card widget
class _LegalCard extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String title;
  final Widget child;

  const _LegalCard({
    required this.isDark,
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.robinhoodGreen, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
