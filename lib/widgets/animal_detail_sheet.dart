import 'package:flutter/material.dart';

class AnimalDetailSheet extends StatelessWidget {
  final String animalName;
  final Map<String, dynamic> faceData;
  final String gender;

  const AnimalDetailSheet({
    super.key,
    required this.animalName,
    required this.faceData,
    required this.gender,
  });

  static void show(BuildContext context, String animalName, Map<String, dynamic> faceData, String gender) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AnimalDetailSheet(
        animalName: animalName,
        faceData: faceData,
        gender: gender,
      ),
    );
  }

  // ─── 동물상 기준 데이터 ────────────────────────────────────────
  static const _catalog = <String, Map<String, dynamic>>{
    '강아지상': {
      'emoji': '🐶',
      'impression': '온화하고 친근한 인상. 처음 본 사람도 경계심 없이 다가가게 만드는 부드러운 눈매가 핵심이에요.',
      'criteria': [
        {'part': '눈꼬리', 'key': 'eye_angle', 'desc': '수평 또는 아래로 처짐 (-1° ~ -8°)', 'match': 'down'},
        {'part': '눈 간격', 'key': 'eye_gap_desc', 'desc': '넓은 편 (비율 0.40 이상)', 'match': '넓음'},
        {'part': '얼굴형', 'key': 'face_shape', 'desc': '둥글거나 계란형', 'match': '계란형'},
        {'part': '전체 인상', 'key': null, 'desc': '각진 요소보다 곡선 요소가 많음', 'match': null},
      ],
      'keywords': ['부드러움', '친근함', '자연스러움', '온화함', '무해함'],
      'contrast': '고양이상과 반대 — 눈꼬리가 올라갈수록 도도한 인상, 내려갈수록 강아지상에 가까워져요.',
    },
    '고양이상': {
      'emoji': '🐱',
      'impression': '신비롭고 도도한 인상. 올라간 눈꼬리와 좁은 눈 간격이 날카롭고 세련된 분위기를 만들어요.',
      'criteria': [
        {'part': '눈꼬리', 'key': 'eye_angle', 'desc': '올라가는 형태 (+1° ~ +8°)', 'match': 'up'},
        {'part': '눈 간격', 'key': 'eye_gap_desc', 'desc': '보통 또는 좁은 편', 'match': '보통'},
        {'part': '얼굴형', 'key': 'face_shape', 'desc': '계란형 또는 갸름한 편', 'match': '계란형'},
        {'part': '눈매', 'key': null, 'desc': '선명하고 또렷한 눈매', 'match': null},
      ],
      'keywords': ['도도함', '신비로움', '우아함', '세련됨', '차가움'],
      'contrast': '강아지상과 반대 — 눈꼬리 각도가 핵심 분기점이에요.',
    },
    '여우상': {
      'emoji': '🦊',
      'impression': '영리하고 세련된 인상. 눈꼬리가 강하게 올라가고 얼굴 윤곽이 갸름해서 시선을 사로잡는 매력이 있어요.',
      'criteria': [
        {'part': '눈꼬리', 'key': 'eye_angle', 'desc': '강하게 올라감 (+3° 이상)', 'match': 'up_strong'},
        {'part': '얼굴형', 'key': 'face_shape', 'desc': '갸름한 편 (비율 0.65~0.75)', 'match': '갸름형'},
        {'part': '눈 간격', 'key': 'eye_gap_desc', 'desc': '보통 또는 좁음', 'match': '보통'},
        {'part': '전체', 'key': null, 'desc': '날카로운 눈매 + 갸름한 윤곽 조합', 'match': null},
      ],
      'keywords': ['세련됨', '날카로움', '정돈됨', '영리함', '매력적'],
      'contrast': '고양이상보다 눈꼬리 각도가 더 강하고 얼굴형이 더 갸름해요.',
    },
    '사슴상': {
      'emoji': '🦌',
      'impression': '청초하고 순수한 인상. 수평에 가까운 눈꼬리와 큰 눈이 맑고 깨끗한 분위기를 만들어요.',
      'criteria': [
        {'part': '눈꼬리', 'key': 'eye_angle', 'desc': '거의 수평 (-1° ~ +1°)', 'match': 'neutral'},
        {'part': '눈 크기', 'key': null, 'desc': '크고 또렷한 눈', 'match': null},
        {'part': '얼굴형', 'key': 'face_shape', 'desc': '계란형 또는 긴 편', 'match': '계란형'},
        {'part': '전체', 'key': null, 'desc': '깨끗하고 맑은 피부 인상', 'match': null},
      ],
      'keywords': ['청초함', '순수함', '차분함', '맑음', '청순함'],
      'contrast': '강아지상보다 더 중성적이고 청초한 느낌. 눈꼬리가 수평에 가까워요.',
    },
    '늑대상': {
      'emoji': '🐺',
      'impression': '강인하고 카리스마 있는 인상. 수평~약간 올라가는 눈꼬리와 갸름한 얼굴이 냉철한 분위기를 만들어요.',
      'criteria': [
        {'part': '눈꼬리', 'key': 'eye_angle', 'desc': '수평 또는 약간 올라감 (0° ~ +3°)', 'match': 'neutral_up'},
        {'part': '얼굴형', 'key': 'face_shape', 'desc': '갸름하거나 긴 편', 'match': '갸름형'},
        {'part': '눈매', 'key': null, 'desc': '날카롭고 강한 눈빛', 'match': null},
        {'part': '전체', 'key': null, 'desc': '강하고 냉철한 인상', 'match': null},
      ],
      'keywords': ['강인함', '카리스마', '차가움', '냉철함', '강렬함'],
      'contrast': '여우상보다 도도함보다는 강인함 쪽. 눈꼬리 각도가 중간 범위예요.',
    },
    '토끼상': {
      'emoji': '🐰',
      'impression': '귀엽고 동안인 인상. 처지는 눈꼬리와 동글동글한 얼굴형이 앳되고 발랄한 느낌을 만들어요.',
      'criteria': [
        {'part': '눈꼬리', 'key': 'eye_angle', 'desc': '내려가거나 수평 (-1° ~ -5°)', 'match': 'down'},
        {'part': '얼굴형', 'key': 'face_shape', 'desc': '둥글거나 넓은 편', 'match': '둥근형'},
        {'part': '눈 간격', 'key': 'eye_gap_desc', 'desc': '보통 또는 넓음', 'match': '보통'},
        {'part': '전체', 'key': null, 'desc': '동안 + 발랄한 인상', 'match': null},
      ],
      'keywords': ['귀여움', '발랄함', '동안', '앳됨', '밝음'],
      'contrast': '강아지상과 비슷하지만 더 동글동글하고 동안의 느낌이 강해요.',
    },
    '곰상': {
      'emoji': '🐻',
      'impression': '듬직하고 포근한 인상. 내려가는 눈꼬리와 넓은 얼굴형이 편안하고 믿음직한 분위기를 만들어요.',
      'criteria': [
        {'part': '눈꼬리', 'key': 'eye_angle', 'desc': '내려가는 형태 (-2° ~ -8°)', 'match': 'down_strong'},
        {'part': '얼굴형', 'key': 'face_shape', 'desc': '둥글고 넓은 편', 'match': '둥근형'},
        {'part': '눈 간격', 'key': 'eye_gap_desc', 'desc': '넓은 편', 'match': '넓음'},
        {'part': '전체', 'key': null, 'desc': '전체적으로 부드럽고 온화한 인상', 'match': null},
      ],
      'keywords': ['듬직함', '편안함', '포근함', '믿음직함', '온화함'],
      'contrast': '강아지상과 비슷하지만 더 크고 듬직한 느낌. 눈꼬리가 더 처져 있어요.',
    },
  };

  @override
  Widget build(BuildContext context) {
    final data = _catalog[animalName] ?? _catalog['강아지상']!;
    final criteria = data['criteria'] as List;
    final keywords = data['keywords'] as List<String>;
    final eyeAngle = double.tryParse(faceData['eye_angle']?.toString() ?? '0') ?? 0.0;
    final eyeGapDesc = faceData['eye_gap_desc']?.toString() ?? '보통';
    final faceShape = faceData['face_shape']?.toString() ?? '계란형';

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF111111),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // 핸들
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF333333),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                children: [
                  // 헤더
                  Row(
                    children: [
                      Text(data['emoji'] as String,
                          style: const TextStyle(fontSize: 40)),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(animalName,
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold,
                                  color: Color(0xFFE8D5B7))),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            children: keywords.take(3).map((kw) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1500),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(kw,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFFE8A030))),
                            )).toList(),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 인상 설명
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(data['impression'] as String,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFFCCCCCC), height: 1.6)),
                  ),
                  const SizedBox(height: 20),

                  // 특징 기준
                  const Text('이 상의 측정 기준',
                      style: TextStyle(fontSize: 13, color: Color(0xFFE8D5B7),
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  ...criteria.map((c) {
                    final part = c['part'] as String;
                    final desc = c['desc'] as String;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 60,
                            child: Text(part,
                                style: const TextStyle(
                                    fontSize: 11, color: Color(0xFF888888))),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(desc,
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFFDDDDDD))),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 20),

                  // 내 수치 비교
                  const Text('내 수치와 비교',
                      style: TextStyle(fontSize: 13, color: Color(0xFFE8D5B7),
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  _myMeasurementRow(
                    '눈꼬리 각도',
                    '${eyeAngle.toStringAsFixed(1)}° (${eyeAngle < -1 ? "내려감" : eyeAngle > 1 ? "올라감" : "수평"})',
                    animalName,
                    'eye_angle',
                    eyeAngle,
                  ),
                  _myMeasurementRow(
                    '눈 간격',
                    eyeGapDesc,
                    animalName,
                    'eye_gap_desc',
                    null,
                  ),
                  _myMeasurementRow(
                    '얼굴형',
                    faceShape,
                    animalName,
                    'face_shape',
                    null,
                  ),
                  const SizedBox(height: 20),

                  // 다른 상과 차이
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F0F0F),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF2A2A2A), width: 0.5),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.compare_arrows,
                            size: 14, color: Color(0xFF666666)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(data['contrast'] as String,
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF888888), height: 1.5)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _myMeasurementRow(
      String label, String value, String animalName, String key, double? numVal) {
    final isMatch = _isMatchingCriteria(animalName, key, numVal, value);
    final color = isMatch == true
        ? const Color(0xFF27AE60)
        : isMatch == false
            ? const Color(0xFFE8A030)
            : const Color(0xFF666666);
    final icon = isMatch == true
        ? Icons.check_circle_outline
        : isMatch == false
            ? Icons.info_outline
            : Icons.remove;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(60), width: 0.5),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(fontSize: 11, color: color)),
            const Spacer(),
            Text(value,
                style: TextStyle(
                    fontSize: 12, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  bool? _isMatchingCriteria(String animal, String key, double? numVal, String strVal) {
    switch (animal) {
      case '강아지상':
        if (key == 'eye_angle' && numVal != null) return numVal <= -1;
        if (key == 'eye_gap_desc') return strVal == '넓음';
        break;
      case '고양이상':
        if (key == 'eye_angle' && numVal != null) return numVal >= 1;
        break;
      case '여우상':
        if (key == 'eye_angle' && numVal != null) return numVal >= 3;
        break;
      case '사슴상':
        if (key == 'eye_angle' && numVal != null) return numVal.abs() <= 1;
        break;
      case '늑대상':
        if (key == 'eye_angle' && numVal != null) return numVal >= 0 && numVal <= 3;
        break;
      case '토끼상':
        if (key == 'eye_angle' && numVal != null) return numVal <= -1;
        break;
      case '곰상':
        if (key == 'eye_angle' && numVal != null) return numVal <= -2;
        if (key == 'eye_gap_desc') return strVal == '넓음';
        break;
    }
    return null;
  }
}
