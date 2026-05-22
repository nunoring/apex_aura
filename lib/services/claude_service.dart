import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import '../config.dart';

// Claude Haiku 4.5 외모 분석 서비스
// Anthropic REST API + Vision (이미지 + 텍스트)
// 외모 분석 1등 모델. Gemini 대비 content filter 약함 + 디테일 풍부.
class ClaudeService {
  static const _systemPrompt =
      '당신은 1회 컨설팅비 30만원의 외모 컨설턴트입니다. '
      '실제 1:1 컨설팅 자료 수준의 깊이로 분석합니다. '
      '톤: 직설적 + 전문가 권위 + 단점 명시 + 즉시 실행 가능한 솔루션. '
      '예시: "둥근~하트형 얼굴형. 하안부가 큰 편 → 시선이 집중되어 단점이 도드라짐. '
      '솔루션: 외곽 라인 정리 헤어 + 광대 강조 메이크업으로 시선 분산." '
      '위로형/모호한 표현 ("자연스러워요", "친근해요" 단독 사용 X). '
      '솔루션은 비의료 그루밍 (헤어 / 메이크업 / 패션 / 액세서리 / 스킨케어) 만 제시. '
      '의료 행위 권유 절대 금지 — 병원·클리닉 추천 금지, 약물 추천 금지. '
      '얼굴 평가는 인상/비율 관찰까지만, 미적 우열 판단 금지. '
      '모든 응답은 반드시 JSON만, 다른 텍스트 없이 반환합니다. JSON 앞뒤에 ```json 같은 마크다운 절대 금지.';

  static const _animalCatalog = [
    {'name': '강아지상', 'emoji': '🐶', 'keywords': ['부드러움', '친근함', '자연스러움']},
    {'name': '고양이상', 'emoji': '🐱', 'keywords': ['도도함', '신비로움', '우아함']},
    {'name': '여우상', 'emoji': '🦊', 'keywords': ['세련됨', '날카로움', '정돈됨']},
    {'name': '사슴상', 'emoji': '🦌', 'keywords': ['청초함', '순수함', '차분함']},
    {'name': '늑대상', 'emoji': '🐺', 'keywords': ['강인함', '카리스마', '차가움']},
    {'name': '토끼상', 'emoji': '🐰', 'keywords': ['귀여움', '발랄함', '동안']},
    {'name': '곰상', 'emoji': '🐻', 'keywords': ['듬직함', '편안함', '포근함']},
  ];

  // 이미지 리사이즈 + 압축 (Anthropic API 처리 부담 줄임)
  // 셀카 5~10MB → 1024px × JPEG 85% ≈ 150~300KB → 처리 안정/빠름
  static Uint8List _compressImage(Uint8List originalBytes) {
    try {
      final decoded = img.decodeImage(originalBytes);
      if (decoded == null) return originalBytes;
      // 긴 축 768px 이내로 리사이즈 (Anthropic 권장 1568px 이내, 더 작게 안정)
      final maxDim = 768;
      img.Image resized;
      if (decoded.width > decoded.height) {
        resized = decoded.width > maxDim
            ? img.copyResize(decoded, width: maxDim)
            : decoded;
      } else {
        resized = decoded.height > maxDim
            ? img.copyResize(decoded, height: maxDim)
            : decoded;
      }
      final jpeg = img.encodeJpg(resized, quality: 85);
      debugPrint('🔵 Image compress: ${originalBytes.length} → ${jpeg.length} bytes (${(jpeg.length / originalBytes.length * 100).toStringAsFixed(1)}%)');
      return Uint8List.fromList(jpeg);
    } catch (e) {
      debugPrint('🔵 Image compress 실패, 원본 사용: $e');
      return originalBytes;
    }
  }

  static Future<Map<String, dynamic>> analyze({
    required Uint8List imageBytes,
    required String mimeType,
    required String animalType,
    required String gender,
    required Map<String, dynamic> faceData,
    required bool isPro,
  }) async {
    // 이미지 압축 (Claude API 처리 부담 줄이려면 1MB 이하 권장)
    final compressed = _compressImage(imageBytes);
    final compressedMime = 'image/jpeg'; // 압축 후 항상 JPEG

    // 1회 호출에 메인 + lookalike + animal_distribution 통합 (응답 시간 절반)
    final prompt = _buildPrompt(animalType, gender, faceData, isPro);
    return _callClaude(
      systemPrompt: _systemPrompt,
      userText: prompt,
      imageBytes: compressed,
      mimeType: compressedMime,
      maxTokens: 3072,
    );
  }

