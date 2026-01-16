import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/news_service.dart';

class NewsFeedSection extends StatefulWidget {
  final String? query; // Added query parameter
  
  const NewsFeedSection({super.key, this.query});

  @override
  State<NewsFeedSection> createState() => _NewsFeedSectionState();
}

class _NewsFeedSectionState extends State<NewsFeedSection> {
  final NewsService _newsService = NewsService();
  late Future<List<NewsItem>> _newsFuture;

  @override
  void initState() {
    super.initState();
    _newsFuture = _newsService.fetchNews(query: widget.query);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<NewsItem>>(
      future: _newsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('No recent news available.');
        }

        final news = snapshot.data!;
        
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: news.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _buildNewsCard(context, news[index]),
        );
      },
    );
  }

  Widget _buildNewsCard(BuildContext context, NewsItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.source,
            style: const TextStyle(fontSize: 12, color: AppTheme.robinhoodGreen, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            item.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}