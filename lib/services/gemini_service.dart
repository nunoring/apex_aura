import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config.dart';

class GeminiService {
  static const _systemPrompt =
      '당신은 10년 경력 퍼스널 스타일리스트입니다. '
      '사진 속 헤어스타일, 패션, 그루밍 상태를 관찰하고 '
      '목표 스타일 방향으로 구체적인 스타일링 개선 방향을 제안합니다. '
      '얼굴 특성 수치는 제공된 데이터를 참고하며, 얼굴 자체를 평가하거나 점수를 매기지 않습니다. '
      '모든 응답은 반드시 JSON만, 다른 텍스트 없이 반환합니다.';

  static const _animalCatalog = [
    {'name': '강아지상', 'emoji': '🐶', 'keywords': ['부드러움', '친근함', '자연스러움']},
    {'name': '고양이상', 'emoji': '🐱', 'keywords': ['도도함', '신비로움', '우아함']},
    {'name': '여우상', 'emoji': '🦊', 'keywords': ['세련됨', '날카로움', '정돈됨']},
    {'name': '사슴상', 'emoji': '🦌', 'keywords': ['청초함', '순수함', '차분함']},
    {'name': '늑대상', 'emoji': '🐺', 'keywords': ['강인함', '카리스마', '차가움']},
    {'name': '토끼상', 'emoji': '🐰', 'keywords': ['귀여움', '발랄함', '동안']},
    {'name': '곰상', 'emoji': '🐻', 'keywords': ['듬직함', '편안함', '포근함']},
  ];

  static Future<Map<String, dynamic>> analyze({
    required Uint8List imageBytes,
    required String mimeType,
    required String animalType,
    required String gender,
    required Map<String, dynamic> faceData,
    required bool isPro,
  }) async {
    final model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: kGeminiApiKey,
      systemInstruction: Content.system(_systemPrompt),
      generationConfig: GenerationConfig(maxOutputTokens: 4096, temperature: 0.7),
    );

    final prompt = _buildPrompt(animalType, gender, faceData, isPro);

    final response = await model.generateContent([
      Content.multi([
        DataPart(mimeType, imageBytes),
        TextPart(prompt),
      ]),
    ]);

