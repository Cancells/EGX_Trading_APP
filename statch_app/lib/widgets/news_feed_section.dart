import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../theme/app_theme.dart';

class NewsItem {
  final String source;
  final String title;
  final DateTime time;
  final String imageUrl;
  final String tag;

  NewsItem({
    required this.source,
    required this.title,
    required this.time,
    this.imageUrl = '',
    required this.tag,
  });
}

class NewsFeedSection extends StatelessWidget {
  const NewsFeedSection({super.key});

  // Mock Data - In V3, replace this with an RSS parser from Enterprise.press or EconomyPlus
  static final List<NewsItem> _news = [
    NewsItem(
      source: 'Enterprise',
      title: 'CBE keeps interest rates on hold for the third consecutive meeting',
      time: DateTime.now().subtract(const Duration(hours: 2)),
      tag: 'Economy',
    ),
    NewsItem(
      source: 'Economy Plus',
      title: 'EGX 30 breaks new resistance level led by CIB and Fawry',
      time: DateTime.now().subtract(const Duration(hours: 5)),
      tag: 'Market',
    ),
    NewsItem(
      source: 'Gold Bullion',
      title: '21K Gold prices stabilize after global spot drop',
      time: DateTime.now().subtract(const Duration(hours: 8)),
      tag: 'Gold',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Market Pulse',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                'See All',
                style: TextStyle(
                  color: AppTheme.robinhoodGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _news.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _buildNewsCard(context, _news[index]),
        ),
      ],
    );
  }

  Widget _buildNewsCard(BuildContext context, NewsItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon / Image Placeholder
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.robinhoodGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                item.source[0],
                style: const TextStyle(
                  color: AppTheme.robinhoodGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.source,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.grey.shade700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      timeago.format(item.time, locale: 'en_short'),
                      style: const TextStyle(color: AppTheme.mutedText, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}