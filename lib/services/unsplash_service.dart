import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config.dart';

// 키워드 기반 패션/메이크업 이미지 조달 (Unsplash API)
// 무료 50req/시간, 상업 사용 OK, Attribution 필수 (결과지 하단 처리)
class UnsplashService {
  static final Map<String, String?> _cache = {};

  static Future<String?> fetchImageUrl(String query) async {
    final key = query.trim();
    if (key.isEmpty) return null;
    if (_cache.containsKey(key)) return _cache[key];
    if (kUnsplashAccessKey.isEmpty ||
        kUnsplashAccessKey == 'YOUR_UNSPLASH_KEY_HERE') {
      return null;
    }
    try {
      final encoded = Uri.encodeComponent(key);
      final uri = Uri.parse(
        'https://api.unsplash.com/search/photos'
        '?query=$encoded&per_page=1&orientation=portrait',
      );
      final res = await http.get(uri, headers: {
        'Authorization': 'Client-ID $kUnsplashAccessKey',
        'Accept-Version': 'v1',
      }).timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) {
        debugPrint('Unsplash error ${res.statusCode}: ${res.body}');
        return null;
      }
      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final results = body['results'] as List?;
      if (results == null || results.isEmpty) return null;
      final first = results.first as Map<String, dynamic>;
      final urls = first['urls'] as Map<String, dynamic>?;
      final url = urls?['small']?.toString() ?? urls?['regular']?.toString();
      _cache[key] = url;
      return url;
    } catch (e) {
      debugPrint('Unsplash fetch error for "$query": $e');
      return null;
    }
  }
}
