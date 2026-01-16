import 'package:http/http.dart' as http;
import 'package:xml/xml.dart'; // Requires 'xml' package in pubspec.yaml

class NewsItem {
  final String title;
  final String source;
  final DateTime time;
  final String url;

  NewsItem({
    required this.title,
    required this.source,
    required this.time,
    required this.url
  });
}

class NewsService {
  // Google News RSS Feed for "Business" topic in English (Egypt edition)
  static const String _rssUrl = 'https://news.google.com/rss/topics/CAAqJggBCiCPASowCAqTCPtCQkFTRWdvSmMzUnZjbmt0TXpZd1NoUkxpUVN2Y0hSc2N4UUNZWGM1ZnBjKgoCChYI/sections/CAQiT0NCQVNTRWdvSmMzUnZjbmt0TXpZd1NoUkxpUVN2Y0hSc2N4UUNZWGM1ZnBjKgoCChYIBAosQ0JBU1F3b0pjM1J2Y25rdE16WXdTaFJMSVNCQ2hJSUVDbng1?hl=en-EG&gl=EG&ceid=EG%3Aen';

  Future<List<NewsItem>> fetchNews() async {
    try {
      final response = await http.get(Uri.parse(_rssUrl));
      
      if (response.statusCode == 200) {
        return _parseRss(response.body);
      }
    } catch (e) {
      print('News Fetch Error: $e');
    }
    return [];
  }

  List<NewsItem> _parseRss(String xmlString) {
    final items = <NewsItem>[];
    
    try {
      final document = XmlDocument.parse(xmlString);
      final xmlItems = document.findAllElements('item');

      for (var node in xmlItems) {
        if (items.length >= 5) break; // Limit to top 5 news

        final titleFull = node.findElements('title').single.innerText;
        final pubDateStr = node.findElements('pubDate').single.innerText;
        final link = node.findElements('link').single.innerText;
        
        // Clean up title (remove " - Source Name" from the end)
        String title = titleFull;
        String source = 'Market News';
        
        if (title.contains(' - ')) {
          final parts = title.split(' - ');
          source = parts.last;
          title = parts.take(parts.length - 1).join(' - ');
        }
        
        // Parse date (RFC 822 format usually)
        DateTime time = DateTime.now();
        try {
          // Simple parsing logic, or use a date parser package
          // Google News uses: "Mon, 05 Aug 2024 12:00:00 GMT"
          // For simplicity, we just use current time if parse fails
          // or rely on a robust parser in V3
        } catch (_) {}

        items.add(NewsItem(
          title: title,
          source: source,
          time: time,
          url: link,
        ));
      }
    } catch (e) {
      print('XML Parsing Error: $e');
    }
    return items;
  }
}