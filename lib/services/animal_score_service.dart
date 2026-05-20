class AnimalScoreService {
  // ML Kit faceData에서 7가지 동물상 퍼센트 계산
  static Map<String, double> calculate(Map<String, dynamic> faceData) {
    final eyeAngle = double.tryParse(faceData['eye_angle']?.toString() ?? '0') ?? 0.0;
    final faceRatio = double.tryParse(faceData['face_ratio']?.toString() ?? '0.75') ?? 0.75;
    final eyeGapRatio = double.tryParse(faceData['eye_gap_ratio']?.toString() ?? '0.4') ?? 0.4;

    // 각 동물상 점수 (0~1)
    final scores = <String, double>{
      '강아지상': _dogScore(eyeAngle, faceRatio, eyeGapRatio),
      '고양이상': _catScore(eyeAngle, faceRatio, eyeGapRatio),
      '여우상': _foxScore(eyeAngle, faceRatio, eyeGapRatio),
      '사슴상': _deerScore(eyeAngle, faceRatio, eyeGapRatio),
      '늑대상': _wolfScore(eyeAngle, faceRatio, eyeGapRatio),
      '토끼상': _rabbitScore(eyeAngle, faceRatio, eyeGapRatio),
      '곰상': _bearScore(eyeAngle, faceRatio, eyeGapRatio),
    };

    // 상위 3개만 남기고 합이 100이 되도록 정규화
    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top3 = sorted.take(3).toList();
    final total = top3.fold(0.0, (s, e) => s + e.value);
    if (total == 0) return {'강아지상': 100.0};

    return Map.fromEntries(
      top3.map((e) => MapEntry(e.key, (e.value / total * 100).roundToDouble())),
    );
  }

  // 가장 닮은 셀럽 반환
  static Map<String, dynamic> getCeleb(String animalName, String gender) {
    final isFemale = gender == 'female';
    final catalog = isFemale ? _celebFemale : _celebMale;
    final list = catalog[animalName] ?? catalog['강아지상']!;
    return list[0]; // 1순위 셀럽
  }

  static List<Map<String, dynamic>> getCelebs(String animalName, String gender) {
    final isFemale = gender == 'female';
    final catalog = isFemale ? _celebFemale : _celebMale;
    return catalog[animalName] ?? catalog['강아지상']!;
  }

  // ─── 동물상 점수 함수 ─────────────────────────────────────────
  static double _dogScore(double eye, double face, double gap) {
    double s = 0;
    if (eye < -1) s += 0.4 * _norm(eye.abs(), 1, 8);
    else if (eye < 1) s += 0.2;
    if (gap > 0.38) s += 0.3 * _norm(gap, 0.38, 0.55);
    if (face > 0.72) s += 0.3 * _norm(face, 0.72, 0.9);
    return s.clamp(0, 1);
  }

  static double _catScore(double eye, double face, double gap) {
    double s = 0;
    if (eye > 1) s += 0.45 * _norm(eye, 1, 8);
    if (gap < 0.42) s += 0.25 * (1 - _norm(gap, 0.28, 0.42));
    if (face < 0.78) s += 0.3 * (1 - _norm(face, 0.6, 0.78));
    return s.clamp(0, 1);
  }

  static double _foxScore(double eye, double face, double gap) {
    double s = 0;
    if (eye > 3) s += 0.5 * _norm(eye, 3, 10);
    if (face < 0.75) s += 0.35 * (1 - _norm(face, 0.6, 0.75));
    if (gap < 0.4) s += 0.15;
    return s.clamp(0, 1);
  }

  static double _deerScore(double eye, double face, double gap) {
    double s = 0;
    final neutralEye = 1 - (eye.abs() / 5).clamp(0, 1);
    s += 0.5 * neutralEye;
    if (face > 0.68 && face < 0.82) s += 0.3;
    if (gap > 0.35 && gap < 0.45) s += 0.2;
    return s.clamp(0, 1);
  }

  static double _wolfScore(double eye, double face, double gap) {
    double s = 0;
    if (eye >= 0 && eye <= 3) s += 0.4;
    if (face < 0.76) s += 0.4 * (1 - _norm(face, 0.6, 0.76));
    if (gap < 0.4) s += 0.2;
    return s.clamp(0, 1);
  }

  static double _rabbitScore(double eye, double face, double gap) {
    double s = 0;
    if (eye < 0) s += 0.3 * _norm(eye.abs(), 0, 5);
    if (face > 0.75) s += 0.4 * _norm(face, 0.75, 0.95);
    if (gap > 0.38) s += 0.3;
    return s.clamp(0, 1);
  }

  static double _bearScore(double eye, double face, double gap) {
    double s = 0;
    if (eye < -2) s += 0.4 * _norm(eye.abs(), 2, 10);
    if (face > 0.78) s += 0.35 * _norm(face, 0.78, 0.95);
    if (gap > 0.4) s += 0.25 * _norm(gap, 0.4, 0.55);
    return s.clamp(0, 1);
  }

  static double _norm(double val, double min, double max) {
    if (max == min) return 0;
    return ((val - min) / (max - min)).clamp(0, 1);
  }

  // ─── 셀럽 카탈로그 ────────────────────────────────────────────
  static const _celebMale = <String, List<Map<String, dynamic>>>{
    '강아지상': [
      {'name': '박보검', 'work': '응답하라 1988', 'trait': '눈꼬리·눈간격'},
      {'name': '차은우', 'work': '진심이 닿다', 'trait': '부드러운 눈매'},
      {'name': '뷔 (BTS)', 'work': 'BTS 활동', 'trait': '둥근 얼굴형'},
    ],
    '고양이상': [
      {'name': '이준기', 'work': '왕의 남자', 'trait': '올라간 눈꼬리'},
      {'name': '공유', 'work': '도깨비', 'trait': '선명한 눈매'},
      {'name': '이민호', 'work': '꽃보다 남자', 'trait': '갸름한 얼굴형'},
    ],
    '여우상': [
      {'name': '현빈', 'work': '사랑의 불시착', 'trait': '날카로운 눈꼬리'},
      {'name': '이병헌', 'work': '내부자들', 'trait': '갸름한 윤곽'},
      {'name': '강동원', 'work': '검사외전', 'trait': '날카로운 눈매'},
    ],
    '사슴상': [
      {'name': '박형식', 'work': '닥터 이방인', 'trait': '맑은 눈매'},
      {'name': '엑소 수호', 'work': '엑소 활동', 'trait': '순수한 인상'},
      {'name': '김수현', 'work': '별에서 온 그대', 'trait': '선한 눈매'},
    ],
    '늑대상': [
      {'name': '소지섭', 'work': '미안하다 사랑한다', 'trait': '냉철한 인상'},
      {'name': '장동건', 'work': '올인', 'trait': '강렬한 눈빛'},
      {'name': '이정재', 'work': '오징어 게임', 'trait': '카리스마'},
    ],
    '토끼상': [
      {'name': '박찬열 (엑소)', 'work': '엑소 활동', 'trait': '동안 인상'},
      {'name': '신원호', 'work': '응팔 PD', 'trait': '귀여운 인상'},
      {'name': 'NCT 재현', 'work': 'NCT 활동', 'trait': '발랄한 눈매'},
    ],
    '곰상': [
      {'name': '류준열', 'work': '응답하라 1988', 'trait': '듬직한 인상'},
      {'name': '조정석', 'work': '오 나의 귀신님', 'trait': '포근한 눈매'},
      {'name': '마동석', 'work': '범죄도시', 'trait': '듬직함'},
    ],
  };

  static const _celebFemale = <String, List<Map<String, dynamic>>>{
    '강아지상': [
      {'name': '아이유', 'work': '나의 아저씨', 'trait': '부드러운 눈매'},
      {'name': '수지', 'work': '건축학개론', 'trait': '친근한 인상'},
      {'name': '한가인', 'work': '해를 품은 달', 'trait': '온화한 눈매'},
    ],
    '고양이상': [
      {'name': '제니 (블랙핑크)', 'work': '블랙핑크 활동', 'trait': '올라간 눈꼬리'},
      {'name': '전지현', 'work': '별에서 온 그대', 'trait': '도도한 눈매'},
      {'name': '손예진', 'work': '사랑의 불시착', 'trait': '선명한 눈매'},
    ],
    '여우상': [
      {'name': '한효주', 'work': '해품달', 'trait': '날카로운 눈꼬리'},
      {'name': '김태리', 'work': '미스터 션샤인', 'trait': '세련된 눈매'},
      {'name': '전소미', 'work': '솔로 활동', 'trait': '갸름한 얼굴형'},
    ],
    '사슴상': [
      {'name': '박신혜', 'work': '상속자들', 'trait': '청순한 눈매'},
      {'name': '공효진', 'work': '파스타', 'trait': '맑은 인상'},
      {'name': '김고은', 'work': '도깨비', 'trait': '순수한 눈매'},
    ],
    '늑대상': [
      {'name': '오연서', 'work': '최고다 이순신', 'trait': '카리스마 눈매'},
      {'name': '이하늬', 'work': '마스크걸', 'trait': '강렬한 인상'},
      {'name': '정유미', 'work': '82년생 김지영', 'trait': '냉철한 인상'},
    ],
    '토끼상': [
      {'name': '김세정', 'work': '구르미 그린 달빛', 'trait': '동안 인상'},
      {'name': '차정원', 'work': '프렌즈', 'trait': '귀여운 눈매'},
      {'name': '로제 (블랙핑크)', 'work': '블랙핑크 활동', 'trait': '발랄한 인상'},
    ],
    '곰상': [
      {'name': '오나라', 'work': '응팔', 'trait': '포근한 인상'},
      {'name': '라미란', 'work': '응팔', 'trait': '듬직한 인상'},
      {'name': '이선빈', 'work': '술꾼도시여자들', 'trait': '친근한 눈매'},
    ],
  };
}
