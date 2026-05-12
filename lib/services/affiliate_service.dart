import 'package:cloud_firestore/cloud_firestore.dart';

class AffiliateService {
  static final _db = FirebaseFirestore.instance;
  static final Map<String, Map<String, String>> _cache = {};

  // 제품명으로 URL 조회
  static Future<String> getUrl(String productName,
      {String platform = 'coupang'}) async {
    if (_cache.containsKey(productName)) {
      return _cache[productName]?[platform] ?? '';
    }

    try {
      final doc = await _db
          .collection('affiliate_products')
          .doc(_toDocId(productName))
          .get();

      if (doc.exists) {
        final data = Map<String, String>.from(doc.data() ?? {});
        _cache[productName] = data;
        return data[platform] ?? '';
      }
    } catch (e) {
      // 조회 실패 시 빈 문자열 반환 — 앱 동작에 영향 없음
    }
    return '';
  }

  // 전체 제품 목록 프리로드 (LoadingScreen 진입 시 1회 호출)
  static Future<void> preload() async {
    try {
      final snapshot = await _db.collection('affiliate_products').get();
      for (final doc in snapshot.docs) {
        _cache[doc.id] = Map<String, String>.from(doc.data());
      }
    } catch (e) {
      // 프리로드 실패 시 개별 조회로 폴백
    }
  }

  static String _toDocId(String name) {
    return name.replaceAll(' ', '_').replaceAll('/', '_');
  }
}
