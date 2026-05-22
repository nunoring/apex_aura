import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

// 셀럽 이름 → 사진 URL 조달 (Wikipedia 기반, 무료 + 상업 사용 OK)
// 라이선스: 위키미디어 커먼즈 CC BY-SA. Attribution 필수 (결과지 하단 표기).
// 1차: 한국어 위키 REST summary API
// 2차: 한국어 위키 검색 API (disambiguation 대응, 예: "윈터" → "윈터 (가수)")
// 3차: 자체 asset DB (assets/celebs/{name}.jpg)
class TmdbService {
  static final Map<String, String?> _cache = {};
  static Set<String>? _assetIndex;

  static Future<String?> fetchPhotoUrl(String name) async {
    final key = name.trim();
    if (key.isEmpty) return null;
    if (_cache.containsKey(key)) return _cache[key];

    // 1. 위키 summary 직접
    final direct = await _wikiSummary(key);
    if (direct != null) return _cache[key] = direct;

    // 2. 위키 검색 → 첫 결과로 summary 재시도
    final searched = await _wikiSearchThenSummary(key);
    if (searched != null) return _cache[key] = searched;

    // 3. 자체 asset
    final asset = await _fetchFromAssets(key);
    return _cache[key] = asset;
  }

  static Future<String?> _wikiSummary(String title) async {
    try {
      final encoded = Uri.encodeComponent(title);
      final uri = Uri.parse('https://ko.wikipedia.org/api/rest_v1/page/summary/$encoded');
      final res = await http.get(uri, headers: {
        'User-Agent': 'ApexAura/1.0 (https://apexaura.app; contact@apexaura.app)',
      }).timeout(const Duration(seconds: 4));
      if (res.statusCode != 200) return null;
      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final type = body['type']?.toString();
      if (type == 'disambiguation') return null;
      final thumbnail = body['thumbnail'] as Map<String, dynamic>?;
      final source = thumbnail?['source']?.toString();
      if (source == null || source.isEmpty) return null;
      // 더 큰 사이즈로 교체 (330px → 500px)
      return source.replaceAll(RegExp(r'/\d+px-'), '/500px-');
    } catch (e) {
      debugPrint('wiki summary error for "$title": $e');
      return null;
    }
  }

  static Future<String?> _wikiSearchThenSummary(String name) async {
    try {
      final encoded = Uri.encodeComponent(name);
      final uri = Uri.parse(
        'https://ko.wikipedia.org/w/rest.php/v1/search/page?q=$encoded&limit=3',
      );
      final res = await http.get(uri, headers: {
        'User-Agent': 'ApexAura/1.0',
      }).timeout(const Duration(seconds: 4));
      if (res.statusCode != 200) return null;
      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final pages = body['pages'] as List?;
      if (pages == null || pages.isEmpty) return null;
      for (final page in pages) {
        final title = (page as Map)['key']?.toString() ?? page['title']?.toString();
        if (title == null) continue;
        final url = await _wikiSummary(title);
        if (url != null) return url;
      }
      return null;
    } catch (e) {
      debugPrint('wiki search error for "$name": $e');
      return null;
    }
  }

  static Future<String?> _fetchFromAssets(String name) async {
    _assetIndex ??= await _loadAssetIndex();
    final candidate = 'assets/celebs/$name.jpg';
    if (_assetIndex!.contains(candidate)) return candidate;
    return null;
  }

  static Future<Set<String>> _loadAssetIndex() async {
    try {
      final manifest = await rootBundle.loadString('AssetManifest.json');
      final map = jsonDecode(manifest) as Map<String, dynamic>;
      return map.keys.where((k) => k.startsWith('assets/celebs/')).toSet();
    } catch (_) {
      return <String>{};
    }
  }
}
