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
      '당신은 1회 30만원 외모 컨설턴트입니다. '
      '톤: 직설적 + 단점 명시 + 비의료 솔루션 (헤어/메이크업/패션/그루밍). '
      '위로형 표현("자연스럽다", "친근하다") 금지. 의료 권유 금지 (병원/클리닉/약물 X). '
      '얼굴 미적 우열 판단 금지, 비율/인상 관찰까지만. '
      '핵심 필드(description, observation, impact, solution, application)는 풍부하게 80~120자. '
      '기타 필드(keywords, tip, comment)는 짧게 30자 이내. '
      'JSON 응답 전체 3500자 이내로 유지 (한도 초과 시 잘림). '
      '응답은 JSON만, 마크다운 백틱 절대 금지.';

  static const _animalCatalog = [
    {'name': '강아지상', 'emoji': '🐶', 'keywords': ['부드러움', '친근함', '자연스러움']},
    {'name': '고양이상', 'emoji': '🐱', 'keywords': ['도도함', '신비로움', '우아함']},
    {'name': '여우상', 'emoji': '🦊', 'keywords': ['세련됨', '날카로움', '정돈됨']},
    {'name': '사슴상', 'emoji': '🦌', 'keywords': ['청초함', '순수함', '차분함']},
    {'name': '늑대상', 'emoji': '🐺', 'keywords': ['강인함', '카리스마', '차가움']},
    {'name': '토끼상', 'emoji': '🐰', 'keywords': ['귀여움', '발랄함', '동안']},
    {'name': '곰상', 'emoji': '🐻', 'keywords': ['듬직함', '편안함', '포근함']},
  ];

  // 외모 컨설팅 도구 박스 — Claude가 측정 기준 + 분류 도구로 활용
  static const _consultingFramework = '''
## 외모 컨설팅 도구 박스 (분석 시 적극 활용)

### 얼굴 비율 측정 기준
- 삼정비 (이상): 상안부(이마):중안부(눈~코):하안부(인중~턱) = 1:1:1
- 황금비: 얼굴 가로:세로 = 1:1.618 (계란형 기준)
- 광대 적정 위치: 눈동자 아래 약 2cm
- 턱선 곡률: 30~45도가 부드러움 (각진 < 30 = 강함, > 45 = 무력)
- 눈 사이: 한 눈 너비 = 적정 (좁으면 답답, 넓으면 어색)

### 한국 남성 헤어 5분류
1. 댄디컷 — 옆머리 짧고 윗머리 자연 정리. 클래식 인상.
2. 투블럭 — 옆머리 짧고 윗머리 길게. 트렌디 + 강한 인상.
3. 가르마 (Side part) — 옆 가르마로 윗머리 흐름. 정장/오피스.
4. 리프컷 (펌 포함) — 윗머리 볼륨 + 부드러운 컬. 동안 효과.
5. 쉐도우펌/물결펌 — 자연스러운 컬로 부피감. 페미닌 인상.

### 한국 여성 헤어 5분류
1. 단발 (보브) — 어깨 위 깔끔. 청량/도회적.
2. 미디움 레이어드 — 어깨선 + 레이어. 가장 무난.
3. 롱헤어 + 시스루 뱅 — 청순/동안.
4. 사이드 펌 + 미디움 — 우아/성숙.
5. 숏컷 — 시크/모던.

### 컬러 시즌 4분류
- Spring Warm: 노란 베이스 밝은 톤 (코랄, 피치, 라이트 베이지)
- Summer Cool: 푸른 베이스 부드러운 톤 (로즈, 라일락, 그레이)
- Autumn Warm: 노란 베이스 깊은 톤 (테라코타, 카멜, 올리브)
- Winter Cool: 푸른 베이스 강한 톤 (블랙, 와인, 쨍한 화이트)

### K-뷰티 메이크업 4단계 공식 (여성)
1. 베이스 — 스킨/메이크업 베이스 + 톤 보정. 광채감 (글로우 vs 매트)
2. 광채/음영 — 컨실러 + 하이라이터 + 쉐딩으로 입체감
3. 포인트 — 눈썹 + 아이라이너 + 마스카라 + 블러셔 (시즌 컬러 매칭)
4. 마무리 — 립 + 픽서 스프레이 (지속력)

### 남성 그루밍 4단계 공식
1. 스킨케어 — 세안 + 토너 + 수분크림. 결 정돈 = 인상 +20%
2. 눈썹 정리 — 모양 잡기 + 빈 곳 채우기. 인상 좌우 큰 변수
3. 헤어 — 왁스 + 드라이로 윗머리 볼륨 (위 5분류 활용)
4. 향수 — 시트러스/우디/머스크. 깔끔한 인상 마무리

### 패션 실루엣 5분류
- 클래식 — 정장, 핏 강조, 무채색
- 캐주얼 — 데님, 티셔츠, 스니커즈
- 모던/미니멀 — 단색, 슬림 핏, 절제
- 스트릿 — 오버사이즈, 그래픽, 컬러 포인트
- 빈티지 — 70~90s 레퍼런스, 레트로 패턴

## 한국 셀럽 레퍼런스 카탈로그 (위키피디아 페이지 있는 개인만)

### 남성 배우/가수 (15명) — 이름:스타일키워드
박서준:자연스러운 댄디 / 차은우:정제된 미소년 / 이종석:시크 슬림 / 박보검:부드러운 그루밍 / 김수현:다정한 동안 / 송중기:단정한 클래식 / 정우성:강렬한 마초 / 공유:무게감 시크 / 조정석:친근한 캐주얼 / 류준열:자연스러운 빈티지 / 정해인:깔끔한 청량 / 변우석:트렌디 모던 / 박형식:부드러운 동안 / 임시완:단아한 학생 / 진영:정제된 미소년

### 여성 배우/가수 (15명) — 이름:스타일키워드
김다미:청량 스트릿 / 김태리:단아한 청순 / 수지:풋풋한 자연 미인 / 한지민:우아한 럭셔리 / 박소담:시크 모던 / 김유정:청량 동안 / 김혜윤:발랄 청춘 / 신민아:도시적 시크 / 박보영:사랑스러운 동안 / 한효주:우아한 클래식 / 정유미:자연스러운 빈티지 / 김태희:차분한 럭셔리 / 손예진:우아한 청순 / 송혜교:깔끔한 단정 / 박신혜:발랄한 동안
''';

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

  // 메인 분석 (1차 호출) — 화면 진입 차단 필수 콘텐츠
  // first_impression + comparison + consultant_report + action_cards
  static Future<Map<String, dynamic>> analyzeMain({
    required Uint8List imageBytes,
    required String mimeType,
    required String animalType,
    required String gender,
    required Map<String, dynamic> faceData,
    required bool isPro,
  }) async {
    final compressed = _compressImage(imageBytes);
    final prompt = _buildMainPrompt(animalType, gender, faceData, isPro);
    return _callClaude(
      systemPrompt: _systemPrompt,
      userText: prompt,
      imageBytes: compressed,
      mimeType: 'image/jpeg',
      maxTokens: 4608, // 6144는 생성 50초+ → 타임아웃. 단축(잘리면 balancer 복구). 측정값 인용은 prompt 지시로 유지
    );
  }

  // 스타일링 분석 (2차 호출, Pro 전용) — 백그라운드로 makeup_steps + fashion_looks
  static Future<Map<String, dynamic>> analyzeStyling({
    required Uint8List imageBytes,
    required String mimeType,
    required String gender,
    required Map<String, dynamic> faceData,
  }) async {
    final compressed = _compressImage(imageBytes);
    final prompt = _buildStylingPrompt(gender, faceData);
    return _callClaude(
      systemPrompt: _stylingSystemPrompt,
      userText: prompt,
      imageBytes: compressed,
      mimeType: 'image/jpeg',
      maxTokens: 6144, // makeup 4단계 + 패션 측정값 인용 rationale로 응답 길어짐
    );
  }

  // styling용 system prompt (메인보다 더 단순)
  static const _stylingSystemPrompt =
      '당신은 스타일링 컨설턴트입니다. '
      '메이크업/패션 추천만 짧고 핵심만 JSON으로 응답. '
      '의료 권유 금지. 마크다운 백틱 금지.';

  // Claude API 호출 (HTTP REST + Vision)
  // timeout 40s, 재시도 없음 (빠른 실패 우선). 응답 도착 평균 25~35s.
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

    final sw = Stopwatch()..start();
    final res = await http.post(
      uri,
      headers: {
        'x-api-key': kAnthropicApiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
      body: body,
    ).timeout(const Duration(seconds: 65));
    sw.stop();
    debugPrint('⏱️ Claude API 응답 ${sw.elapsedMilliseconds}ms (status ${res.statusCode})');

    if (res.statusCode == 200) {
      final response = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      debugPrint('📦 Claude stop_reason=${response['stop_reason']} usage=${response['usage']}');
      final content = response['content'] as List?;
      if (content == null || content.isEmpty) {
        throw Exception('Claude empty response');
      }
      final firstText = (content.first as Map)['text']?.toString() ?? '';
      debugPrint('📝 Claude text length: ${firstText.length} chars');
      return _parseJson(firstText);
    }

    final bodyPreview = utf8.decode(res.bodyBytes);
    final clipped = bodyPreview.substring(0, bodyPreview.length.clamp(0, 200));
    throw Exception('Claude API ${res.statusCode}: $clipped');
  }

  // 메인 prompt — first_impression + action_cards + consultant_report (makeup/fashion 제외)
  static String _buildMainPrompt(
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
    final goldenRatio = faceData['golden_ratio']?.toString() ?? '-';
    final goldenDesc = faceData['golden_desc']?.toString() ?? '';
    final faceRatio = faceData['face_ratio']?.toString() ?? '-';
    final eyeGap = faceData['eye_gap_ratio']?.toString() ?? '-';
    final eyeGapDesc = faceData['eye_gap_desc']?.toString() ?? '';
    final noseWidth = faceData['nose_width_ratio']?.toString() ?? '-';
    final noseDesc = faceData['nose_desc']?.toString() ?? '';
    final symmetry = faceData['symmetry_score']?.toString() ?? '-';

    final schema = isPro ? _proMainSchema(animalType, currentFaceType) : _freeSchema(animalType, currentFaceType);

    return '''사진 속 $genderKo의 외모를 직설적으로 분석. 톤: 단점 명시 + 비의료 솔루션.

## 이 얼굴 ML Kit 실측 데이터 (아래 규칙대로만 인용)
- 얼굴형: $faceShape / ML Kit 판정 동물상: $currentFaceType
- 황금비율(이마:코:턱): $goldenRatio ($goldenDesc)
- 얼굴 가로세로 비율: $faceRatio
- 눈꼬리 각도: ${eyeAngle}° ($eyeAngleDesc)
- 눈 간격 비율: $eyeGap ($eyeGapDesc)
- 코 너비 비율: $noseWidth ($noseDesc)
- 좌우 대칭도: $symmetry
→ 측정 수치 인용은 weaknesses·action_cards·consultant_report·솔루션에만 ("황금비 $goldenRatio → ..." 식, 일반론 금지).
→ ⚠️ first_impression(summary·strengths·keywords)에는 측정 수치 넣지 말 것. 첫인상은 인상·매력·느낌 위주로 짧고 깔끔하게.

$_consultingFramework

## 분석 규칙
- weaknesses/strengths/action_cards 작성 시 위 "외모 컨설팅 도구 박스" 적극 활용.
  - 예: "삼정비 1:1:1.2 → 하안부 과대 → 외곽 정리 헤어로 시선 분산"
  - 예: "여름 쿨 톤 → 베이스 메이크업은 로즈 베이지 권장"
  - 예: "투블럭 + 윗머리 볼륨 (박서준 이태원클라쓰 헤어)"
- references 셀럽: 위 한국 셀럽 카탈로그에서 선택 (성별/스타일 매칭). 그룹명 금지.
- lookalike_celebs: 사진과 실제 닮은 한국 $genderKo 연예인 3명. 카탈로그 안 인물 우선.
- animal_distribution: 7동물상 중 3개, 합 100. 메인 1순위.
- 솔루션: 헤어/메이크업/패션/그루밍/스킨케어. 병원/클리닉/약물 금지.

$schema''';
  }

  // 스타일링 prompt — makeup_steps + fashion_looks만
  static String _buildStylingPrompt(String gender, Map<String, dynamic> faceData) {
    final genderKo = gender == 'female' ? '여성' : '남성';
    final faceShape = faceData['face_shape'] ?? '계란형';
    final goldenRatio = faceData['golden_ratio']?.toString() ?? '-';
    final goldenDesc = faceData['golden_desc']?.toString() ?? '';
    final faceRatio = faceData['face_ratio']?.toString() ?? '-';
    final eyeGap = faceData['eye_gap_ratio']?.toString() ?? '-';
    final eyeGapDesc = faceData['eye_gap_desc']?.toString() ?? '';
    final noseWidth = faceData['nose_width_ratio']?.toString() ?? '-';
    final noseDesc = faceData['nose_desc']?.toString() ?? '';

    return '''사진 속 $genderKo 기준 스타일링 추천. 메이크업 4단계 + 패션 룩 2개.

## 이 얼굴 ML Kit 실측 데이터 (추천 근거로 반드시 인용)
- 얼굴형: $faceShape
- 황금비율(이마:코:턱): $goldenRatio ($goldenDesc)
- 얼굴 가로세로 비율: $faceRatio
- 눈 간격 비율: $eyeGap ($eyeGapDesc)
- 코 너비 비율: $noseWidth ($noseDesc)
→ 모든 추천(메이크업·패션)의 rationale에 위 수치를 직접 짚어 설명. 일반론 금지.

## 도구 박스 (적극 활용)
### 컬러 시즌 4분류
- Spring Warm: 코랄, 피치, 라이트 베이지
- Summer Cool: 로즈, 라일락, 그레이
- Autumn Warm: 테라코타, 카멜, 올리브
- Winter Cool: 블랙, 와인, 쨍한 화이트

### 얼굴형별 컨투어링·블러셔 배치 ($faceShape 기준으로 적용)
- 둥근형: 광대 아래 세로 쉐딩, 블러셔 사선 위로 → 얼굴 길어 보이게
- 각진형: 턱·이마 모서리 쉐딩으로 각 완화, 블러셔 둥글게
- 긴형: 이마 위·턱 끝 가로 쉐딩으로 길이 축소, 블러셔 가로로
- 계란형: 기본 균형 유지, 광대 살짝 강조

### ${gender == 'female' ? 'K-뷰티 메이크업 4단계 (여성)' : '남성 그루밍·메이크업 4단계'}
${gender == 'female' ? '''1) 베이스: 스킨케어 → 메이크업 베이스 + 톤 보정 (글로우/매트)
2) 피부 표현: 파운데이션 + 컨실러(다크서클·잡티) + 파우더
3) 눈썹+아이: 아이브로우 + 아이섀도(시즌 컬러) + 아이라이너 + 마스카라
4) 컨투어+포인트: 얼굴형별 쉐딩/하이라이트 + 블러셔 + 립 (시즌 컬러)''' : '''1) 베이스: 세안 → 토너 → 수분크림 (남성용 라인)
2) 피부 표현: BB크림 또는 톤업크림으로 피부톤 균일화 + 가벼운 컨실러(다크서클·잡티)
3) 눈썹+아이: 눈썹 결 정리 + (선택) 연한 아이브로우
4) 컨투어+마무리: 얼굴형별 가벼운 쉐딩 + 헤어 왁스 + 향수
- 남성도 가벼운 화장 OK (BB/톤업/컨실러). 의료/시술 X.'''}

### 패션 실루엣 5분류
- 클래식 / 캐주얼 / 모던 / 스트릿 / 빈티지

## 패션 룩 작성 규칙 (중요)
- fashion_looks 2개 (서로 다른 컨셉, 예: 데일리 캐주얼 + 정장/세미포멀)
- 각 룩의 rationale에 **실측 수치 인용 + "왜 어울리는가"** 명시:
  - 예: "얼굴 가로세로 $faceRatio → 가로 볼륨 주는 라운드넥 + 레이어드로 길이감 분산. 황금비 $goldenRatio($goldenDesc)이라 심플한 핏이 비율 살림. Summer Cool이면 그레이/네이비가 피부톤 살림."
- items 각자 rationale에 "왜 이 아이템인지" 한 줄

${_stylingSchema()}''';
  }

  // _freeSchema와 _proSchema는 GeminiService와 동일한 응답 스키마 사용
  static String _freeSchema(String targetAnimal, String currentAnimal) => '''
반드시 아래 JSON 형식으로만 응답:

{
  "first_impression": {
    "summary": "첫인상 한 줄 요약",
    "face_shape": "얼굴형",
    "lookalike_celebs": [
      {"name": "한국 연예인 이름1 (개인 솔로/배우, 그룹명 금지)", "trait": "어디가 닮았는지", "work": "대표작/소속"},
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
        {"title": "강점1", "description": "짧은 설명"},
        {"title": "강점2", "description": "짧은 설명"},
        {"title": "강점3", "description": "짧은 설명"}
      ],
      "tip": "이 매력을 살리는 스타일링 팁"
    },
    "sub_animal": {"name": "보조동물상", "emoji": "🐱", "keywords": ["키워드1", "키워드2"], "comment": "짧은 설명"},
    "target_animal": {"name": "추천 변신 동물상 (자유 선택, 동물상 카탈로그 중 하나)", "emoji": "이모지", "keywords": ["키워드1", "키워드2"], "comment": "20자 이상 설명"},
    "animal_match": {
      "percentage": 80,
      "similarity_points": ["닮은 점 1", "닮은 점 2", "닮은 점 3"]
    },
    "appearance_tier": {
      "score": 7,
      "tier_name": "인스타에서 자주 보이는 유형",
      "tier_description": "1=논외 / 6=잘생김 / 7=인스타 유형 / 8=연예인급 / 9=고등급 / 10=세계급. 6~10 중 객관적 1개",
      "above_percentile": 25
    },
    "weaknesses": [
      {"title": "단점1 (예: 하안부가 큰 편)", "observation": "관찰", "impact": "인상 영향", "solution": "비의료 보완책"},
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
    "quote": "전문가 코멘트",
    "gap": "핵심 갭 요소",
    "direction": "변화 방향"
  },
  "action_cards": [
    {
      "category": "헤어스타일",
      "observation": "현재 헤어 상태",
      "impact": "인상에 미치는 영향",
      "change": "개선 방법",
      "result": "변화 후 인상",
      "application": "관찰→영향→변화→결과 연결 설명. 120자 이상.",
      "timeline": "오늘 가능",
      "gap_reduction": 15,
      "references": [{"name": "셀럽명", "context": "작품(연도)+장면+연결이유", "description": "스타일 요소"}]
    },
    {
      "category": "패션",
      "observation": "현재 패션 상태",
      "impact": "인상에 미치는 영향",
      "change": "개선 방법",
      "result": "변화 후 인상",
      "application": "관찰→영향→변화→결과 연결 설명",
      "timeline": "1주일",
      "gap_reduction": 20,
      "references": [{"name": "셀럽명", "context": "작품(연도)+장면+연결이유", "description": "스타일 요소"}]
    },
    {
      "category": "그루밍",
      "observation": "현재 그루밍 상태",
      "impact": "인상에 미치는 영향",
      "change": "개선 방법",
      "result": "변화 후 인상",
      "application": "관찰→영향→변화→결과 연결 설명",
      "references": [{"name": "셀럽명", "context": "작품(연도)+장면+연결이유", "description": "스타일 요소"}]
    }
  ]
}''';

  static String _proMainSchema(String targetAnimal, String currentAnimal) => '''
반드시 아래 JSON 형식으로만 응답:

{
  "first_impression": {
    "summary": "첫인상 한 줄 요약",
    "face_shape": "얼굴형",
    "lookalike_celebs": [
      {"name": "한국 연예인 이름1 (개인 솔로/배우, 그룹명 금지)", "trait": "어디가 닮았는지", "work": "대표작/소속"},
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
      "keywords": ["k1", "k2", "k3"],
      "strengths": [
        {"title": "강점1", "description": "이 매력이 인상에 미치는 영향을 자세히 (80자+)"},
        {"title": "강점2", "description": "자세히 (80자+)"},
        {"title": "강점3", "description": "자세히 (80자+)"}
      ],
      "tip": "이 매력을 살리는 구체 스타일링 팁"
    },
    "sub_animal": {"name": "보조동물상", "emoji": "🐱", "keywords": ["k1", "k2"], "comment": "보조 매력 자세히 (60자+)"},
    "target_animal": {"name": "추천 변신 동물상", "emoji": "이모지", "keywords": ["k1", "k2"], "comment": "왜 이 방향인지 (50자+)"},
    "animal_match": {
      "main": "$currentAnimal",
      "percentage": 80,
      "reasons": ["근거1 (60자+)", "근거2 (60자+)"],
      "similarity_points": ["닮은점1 (50자+)", "닮은점2 (50자+)", "닮은점3 (50자+)"]
    },
    "appearance_tier": {
      "score": 7,
      "tier_name": "유형명 (예: 인스타 자주 보이는 유형)",
      "above_percentile": 25,
      "target_score": 9,
      "target_percentile": 8,
      "potential_reason": "변화 시 이 점수까지 갈 수 있는 이유 (50자+)"
    },
    "weaknesses": [
      {"title": "단점1", "observation": "관찰 사실 자세히 (60자+)", "impact": "인상 영향 (50자+)", "solution": "비의료 보완책 자세히 (80자+)"},
      {"title": "단점2", "observation": "60자+", "impact": "50자+", "solution": "80자+"},
      {"title": "단점3", "observation": "60자+", "impact": "50자+", "solution": "80자+"}
    ]
  },
  "comparison": {
    "current_animal": "$currentAnimal",
    "target_animal": "$targetAnimal",
    "current_keywords": ["키워드1", "키워드2", "키워드3"],
    "target_keywords": ["키워드1", "키워드2", "키워드3"],
    "gap_percent": 45
  },
  "consultant_report_full": {
    "quote": "전문가 코멘트 (50자+)",
    "observation": "현재 관찰 (50자+)",
    "impact": "인상 영향 (50자+)",
    "gap": "핵심 갭 (40자+)",
    "direction": "변화 방향 (40자+)"
  },
  "action_cards": [
    {
      "category": "헤어스타일",
      "observation": "현재 헤어 상태 자세히 (60자+)",
      "impact": "인상에 미치는 영향 (50자+)",
      "change": "구체 개선 방법 (60자+)",
      "result": "변화 후 인상 (50자+)",
      "application": "관찰→영향→변화→결과 연결 설명 (100자+)",
      "timeline": "오늘 가능",
      "gap_reduction": 15,
      "references": [{"name": "솔로 배우/가수 이름", "context": "작품(연도)+장면+연결이유 (50자+)", "description": "스타일 요소 (40자+)"}]
    },
    {
      "category": "패션",
      "observation": "현재 패션 상태 자세히 (60자+)",
      "impact": "영향 (50자+)",
      "change": "개선 방법 (60자+)",
      "result": "결과 (50자+)",
      "application": "100자+",
      "timeline": "1주일",
      "gap_reduction": 20,
      "references": [{"name": "솔로 배우/가수 이름", "context": "50자+", "description": "40자+"}]
    },
    {
      "category": "그루밍",
      "observation": "현재 그루밍 자세히 (60자+)",
      "impact": "영향 (50자+)",
      "change": "개선 방법 (60자+)",
      "result": "결과 (50자+)",
      "application": "100자+",
      "timeline": "1주일",
      "gap_reduction": 12,
      "references": [{"name": "솔로 배우/가수 이름", "context": "50자+", "description": "40자+"}]
    }
  ]
}''';

  // styling 응답 schema — makeup_steps + fashion_looks
  static String _stylingSchema() => '''반드시 아래 JSON 형식으로만 응답:

{
  "makeup_steps": [
    {"step_number": 1, "step_name": "베이스", "description": "스킨케어+톤보정 짧게", "products": [{"name": "제품명", "shade": "색상", "category": "스킨케어/베이스", "usage": "사용법"}], "tip": "팁"},
    {"step_number": 2, "step_name": "피부 표현", "description": "파운데이션/BB+컨실러 짧게", "products": [{"name": "제품명", "shade": "색상", "category": "파운데이션/BB/컨실러", "usage": "사용법"}], "tip": "팁"},
    {"step_number": 3, "step_name": "눈썹+아이", "description": "눈썹/아이 짧게", "products": [{"name": "제품명", "shade": "색상", "category": "아이브로우/아이섀도", "usage": "사용법"}], "tip": "팁"},
    {"step_number": 4, "step_name": "컨투어+포인트", "description": "얼굴형 기반 쉐딩/블러셔/립 짧게", "products": [{"name": "제품명", "shade": "색상", "category": "쉐딩/블러셔/립", "usage": "사용법"}], "tip": "얼굴형별 배치 팁"}
  ],
  "fashion_looks": [
    {
      "name": "룩 이름1 (예: 데일리 캐주얼)",
      "image_keyword": "Unsplash 영어 키워드 — 단품/소품/플랫레이만 (인물 X, 예: 'white linen shirt flat lay product')",
      "items": [
        {"category": "Top", "description": "상의 짧게", "rationale": "왜 이 아이템 (얼굴형/체형 한 줄)"},
        {"category": "Bottom", "description": "하의 짧게", "rationale": "한 줄"},
        {"category": "Shoes", "description": "신발 짧게", "rationale": "한 줄"}
      ],
      "rationale": "왜 이 룩이 이 사람에게 어울리는가 — 얼굴형·체형·인상·컬러 시즌 매칭 자세히 (80자+)",
      "styling_tip": "팁",
      "color_palette": ["#000000", "#FFFFFF"]
    },
    {
      "name": "룩 이름2 (룩1과 다른 컨셉, 예: 세미포멀)",
      "image_keyword": "Unsplash 영어 키워드 — 단품/플랫레이만 (인물 X)",
      "items": [
        {"category": "Top", "description": "상의 짧게", "rationale": "한 줄"},
        {"category": "Bottom", "description": "하의 짧게", "rationale": "한 줄"},
        {"category": "Shoes", "description": "신발 짧게", "rationale": "한 줄"}
      ],
      "rationale": "왜 이 룩이 어울리는가 자세히 (80자+)",
      "styling_tip": "팁",
      "color_palette": ["#000000", "#808080"]
    }
  ]
}''';

  static Map<String, dynamic> _parseJson(String raw) {
    final cleaned = raw
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();
    try {
      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (_) {
      // 1차 fallback: regex로 outer { } 추출
      final match = RegExp(r'\{[\s\S]*\}').firstMatch(cleaned);
      if (match != null) {
        try {
          return jsonDecode(match.group(0)!) as Map<String, dynamic>;
        } catch (_) {}
      }
      // 2차 fallback: balancer — max_tokens로 잘린 응답 복구
      final balanced = _balanceTruncatedJson(cleaned);
      if (balanced != null) {
        try {
          debugPrint('🟠 JSON balancer: 잘린 응답 복구 시도');
          return jsonDecode(balanced) as Map<String, dynamic>;
        } catch (e) {
          debugPrint('🟠 balancer 복구 실패: $e');
        }
      }
      throw Exception('Claude JSON 파싱 실패: ${cleaned.substring(0, cleaned.length.clamp(0, 200))}');
    }
  }

  // max_tokens로 잘린 JSON을 graceful하게 복구
  // 마지막 완전한 콤마 위치까지 자르고 누락된 } ] 채워서 파싱 가능하게
  static String? _balanceTruncatedJson(String text) {
    String working = text;
    // 50회까지 시도 (마지막 필드부터 거꾸로 자르며 복구 시도)
    for (int attempt = 0; attempt < 50; attempt++) {
      // 마지막 콤마 위치 찾기 — 보통 잘린 곳 근처에 콤마 없음, 그 앞 마지막 완전한 키-값
      final lastComma = working.lastIndexOf(',');
      if (lastComma <= 0) return null;
      working = working.substring(0, lastComma);

      // 카운트: 열린 { [ vs 닫힌 } ] (string 안은 무시)
      int curly = 0, bracket = 0;
      bool inString = false, escape = false;
      for (int i = 0; i < working.length; i++) {
        final c = working[i];
        if (escape) { escape = false; continue; }
        if (c == '\\') { escape = true; continue; }
        if (c == '"') { inString = !inString; continue; }
        if (inString) continue;
        if (c == '{') curly++;
        else if (c == '}') curly--;
        else if (c == '[') bracket++;
        else if (c == ']') bracket--;
      }
      if (curly < 0 || bracket < 0) continue;
      if (inString) continue; // string 한가운데 잘림 — 더 거슬러 올라가야

      // 닫는 괄호 추가 — bracket 먼저 (안쪽), 그 다음 curly
      final balanced = working + (']' * bracket) + ('}' * curly);
      try {
        jsonDecode(balanced);
        return balanced; // 파싱 성공한 첫 결과 반환
      } catch (_) {
        // 더 거슬러 올라가서 재시도
      }
    }
    return null;
  }
}
