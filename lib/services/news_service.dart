import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

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
  // Default Business News
  static const String _defaultRss = 'https://news.google.com/rss/topics/CAAqJggBCiCPASowCAqTCPtCQkFTRWdvSmMzUnZjbmt0TXpZd1NoUkxpUVN2Y0hSc2N4UUNZWGM1ZnBjKgoCChYI/sections/CAQiT0NCQVNTRWdvSmMzUnZjbmt0TXpZd1NoUkxpUVN2Y0hSc2N4UUNZWGM1ZnBjKgoCChYIBAosQ0JBU1F3b0pjM1J2Y25rdE16WXdTaFJMSVNCQ2hJSUVDbng1?hl=en-EG&gl=EG&ceid=EG%3Aen';

  Future<List<NewsItem>> fetchNews({String? query}) async {
    try {
      // 8. Dynamic Query for specific stock news
      String url = _defaultRss;
      if (query != null && query.isNotEmpty) {
        final encodedQuery = Uri.encodeComponent('$query stock news');
        url = 'https://news.google.com/rss/search?q=$encodedQuery&hl=en-EG&gl=EG&ceid=EG%3Aen';
      }

      final response = await http.get(Uri.parse(url));
      
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
        if (items.length >= 10) break; 

        final titleFull = node.findElements('title').single.innerText;
        final link = node.findElements('link').single.innerText;
        
        String title = titleFull;
        String source = 'Market News';
        
        if (title.contains(' - ')) {
          final parts = title.split(' - ');
          source = parts.last;
          title = parts.take(parts.length - 1).join(' - ');
        }

        items.add(NewsItem(
          title: title,
          source: source,
          time: DateTime.now(), // Simplified
          url: link,
        ));
      }
    } catch (e) {
      print('XML Parsing Error: $e');
    }
    return items;
  }
}