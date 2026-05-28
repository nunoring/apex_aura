import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryService {
  static const _key = 'analysis_history_v1';
  static const _maxRecords = 20;

  static Future<String?> save({
    required String currentType,
    required String targetType,
    required String gender,
    required File imageFile,
    required Map<String, dynamic> analysisResult,
    required Map<String, dynamic> faceData,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dir = await getApplicationDocumentsDirectory();
      final histDir = Directory('${dir.path}/history');
      await histDir.create(recursive: true);

      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final thumbPath = '${histDir.path}/$id.jpg';
      await imageFile.copy(thumbPath);

      final score = _computeScore(faceData, analysisResult);
      final tier = _tierFromScore(score);

      final record = {
        'id': id,
        'date': DateTime.now().toIso8601String(),
        'currentType': currentType,
        'targetType': targetType,
        'gender': gender,
        'score': score,
        'tier': tier,
        'imagePath': thumbPath,
        'analysisResult': analysisResult,
        'faceData': faceData,
      };

      final raw = prefs.getString(_key);
      final list = raw != null ? jsonDecode(raw) as List : [];
      list.insert(0, record);
      if (list.length > _maxRecords) list.removeRange(_maxRecords, list.length);
      await prefs.setString(_key, jsonEncode(list));
      return id;
    } catch (_) {
      // 저장 실패 시 앱 흐름에 영향 없도록 무시
      return null;
    }
  }

  // styling(makeup/fashion)이 백그라운드로 늦게 도착 → 기존 레코드에 병합
  // (저장은 메인 결과만 먼저 됨 → 도착 후 이걸로 갱신해야 과거 기록에도 보임)
  static Future<void> updateStyling(String id,
      {List<dynamic>? makeupSteps, List<dynamic>? fashionLooks}) async {
    if (makeupSteps == null && fashionLooks == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return;
      final list = jsonDecode(raw) as List;
      for (final rec in list) {
        if ((rec as Map)['id'] == id) {
          final ar = Map<String, dynamic>.from(
              rec['analysisResult'] as Map? ?? {});
          if (makeupSteps != null) ar['makeup_steps'] = makeupSteps;
          if (fashionLooks != null) ar['fashion_looks'] = fashionLooks;
          rec['analysisResult'] = ar;
          break;
        }
      }
      await prefs.setString(_key, jsonEncode(list));
    } catch (_) {}
  }

  static Future<List<Map<String, dynamic>>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return [];
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => Map<String, dynamic>.from(e as Map))
          .where((e) => File(e['imagePath'] as String).existsSync())
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> delete(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return;
      final list = jsonDecode(raw) as List;
      final record = list.firstWhere(
        (e) => (e as Map)['id'] == id,
        orElse: () => null,
      );
      if (record != null) {
        final path = (record as Map)['imagePath'] as String;
        final f = File(path);
        if (f.existsSync()) await f.delete();
      }
      list.removeWhere((e) => (e as Map)['id'] == id);
      await prefs.setString(_key, jsonEncode(list));
    } catch (_) {}
  }

  // ResultScreen의 _abilityScores 로직과 동일하게 유지
  static int _computeScore(
      Map<String, dynamic> faceData, Map<String, dynamic> analysisResult) {
    final goldenRatio =
        double.tryParse(faceData['golden_ratio']?.toString() ?? '0') ?? 0.0;
    final faceRatio =
        double.tryParse(faceData['face_ratio']?.toString() ?? '0') ?? 0.0;
    final eyeAngle =
        double.tryParse(faceData['eye_angle']?.toString() ?? '0') ?? 0.0;
    final eyeGap =
        double.tryParse(faceData['eye_gap_ratio']?.toString() ?? '0') ?? 0.0;
    final skinRaw =
        (analysisResult['skinAnalysis'] as Map<String, dynamic>?)?['overall']
            ?.toString() ??
            '보통';

    final goldenScore =
        ((1.0 - ((goldenRatio - 0.33).abs() / 0.15).clamp(0.0, 1.0)) * 55 +
                    35)
                .round()
                .clamp(30, 100);
    final shapeScore =
        ((1.0 - ((faceRatio - 0.75).abs() / 0.25).clamp(0.0, 1.0)) * 55 + 35)
            .round()
            .clamp(30, 100);
    final eyeAbs = (eyeAngle.abs() / 6.0).clamp(0.0, 1.0);
    final eyeIdeal =
        (1.0 - ((eyeAngle.abs() - 3.0).abs() / 5.0).clamp(0.0, 1.0));
    final eyeScore =
        ((eyeAbs * 0.4 + eyeIdeal * 0.6) * 55 + 38).round().clamp(30, 100);
    final gapScore =
        ((1.0 - ((eyeGap - 0.40).abs() / 0.15).clamp(0.0, 1.0)) * 50 + 38)
            .round()
            .clamp(30, 100);
    final skinScore =
        skinRaw == '좋음' ? 88 : skinRaw == '관리필요' ? 50 : 68;

    return ((goldenScore + shapeScore + eyeScore + gapScore + skinScore) / 5)
        .round();
  }

  static String _tierFromScore(int score) {
    if (score >= 82) return 'S';
    if (score >= 70) return 'A';
    if (score >= 56) return 'B';
    if (score >= 42) return 'C';
    return 'D';
  }

  static String dateLabel(String isoDate) {
    final date = DateTime.tryParse(isoDate);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return '오늘';
    if (diff.inDays == 1) return '어제';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}주 전';
    return '${(diff.inDays / 30).floor()}개월 전';
  }
}