    final raw = response.text ?? '';
    return _parseJson(raw);
  }

  static String _buildPrompt(
    String animalType,
    String gender,
    Map<String, dynamic> faceData,
    bool isPro,
  ) {
    final genderKo = gender == 'female' ? '여성' : '남성';
    final currentFaceType = faceData['current_face_type']?.toString() ?? '미분류';
    final eyeAngle = faceData['eye_angle'] ?? 0;
    final eyeAngleDesc = faceData['eye_angle_desc'] ?? '수평';
    final faceShape = faceData['face_shape'] ?? '계란형';
    final eyeGapDesc = faceData['eye_gap_desc'] ?? '보통';

    final catalogText = _animalCatalog
        .map((a) => "${a['name']} ${a['emoji']} — ${(a['keywords'] as List).join(', ')}")
        .join('\n');

    final schema = isPro ? _proSchema(animalType, currentFaceType) : _freeSchema(animalType, currentFaceType);

    return '''사진 속 스타일링을 분석하고 아래 데이터를 활용해 목표 스타일 방향으로 개선안을 제안해주세요.

## 참고 데이터
- 성별: $genderKo
- 눈꼬리: ${eyeAngle}° ($eyeAngleDesc), 얼굴형: $faceShape, 눈간격: $eyeGapDesc
- 현재 동물상: $currentFaceType → 목표: $animalType

## 동물상 카탈로그
$catalogText

※ 헤어/패션/그루밍 스타일링에 집중하세요. 얼굴 평가 금지.
※ 셀럽 레퍼런스는 작품명(연도) + 장면 + 이 사람 특징과의 연결 이유를 포함하세요.
※ 시술/성형/의료 관련 표현 절대 금지.
※ 패션 제안 첫 문장에 "얼굴형 수치 기반 제안이에요" 문구 포함.
※ ${gender == 'female' ? '여성이므로 메이크업 4단계 제품 추천 포함.' : '남성이므로 메이크업 대신 스킨케어+눈썹정리+헤어왁스+향수 그루밍 루틴 4단계 추천.'}

$schema''';
  }

  static String _freeSchema(String targetAnimal, String currentAnimal) => '''
반드시 아래 JSON 형식으로만 응답하세요:

{
  "first_impression": {
    "summary": "첫인상 한 줄 요약 (20자 이상)",
    "face_shape": "얼굴형",
    "main_animal": {
      "name": "$currentAnimal",
      "emoji": "🐶",
      "keywords": ["키워드1", "키워드2", "키워드3"],
      "strengths": [
        {"title": "강점1", "description": "30자 이상 설명"},
        {"title": "강점2", "description": "30자 이상 설명"},
        {"title": "강점3", "description": "30자 이상 설명"}
      ],
      "tip": "이 매력을 살리는 스타일링 팁 (30자 이상)"
    },
    "sub_animal": {"name": "보조동물상", "emoji": "🐱", "keywords": ["키워드1", "키워드2"], "comment": "30자 이상 설명"},
    "target_animal": {"name": "$targetAnimal", "emoji": "🦊", "keywords": ["키워드1", "키워드2"], "comment": "20자 이상 설명"},
    "animal_match": {
      "percentage": 80,
      "similarity_points": ["닮은 점 1 (30자 이상)", "닮은 점 2 (30자 이상)", "닮은 점 3 (30자 이상)"]
    }
  },
  "comparison": {
    "current_animal": "$currentAnimal",
    "target_animal": "$targetAnimal",
    "current_keywords": ["키워드1", "키워드2", "키워드3"],
    "target_keywords": ["키워드1", "키워드2", "키워드3"],
    "gap_percent": 45
  },
  "consultant_report_simple": {
    "quote": "전문가 코멘트 (20자 이상)",
    "gap": "핵심 갭 요소",
    "direction": "변화 방향"
  },
  "action_cards": [
    {
      "category": "헤어스타일",
      "observation": "현재 헤어 상태 (40자 이상)",
      "impact": "인상에 미치는 영향 (30자 이상)",
      "change": "개선 방법 (30자 이상)",
      "result": "변화 후 인상 (30자 이상)",
      "application": "관찰→영향→변화→결과 연결 설명. 반드시 '이 변화만으로 ${targetAnimal}에 X% 더 가까워져요' 문장 포함. 강조어휘(핵심은/사실/근데/여기서 바뀌는) 1개 이상. 120자 이상.",
      "timeline": "오늘 가능",
      "gap_reduction": 15,
      "references": [{"name": "셀럽명", "context": "작품(연도)+장면+이 사람과의 연결이유 (50자 이상)", "description": "스타일 요소 (30자 이상)"}]
    },
    {
      "category": "패션",
      "observation": "현재 패션 상태 (40자 이상)",
      "impact": "인상에 미치는 영향 (30자 이상)",
      "change": "개선 방법 (30자 이상)",
      "result": "변화 후 인상 (30자 이상)",
      "application": "반드시 '이 변화만으로 ${targetAnimal}에 X% 더 가까워져요' 문장 포함. 강조어휘 포함. 120자 이상.",
      "timeline": "1주일",
      "gap_reduction": 20,
      "references": [{"name": "셀럽명", "context": "작품(연도)+장면+연결이유 (50자 이상)", "description": "스타일 요소 (30자 이상)"}]
    },
    {
      "category": "그루밍",
      "observation": "현재 그루밍 상태 (40자 이상)",
      "impact": "인상에 미치는 영향 (30자 이상)",
      "change": "개선 방법 (30자 이상)",
      "result": "변화 후 인상 (30자 이상)",
      "application": "120자 이상, 강조어휘 포함",
      "references": [{"name": "셀럽명", "context": "작품(연도)+장면+연결이유 (50자 이상)", "description": "스타일 요소 (30자 이상)"}]
    }
  ]
}''';

  static String _proSchema(String targetAnimal, String currentAnimal) => '''
반드시 아래 JSON 형식으로만 응답하세요:

{
  "first_impression": {
    "summary": "첫인상 한 줄 요약 (20자 이상)",
    "face_shape": "얼굴형",
    "main_animal": {
      "name": "$currentAnimal",
      "emoji": "🐶",
      "keywords": ["키워드1", "키워드2", "키워드3"],
      "strengths": [
        {"title": "강점1", "description": "30자 이상 설명"},
        {"title": "강점2", "description": "30자 이상 설명"},
        {"title": "강점3", "description": "30자 이상 설명"}
      ],
      "tip": "스타일링 팁 (30자 이상)"
    },
    "sub_animal": {"name": "보조동물상", "emoji": "🐱", "keywords": ["키워드1", "키워드2"], "comment": "30자 이상"},
    "target_animal": {"name": "$targetAnimal", "emoji": "🦊", "keywords": ["키워드1", "키워드2"], "comment": "20자 이상"},
    "animal_match": {
      "main": "$currentAnimal",
      "percentage": 80,
      "reasons": ["근거1 (40자 이상)", "근거2 (40자 이상)", "근거3 (40자 이상)"],
      "gap_to_target": {
        "target_animal": "$targetAnimal",
        "changeable": ["바꿀 수 있는 요소1", "바꿀 수 있는 요소2"],
        "fixed": ["골격 등 고정 요소1"]
      },
      "similarity_points": ["닮은 점1 (30자 이상)", "닮은 점2 (30자 이상)", "닮은 점3 (30자 이상)"]
    }
  },
  "comparison": {
    "current_animal": "$currentAnimal",
    "target_animal": "$targetAnimal",
    "current_keywords": ["키워드1", "키워드2", "키워드3"],
    "target_keywords": ["키워드1", "키워드2", "키워드3"],
    "gap_percent": 45
  },
  "radar": {
    "current": {"눈매": 0.5, "코": 0.5, "얼굴윤곽": 0.5, "스타일": 0.4},
    "target": {"눈매": 0.85, "코": 0.7, "얼굴윤곽": 0.75, "스타일": 0.85}
  },
  "consultant_report_full": {
    "quote": "전문가 코멘트 (50자 이상)",
    "observation": "현재 관찰 (30자 이상)",
    "impact": "인상 영향 (30자 이상)",
    "gap": "핵심 갭 (20자 이상)",
    "direction": "변화 방향 (20자 이상)"
  },
  "three_factor": {
    "physical": {"summary": "신체 요약 (15자 이상)", "items": ["항목1", "항목2", "항목3"]},
    "face": {"summary": "얼굴 요약 (15자 이상)", "items": ["항목1", "항목2", "항목3"]},
    "fashion": {"summary": "패션 요약 (15자 이상)", "items": ["항목1", "항목2", "항목3"]}
  },
  "action_cards": [
    {
      "category": "헤어스타일",
      "observation": "현재 헤어 (40자 이상)",
      "impact": "영향 (30자 이상)",
      "change": "개선 (30자 이상)",
      "result": "결과 (30자 이상)",
      "application": "120자 이상, 강조어휘 1개 이상",
      "references": [{"name": "셀럽명", "context": "작품(연도)+장면+연결이유 (50자 이상)", "description": "스타일 요소 (30자 이상)"}]
    },
    {
      "category": "패션",
      "observation": "현재 패션 (40자 이상)",
      "impact": "영향 (30자 이상)",
      "change": "개선 (30자 이상)",
      "result": "결과 (30자 이상)",
      "application": "120자 이상, 강조어휘 1개 이상",
      "references": [{"name": "셀럽명", "context": "작품(연도)+장면+연결이유 (50자 이상)", "description": "스타일 요소 (30자 이상)"}]
    },
    {
      "category": "그루밍",
      "observation": "현재 그루밍 (40자 이상)",
      "impact": "영향 (30자 이상)",
      "change": "개선 (30자 이상)",
      "result": "결과 (30자 이상)",
      "application": "120자 이상, 강조어휘 1개 이상",
      "references": [{"name": "셀럽명", "context": "작품(연도)+장면+연결이유 (50자 이상)", "description": "스타일 요소 (30자 이상)"}]
    }
  ],
  "makeup_steps": [
    {"step_number": 1, "step_name": "기초", "description": "기초 단계 설명", "products": [{"name": "제품명", "shade": null, "category": "카테고리", "usage": "사용법"}, {"name": "제품명2", "shade": null, "category": "카테고리2", "usage": "사용법2"}], "tip": "팁"},
    {"step_number": 2, "step_name": "베이스", "description": "베이스 단계", "products": [{"name": "제품명", "shade": "색상", "category": "파운데이션", "usage": "사용법"}, {"name": "제품명2", "shade": null, "category": "컨실러", "usage": "사용법2"}], "tip": "팁"},
    {"step_number": 3, "step_name": "음영", "description": "음영 단계", "products": [{"name": "제품명", "shade": "색상", "category": "눈썹", "usage": "사용법"}, {"name": "제품명2", "shade": null, "category": "쉐딩", "usage": "사용법2"}], "tip": "팁"},
    {"step_number": 4, "step_name": "마무리", "description": "마무리 단계", "products": [{"name": "제품명", "shade": null, "category": "파우더", "usage": "사용법"}, {"name": "제품명2", "shade": null, "category": "픽서", "usage": "사용법2"}], "tip": "팁"}
  ],
  "fashion_looks": [
    {
      "name": "룩 이름1",
      "items": [
        {"category": "Outer", "description": "아우터 설명", "rationale": "이유"},
        {"category": "Top", "description": "상의 설명", "rationale": "이유"},
        {"category": "Bottom", "description": "하의 설명", "rationale": "이유"},
        {"category": "Shoes", "description": "신발 설명", "rationale": "이유"},
        {"category": "Acc", "description": "액세서리 설명", "rationale": "이유"}
      ],
      "rationale": "전체 코디 이유",
      "styling_tip": "스타일링 팁",
      "color_palette": ["#000000", "#FFFFFF"]
    },
    {
      "name": "룩 이름2",
      "items": [
        {"category": "Outer", "description": "설명", "rationale": "이유"},
        {"category": "Top", "description": "설명", "rationale": "이유"},
        {"category": "Bottom", "description": "설명", "rationale": "이유"},
        {"category": "Shoes", "description": "설명", "rationale": "이유"},
        {"category": "Acc", "description": "설명", "rationale": "이유"}
      ],
      "rationale": "전체 코디 이유",
      "styling_tip": "스타일링 팁",
      "color_palette": ["#000000", "#808080"]
    }
  ],
  "color_palette": {
    "main": ["#000000", "#FFFFFF"],
    "accent": ["#C19A6B"],
    "avoid": ["#FF00FF"]
  }
}''';

  static Map<String, dynamic> _parseJson(String raw) {
    final cleaned = raw
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();
    try {
      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (_) {
      final match = RegExp(r'\{[\s\S]*\}').firstMatch(cleaned);
      if (match != null) {
        return jsonDecode(match.group(0)!) as Map<String, dynamic>;
      }
      throw Exception('JSON 파싱 실패: ${cleaned.substring(0, cleaned.length.clamp(0, 200))}');
    }
  }
}