  // Claude API 호출 (HTTP REST + Vision) — 재시도 1회 (UX 우선)
  // timeout 25s, 429/529/5xx 시 3초 후 1회 재시도. 그 이후 즉시 실패.
  static Future<Map<String, dynamic>> _callClaude({
    required String systemPrompt,
    required String userText,
    required Uint8List imageBytes,
    required String mimeType,
    required int maxTokens,
  }) async {
    final base64Image = base64Encode(imageBytes);
    final uri = Uri.parse('https://api.anthropic.com/v1/messages');
    final body = jsonEncode({
      'model': kClaudeModel,
      'max_tokens': maxTokens,
      'system': systemPrompt,
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'image',
              'source': {
                'type': 'base64',
                'media_type': mimeType,
                'data': base64Image,
              },
            },
            {'type': 'text', 'text': userText},
          ],
        }
      ],
    });

    Future<http.Response> doCall() => http.post(
          uri,
          headers: {
            'x-api-key': kAnthropicApiKey,
            'anthropic-version': '2023-06-01',
            'content-type': 'application/json',
          },
          body: body,
        ).timeout(const Duration(seconds: 25));

    http.Response res;
    try {
      res = await doCall();
    } catch (e) {
      debugPrint('⚠️ Claude API 1차 시도 실패 (재시도 1회): $e');
      await Future.delayed(const Duration(seconds: 3));
      res = await doCall(); // 1회 재시도 — 또 실패 시 throw가 호출자로 전파
    }

    if (res.statusCode == 200) {
      final response = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final content = response['content'] as List?;
      if (content == null || content.isEmpty) {
        throw Exception('Claude empty response');
      }
      final firstText = (content.first as Map)['text']?.toString() ?? '';
      return _parseJson(firstText);
    }

    // 5xx/429/529는 한 번 재시도
    if (res.statusCode == 429 ||
        res.statusCode == 529 ||
        (res.statusCode >= 500 && res.statusCode < 600)) {
      debugPrint('⚠️ Claude API ${res.statusCode}: 3초 후 1회 재시도');
      await Future.delayed(const Duration(seconds: 3));
      res = await doCall();
      if (res.statusCode == 200) {
        final response = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        final content = response['content'] as List?;
        final firstText = (content!.first as Map)['text']?.toString() ?? '';
        return _parseJson(firstText);
      }
    }

    final bodyPreview = utf8.decode(res.bodyBytes);
    final clipped = bodyPreview.substring(0, bodyPreview.length.clamp(0, 200));
    throw Exception('Claude API ${res.statusCode}: $clipped');
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

    return '''당신은 1:1 외모 컨설팅을 수행하는 전문가입니다. 30만원 상당의 컨설팅 자료 수준의 깊이로 분석해주세요.

## 참고 데이터
- 성별: $genderKo
- 눈꼬리: ${eyeAngle}° ($eyeAngleDesc), 얼굴형: $faceShape, 눈간격: $eyeGapDesc
- 현재 동물상 (ML Kit 자동 판정): $currentFaceType

## 동물상 카탈로그
$catalogText

## 컨설팅 톤 (필수)
※ **직설적 + 전문가 권위 + 단점 명시 + 즉시 실행 가능한 솔루션**.
※ 예시: "둥근~하트형 얼굴형. 이상적 가로~세로 비율이지만, 하안부가 큰 편 → 시선이 집중되어 하관이 도드라지는 단점. 솔루션: 외곽 라인 정리 헤어 + 광대 강조 메이크업으로 시선 분산."
※ 단점은 반드시 명시하되, **비의료 보완책**(헤어/메이크업/패션/그루밍)을 함께 제시.

## 콘텐츠 가이드
※ target_animal(변신 추천)은 자유 선택.
※ references의 셀럽은 **위키피디아 개인 페이지 있는 솔로 배우 또는 단독 활동 가수**. 그룹 이름 절대 금지.

## 솔루션 가이드
※ 솔루션은 비의료 그루밍만: 헤어 / 메이크업 / 안경테 / 옷 실루엣 / 액세서리 / 스킨케어.
※ 병원·클리닉 추천 금지. 약물 추천 금지.

## 기타
※ ${gender == 'female' ? '여성이므로 메이크업 4단계 제품 추천 포함.' : '남성이므로 메이크업 대신 스킨케어+눈썹정리+헤어왁스+향수 그루밍 루틴 4단계 추천.'}

## 닮은꼴 셀럽 + 동물상 분포 (필수, 누락 금지)
※ lookalike_celebs: 사진과 실제로 닮은 한국 $genderKo 연예인 3명. 개인 솔로/배우만 (그룹명 금지). 위키피디아 개인 페이지 있는 사람.
※ animal_distribution: 사진을 보고 직접 판단한 동물상 분포. 7종(강아지/고양이/여우/사슴/늑대/토끼/곰)상 중 3개. 합 100. 메인이 1순위로 가장 높게.

$schema''';
  }

  // _freeSchema와 _proSchema는 GeminiService와 동일한 응답 스키마 사용
  static String _freeSchema(String targetAnimal, String currentAnimal) => '''
반드시 아래 JSON 형식으로만 응답:

{
  "first_impression": {
    "summary": "첫인상 한 줄 요약 (20자 이상)",
    "face_shape": "얼굴형",
    "lookalike_celebs": [
      {"name": "한국 연예인 이름1 (개인 솔로/배우, 그룹명 금지)", "trait": "어디가 닮았는지 (15자 이상)", "work": "대표작/소속 (10자 이상)"},
      {"name": "한국 연예인 이름2", "trait": "...", "work": "..."},
      {"name": "한국 연예인 이름3", "trait": "...", "work": "..."}
    ],
    "animal_distribution": [
      {"name": "메인동물상", "percentage": 45},
      {"name": "보조동물상1", "percentage": 30},
      {"name": "보조동물상2", "percentage": 25}
    ],
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
    "target_animal": {"name": "추천 변신 동물상 (자유 선택, 동물상 카탈로그 중 하나)", "emoji": "이모지", "keywords": ["키워드1", "키워드2"], "comment": "20자 이상 설명"},
    "animal_match": {
      "percentage": 80,
      "similarity_points": ["닮은 점 1 (30자 이상)", "닮은 점 2 (30자 이상)", "닮은 점 3 (30자 이상)"]
    },
    "appearance_tier": {
      "score": 7,
      "tier_name": "인스타에서 자주 보이는 유형",
      "tier_description": "1=논외 / 6=잘생김 / 7=인스타 유형 / 8=연예인급 / 9=고등급 / 10=세계급. 6~10 중 객관적 1개",
      "above_percentile": 25
    },
    "weaknesses": [
      {"title": "단점1 (예: 하안부가 큰 편)", "observation": "관찰 (25자 이상)", "impact": "인상 영향 (20자 이상)", "solution": "비의료 보완책 (30자 이상)"},
      {"title": "단점2", "observation": "...", "impact": "...", "solution": "..."},
      {"title": "단점3", "observation": "...", "impact": "...", "solution": "..."}
    ]
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
      "application": "관찰→영향→변화→결과 연결 설명. 120자 이상.",
      "timeline": "오늘 가능",
      "gap_reduction": 15,
      "references": [{"name": "셀럽명", "context": "작품(연도)+장면+연결이유 (50자 이상)", "description": "스타일 요소 (30자 이상)"}]
    },
    {
      "category": "패션",
      "observation": "현재 패션 상태 (40자 이상)",
      "impact": "인상에 미치는 영향 (30자 이상)",
      "change": "개선 방법 (30자 이상)",
      "result": "변화 후 인상 (30자 이상)",
      "application": "120자 이상.",
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
      "application": "120자 이상.",
      "references": [{"name": "셀럽명", "context": "작품(연도)+장면+연결이유 (50자 이상)", "description": "스타일 요소 (30자 이상)"}]
    }
  ]
}''';

  static String _proSchema(String targetAnimal, String currentAnimal) => '''
반드시 아래 JSON 형식으로만 응답:

{
  "first_impression": {
    "summary": "첫인상 한 줄 요약 (20자 이상)",
    "face_shape": "얼굴형",
    "lookalike_celebs": [
      {"name": "한국 연예인 이름1 (개인 솔로/배우, 그룹명 금지)", "trait": "어디가 닮았는지 (15자 이상)", "work": "대표작/소속 (10자 이상)"},
      {"name": "한국 연예인 이름2", "trait": "...", "work": "..."},
      {"name": "한국 연예인 이름3", "trait": "...", "work": "..."}
    ],
    "animal_distribution": [
      {"name": "메인동물상", "percentage": 45},
      {"name": "보조동물상1", "percentage": 30},
      {"name": "보조동물상2", "percentage": 25}
    ],
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
    "target_animal": {"name": "추천 변신 동물상 (자유 선택)", "emoji": "이모지", "keywords": ["키워드1", "키워드2"], "comment": "20자 이상"},
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
    },
    "appearance_tier": {
      "score": 7,
      "tier_name": "인스타에서 자주 보이는 유형",
      "tier_description": "1=논외 / 6=잘생김 / 7=인스타 유형 / 8=연예인급 / 9=고등급 / 10=세계급",
      "above_percentile": 25
    },
    "weaknesses": [
      {"title": "단점1 (예: 하안부가 큰 편)", "observation": "관찰 사실 (25자 이상)", "impact": "인상 영향 (20자 이상)", "solution": "비의료 보완책 (30자 이상)"},
      {"title": "단점2", "observation": "...", "impact": "...", "solution": "..."},
      {"title": "단점3", "observation": "...", "impact": "...", "solution": "..."}
    ]
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
    "physical": "신체관리 한 문단 (40자 이상)",
    "face": "얼굴관리 한 문단 (40자 이상)",
    "fashion": "패션 한 문단 (40자 이상)"
  },
  "action_cards": [
    {
      "category": "헤어스타일",
      "observation": "현재 헤어 (40자 이상)",
      "impact": "영향 (30자 이상)",
      "change": "개선 (30자 이상)",
      "result": "결과 (30자 이상)",
      "application": "120자 이상",
      "references": [{"name": "솔로 배우/가수 이름", "context": "작품(연도)+장면+연결이유 (50자 이상)", "description": "스타일 요소 (30자 이상)"}]
    },
    {
      "category": "패션",
      "observation": "현재 패션 (40자 이상)",
      "impact": "영향 (30자 이상)",
      "change": "개선 (30자 이상)",
      "result": "결과 (30자 이상)",
      "application": "120자 이상",
      "references": [{"name": "솔로 배우/가수 이름", "context": "작품(연도)+장면+연결이유 (50자 이상)", "description": "스타일 요소 (30자 이상)"}]
    },
    {
      "category": "그루밍",
      "observation": "현재 그루밍 (40자 이상)",
      "impact": "영향 (30자 이상)",
      "change": "개선 (30자 이상)",
      "result": "결과 (30자 이상)",
      "application": "120자 이상",
      "references": [{"name": "솔로 배우/가수 이름", "context": "작품(연도)+장면+연결이유 (50자 이상)", "description": "스타일 요소 (30자 이상)"}]
    }
  ],
  "makeup_steps": [
    {"step_number": 1, "step_name": "기초", "description": "기초 단계 설명", "products": [{"name": "제품명", "shade": null, "category": "카테고리", "usage": "사용법"}], "tip": "팁"},
    {"step_number": 2, "step_name": "베이스", "description": "베이스 단계", "products": [{"name": "제품명", "shade": "색상", "category": "파운데이션", "usage": "사용법"}], "tip": "팁"},
    {"step_number": 3, "step_name": "음영", "description": "음영 단계", "products": [{"name": "제품명", "shade": "색상", "category": "눈썹", "usage": "사용법"}], "tip": "팁"},
    {"step_number": 4, "step_name": "마무리", "description": "마무리 단계", "products": [{"name": "제품명", "shade": null, "category": "파우더", "usage": "사용법"}], "tip": "팁"}
  ],
  "fashion_looks": [
    {
      "name": "룩 이름1 (예: 데일리 베이직)",
      "image_keyword": "Unsplash 영어 키워드 (예: 'white linen shirt jeans men casual')",
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
      "name": "룩 이름2 (룩1과 다른 컨셉)",
      "image_keyword": "룩2 영어 키워드",
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
      throw Exception('Claude JSON 파싱 실패: ${cleaned.substring(0, cleaned.length.clamp(0, 200))}');
    }
  }
}
