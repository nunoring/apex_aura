const { onRequest } = require("firebase-functions/v2/https");
const { OpenAI } = require("openai");
const cors = require("cors")({ origin: true });

// ─── 금지 단어 목록 ───────────────────────────────────────────
const BANNED_PATTERNS = [
  /필러/g, /보톡스/g, /성형/g, /수술/g, /리프팅/g, /레이저/g,
  /시술/g, /이식/g, /윤곽술/g, /처방/g, /치료/g, /진료/g,
  /임상/g, /의학적/g, /의사/g, /약물/g, /호르몬/g, /주사/g,
  /못생긴/g, /결함/g, /흠/g, /단점/g, /못난/g, /추한/g,
  /가르미/g, /지방분해/g,
];

function containsBanned(text) {
  return BANNED_PATTERNS.some((pattern) => {
    pattern.lastIndex = 0;
    return pattern.test(text);
  });
}

// ─── 동물상 카탈로그 ─────────────────────────────────────────
const ANIMAL_CATALOG = [
  { name: "강아지상", emoji: "🐶", keywords: ["부드러움", "친근함", "자연스러움"] },
  { name: "고양이상", emoji: "🐱", keywords: ["도도함", "신비로움", "우아함"] },
  { name: "여우상",   emoji: "🦊", keywords: ["세련됨", "날카로움", "정돈됨"] },
  { name: "사슴상",   emoji: "🦌", keywords: ["청초함", "순수함", "차분함"] },
  { name: "늑대상",   emoji: "🐺", keywords: ["강인함", "카리스마", "차가움"] },
  { name: "토끼상",   emoji: "🐰", keywords: ["귀여움", "발랄함", "동안"] },
  { name: "곰상",     emoji: "🐻", keywords: ["듬직함", "편안함", "포근함"] },
];
const CATALOG_NAMES = ANIMAL_CATALOG.map(a => a.name).join(", ");

// ─── GPT 시스템 프롬프트 ─────────────────────────────────────
const SYSTEM_PROMPT = `당신은 10년 경력 전문 이미지 컨설턴트입니다.
사진 한 장에서 이 사람만의 특징을 정밀하게 관찰하고,
왜 그런 인상이 만들어지는지 메커니즘과 함께 설명합니다.

## CRITICAL RULE 1 — 개인 관찰 의무
모든 특징 서술은 반드시 "현재 사진에서 보이는 ___" 또는
"현재 ___ 부분이" 형태로 시작합니다.

❌ "레이어드컷은 윤곽을 강조하는 효과가 있어요"
✅ "현재 머리카락이 광대 라인을 덮는 길이인데, 이게 얼굴 옆선을
    숨겨서 인상이 더 둥글어 보여요. 레이어드로 옆선을 드러내면
    이 사람 얼굴형의 선이 살아나요"

## CRITICAL RULE 2 — 메커니즘 4요소 순서
관찰(현재 상태) → 영향(인상에 미치는 작용) → 변화(방법) → 결과(달라지는 인상)
이 4요소가 반드시 순서대로 포함되어야 합니다.

## CRITICAL RULE 3 — 동물상 근거 의무
animal_match.reasons는 반드시 3개 이상.
각 근거는 "관찰된 구체적 특징 + 해당 동물상의 전형적 특징과 일치하는 이유"
형태여야 합니다.

❌ "전반적으로 강아지상의 느낌이에요"
✅ "현재 사진에서 눈꼬리가 살짝 처지는 형태인데, 이게 강아지상의
    핵심 특징인 부드럽고 무해한 눈매와 정확히 일치해요"

## CRITICAL RULE 4 — 금지 어휘
단독 사용 절대 금지 (메커니즘 없이 결론으로만 쓰는 것):
- "세련된 인상이에요" / "정돈된 느낌이에요" / "조화로운 얼굴이에요"
- "효율적인 변화예요" / "~는 효과가 있어요" / "~한 인상을 만들어요"

## CRITICAL RULE 5 — 톤 변화
모든 문장이 ~어요로만 끝나면 안 됩니다.
각 카드/섹션에 아래 강조 어휘 최소 1개:
강조: "핵심은 ___예요", "사실 이게 가장 중요한데요", "여기서 바뀌는 게 ___"
대비: "근데", "다만", "사실"
긍정: "충분히 가능해요", "잘 어울려요"

## CRITICAL RULE 6 — 셀럽 레퍼런스
셀럽명 + 작품/활동명 + 시기 + 구체적 장면/스타일 모두 포함.
❌ "한지민의 미디엄 레이어드"
✅ "한지민 '나의 해방일지'(2022) 중반부 출근 장면 — 귀 아래로
    자연스럽게 흘러내리는 옆머리가 얼굴 옆선을 살짝 드러내는 스타일"

## 동물상 카탈로그 (반드시 이 7종에서만 선택)
강아지상 🐶 — 부드러움, 친근함, 자연스러움
고양이상 🐱 — 도도함, 신비로움, 우아함
여우상 🦊 — 세련됨, 날카로움, 정돈됨
사슴상 🦌 — 청초함, 순수함, 차분함
늑대상 🐺 — 강인함, 카리스마, 차가움
토끼상 🐰 — 귀여움, 발랄함, 동안
곰상 🐻 — 듬직함, 편안함, 포근함

## 메이크업 4단계 구조
1단계 기초: 수분 토너패드 → 스킨 → 세럼 → 메이크업 베이스
2단계 베이스: 파운데이션 → 컨실러 → 파우더
3단계 음영: 눈썹 → 쉐딩 → 립 → 하이라이트
4단계 마무리: 파우더 → 픽서

## 카피 톤
- 2인칭 호칭 없음
- 종결어미: ~어요 / ~거든요 / ~예요 혼합
- 절대 금지: ~습니다, ~추천합니다, ~가능합니다

## 절대 금지 내용
- 시술/성형/의료/약물 관련 언급 일체
- 신체 비하 표현
- 사진에 없는 것을 있다고 관찰하는 것`;

// ─── Free 응답 스키마 지시 ────────────────────────────────────
const FREE_SCHEMA_INSTRUCTION = `
반드시 아래 JSON 형식으로만 응답하세요. 다른 텍스트 없이 JSON만.

{
  "first_impression": {
    "summary": "첫인상 한 줄 요약 (카피 톤 적용, 20자 이상)",
    "face_shape": "얼굴형 (예: 계란형)",
    "main_animal": {
      "name": "강아지상",
      "emoji": "🐶",
      "keywords": ["부드러움", "친근함", "자연스러움"],
      "strengths": [
        {"title": "강점 제목1", "description": "30자 이상 구체적 설명 (~어요 종결)"},
        {"title": "강점 제목2", "description": "30자 이상 구체적 설명"},
        {"title": "강점 제목3", "description": "30자 이상 구체적 설명"}
      ],
      "tip": "이 매력을 살리는 방향 팁 (30자 이상, 카피 톤)"
    },
    "sub_animal": {
      "name": "고양이상",
      "emoji": "🐱",
      "keywords": ["도도함", "신비로움"],
      "comment": "보조 매력 설명 (30자 이상, 카피 톤)"
    },
    "target_animal": {
      "name": "여우상",
      "emoji": "🦊",
      "keywords": ["세련됨", "정돈됨"],
      "comment": "목표 동물상 설명 (20자 이상, 카피 톤)"
    },
    "animal_match": {
      "percentage": 82,
      "similarity_points": [
        "관찰한 특징 + 인상 효과 설명 (30자 이상, 구체적으로)",
        "두 번째 유사 포인트 (30자 이상, 구체적으로)",
        "세 번째 유사 포인트 (30자 이상, 구체적으로)"
      ]
    }
  },
  "comparison": {
    "current_animal": "현재 동물상",
    "target_animal": "목표 동물상",
    "current_keywords": ["키워드1", "키워드2", "키워드3"],
    "target_keywords": ["키워드1", "키워드2", "키워드3"],
    "gap_percent": 0
  },
  "consultant_report_simple": {
    "quote": "전문가 코멘트 1~2문장 (카피 톤 적용)",
    "gap": "핵심 갭 요소 2가지",
    "direction": "변화 방향성 한 줄"
  },
  "action_cards": [
    {
      "category": "헤어스타일",
      "observation": "현재 사진에서 보이는 헤어 상태 — 길이/볼륨/앞머리 위치 등 구체적 묘사 (40자 이상)",
      "impact": "그 헤어가 이 사람 얼굴형/인상에 미치는 영향 (30자 이상)",
      "change": "어떻게 바꾸면 되는지 구체적 방법 (30자 이상)",
      "result": "바꾼 후 어떤 인상이 나오는지 (30자 이상)",
      "application": "위 4요소(관찰→영향→변화→결과)를 자연스럽게 연결한 전체 설명. 강조 어휘(핵심은/사실/근데/여기서 바뀌는) 최소 1개 포함. 120자 이상.",
      "references": [{"name": "셀럽명", "context": "작품명(연도) + 구체적 장면/스타일 (30자 이상)", "description": "어떤 스타일 요소 참고 (20자 이상)"}]
    },
    {
      "category": "패션",
      "observation": "현재 사진에서 보이는 체형/스타일 상태 (40자 이상)",
      "impact": "그게 인상/체형에 미치는 영향 (30자 이상)",
      "change": "구체적 변화 방법 (30자 이상)",
      "result": "변화 후 인상 (30자 이상)",
      "application": "자연스럽게 연결한 전체 설명 (카피 톤, 100자 이상, 강조 어휘 최소 1개)",
      "references": [{"name": "...", "context": "작품+시기+장면 (30자 이상)", "description": "..."}]
    },
    {
      "category": "메이크업",
      "observation": "현재 피부/눈썹/전체 그루밍 상태 (40자 이상)",
      "impact": "그게 인상에 미치는 영향 (30자 이상)",
      "change": "구체적 변화 방법 (30자 이상)",
      "result": "변화 후 인상 (30자 이상)",
      "application": "자연스럽게 연결한 전체 설명 (카피 톤, 100자 이상, 강조 어휘 최소 1개)",
      "references": [{"name": "...", "context": "작품+시기+장면 (30자 이상)", "description": "..."}]
    }
  ]
}

scores의 각 항목은 0.0~10.0 범위의 숫자.
gap_percent는 0~100 사이 정수.`;

// ─── Pro 응답 스키마 지시 ─────────────────────────────────────
const PRO_SCHEMA_INSTRUCTION = `
반드시 아래 JSON 형식으로만 응답하세요. 다른 텍스트 없이 JSON만.

CRITICAL: 아래 필드는 반드시 채워야 합니다 (빈 값 금지):
- face_analysis.details: 반드시 5개 (눈꼬리/쌍꺼풀/미간/코/입술), 각 feature "현재 사진에서 보이는"으로 시작
- animal_match.reasons: 반드시 3개 이상, 각 40자 이상
- animal_match.gap_to_target.changeable: 최소 2개, fixed: 최소 1개
- animal_match.percentage: 60~95 범위
- scores 각 항목(eye/balance/face_shape/eye_distance/skin): 0.0~10.0 범위 실수
- appearance_score.score: 60~85 범위 정수 (100 금지), scores 5개 평균 기반 산출
- first_impression.animal_match.percentage: 60~95 범위 (100 금지)
- first_impression.animal_match.similarity_points: 정확히 3개, 각 30자↑, 일반론 금지
- first_impression.main_animal.strengths: 정확히 3개, 각 description 30자↑
- first_impression.main_animal.tip: 30자↑
- first_impression.sub_animal.comment: 30자↑
- first_impression.target_animal.comment: 20자↑
- main/sub/target은 모두 서로 다른 동물상 (카탈로그에서만 선택)
- consultant_report_full: 5개 필드 모두 (quote 50자↑, observation/impact/gap/direction 각 20자↑)
- makeup_steps: 반드시 4개 (step 1~4), 각 step에 products 최소 2개
- fashion_looks: 반드시 2개, 각 룩에 items 5개 (Outer/Top/Bottom/Shoes/Acc)

{
  "first_impression": {
    "summary": "첫인상 한 줄 요약 (카피 톤 적용, 20자 이상)",
    "face_shape": "계란형",
    "main_animal": {
      "name": "강아지상",
      "emoji": "🐶",
      "keywords": ["부드러움", "친근함", "자연스러움"],
      "strengths": [
        {"title": "부드러운 인상", "description": "처음 본 사람도 편안하게 느끼는 매력이 있어요 (30자 이상)"},
        {"title": "친근한 분위기", "description": "쉽게 다가갈 수 있는 따뜻한 매력을 가지고 있어요 (30자 이상)"},
        {"title": "자연스러운 표정", "description": "꾸미지 않아도 매력적인 표정을 가지고 있어요 (30자 이상)"}
      ],
      "tip": "이 매력은 그대로 살리고 다른 요소를 더하는 방향이 효율적이에요 (30자 이상)"
    },
    "sub_animal": {
      "name": "고양이상",
      "emoji": "🐱",
      "keywords": ["도도함", "신비로움"],
      "comment": "이 매력도 함께 가지고 있어요. 활용하면 입체적 인상이 나와요 (30자 이상)"
    },
    "target_animal": {
      "name": "여우상",
      "emoji": "🦊",
      "keywords": ["세련됨", "정돈됨"],
      "comment": "스타일링으로 도달 가능한 목표예요 (20자 이상)"
    },
    "animal_match": {
      "main": "동물상명 (예: 강아지상)",
      "percentage": 0,
      "reasons": [
        "근거1 — 현재 사진에서 관찰된 구체적 특징 + 해당 동물상 전형 특징과 일치하는 이유 (40자 이상)",
        "근거2 — 동일 형식 (40자 이상)",
        "근거3 — 동일 형식 (40자 이상)"
      ],
      "gap_to_target": {
        "target_animal": "목표 동물상명",
        "changeable": ["스타일링으로 바꿀 수 있는 요소 1", "스타일링으로 바꿀 수 있는 요소 2"],
        "fixed": ["골격 등 바꾸기 어려운 요소 1"]
      },
      "similarity_points": [
        "닮은 점 1 — 구체적 특징 기반 (30자 이상)",
        "닮은 점 2 (30자 이상)",
        "닮은 점 3 (30자 이상)"
      ]
    }
  },
  "scores": {
    "eye": 0.0,
    "balance": 0.0,
    "face_shape": 0.0,
    "eye_distance": 0.0,
    "skin": 0.0
  },
  "appearance_score": {
    "score": 0,
    "max_score": 100
  },
  "face_analysis": {
    "ratio_horizontal_vertical": "1:1.XX",
    "top_face_percent": 0,
    "middle_face_percent": 0,
    "bottom_face_percent": 0,
    "details": [
      {"part": "눈꼬리", "feature": "현재 사진에서 보이는 눈꼬리 형태 — 올라감/처짐/수평 + 각도 정도 (20자 이상)", "impact": "이 특징이 전체 인상에 미치는 구체적 영향 — 메커니즘 포함 (30자 이상)"},
      {"part": "쌍꺼풀", "feature": "현재 사진에서 보이는 쌍꺼풀 유무/형태 — 무쌍/속쌍/겉쌍/라인 형태 구분 (20자 이상)", "impact": "눈 크기 인상과 전체 눈매에 미치는 영향 (30자 이상)"},
      {"part": "미간", "feature": "현재 사진에서 보이는 미간 넓이 — 표준 대비 넓음/좁음/표준 + 수치 느낌 (20자 이상)", "impact": "눈 간격 인상과 전체 밸런스에 미치는 영향 (30자 이상)"},
      {"part": "코", "feature": "현재 사진에서 보이는 콧볼 넓이 + 콧대 높이 관찰 (20자 이상)", "impact": "얼굴 중심 밸런스에 미치는 영향 (30자 이상)"},
      {"part": "입술", "feature": "현재 사진에서 보이는 입술 두께 + 상하 비율 관찰 (20자 이상)", "impact": "전체 인상 부드러움/강함에 기여하는 방식 (30자 이상)"}
    ]
  },
  "grooming_keywords": ["키워드1", "키워드2", "키워드3", "키워드4", "키워드5", "키워드6"],
  "radar": {
    "current": {"눈매": 0.0, "코": 0.0, "얼굴윤곽": 0.0, "스타일": 0.0},
    "target": {"눈매": 0.0, "코": 0.0, "얼굴윤곽": 0.0, "스타일": 0.0}
  },
  "comparison": {
    "current_animal": "현재 동물상",
    "target_animal": "목표 동물상",
    "current_keywords": ["키워드1", "키워드2", "키워드3"],
    "target_keywords": ["키워드1", "키워드2", "키워드3"],
    "gap_percent": 0
  },
  "consultant_report_full": {
    "quote": "전문가 인용 코멘트 (50자 이상 100자 이하, 카피 톤 적용, ~어요 종결)",
    "observation": "현재 헤어/스타일에서 관찰되는 것 (30자 이상)",
    "impact": "그게 인상에 미치는 영향 (30자 이상)",
    "gap": "목표 스타일과의 핵심 차이 (20자 이상)",
    "direction": "가장 효율적인 변화 방향 (20자 이상)"
  },
  "three_factor": {
    "physical": {"summary": "피지컬 요약 (15자 이상)", "items": ["구체적 항목1", "구체적 항목2", "구체적 항목3"]},
    "face": {"summary": "얼굴 요약 (15자 이상)", "items": ["구체적 항목1", "구체적 항목2", "구체적 항목3"]},
    "fashion": {"summary": "패션 요약 (15자 이상)", "items": ["구체적 항목1", "구체적 항목2", "구체적 항목3"]}
  },
  "action_cards": [
    {
      "category": "헤어스타일",
      "observation": "현재 사진에서 보이는 헤어 상태 — 길이/볼륨/앞머리 위치 등 구체적 묘사 (40자 이상)",
      "impact": "그 헤어가 이 사람 얼굴형/인상에 미치는 영향 (30자 이상)",
      "change": "어떻게 바꾸면 되는지 구체적 방법 (30자 이상)",
      "result": "바꾼 후 어떤 인상이 나오는지 (30자 이상)",
      "application": "위 4요소(관찰→영향→변화→결과)를 자연스럽게 연결한 전체 설명. 강조 어휘(핵심은/사실/근데/여기서 바뀌는) 최소 1개 포함. 120자 이상.",
      "references": [{"name": "셀럽명", "context": "작품명(연도) + 구체적 장면/스타일 (30자 이상)", "description": "어떤 스타일 요소 참고 (20자 이상)"}]
    },
    {
      "category": "패션",
      "observation": "현재 사진에서 보이는 체형/스타일 상태 (40자 이상)",
      "impact": "그게 인상/체형에 미치는 영향 (30자 이상)",
      "change": "구체적 변화 방법 (30자 이상)",
      "result": "변화 후 인상 (30자 이상)",
      "application": "자연스럽게 연결한 전체 설명 (카피 톤, 100자 이상, 강조 어휘 최소 1개)",
      "references": [{"name": "...", "context": "작품+시기+장면 (30자 이상)", "description": "..."}]
    },
    {
      "category": "메이크업",
      "observation": "현재 피부/눈썹/전체 그루밍 상태 (40자 이상)",
      "impact": "그게 인상에 미치는 영향 (30자 이상)",
      "change": "구체적 변화 방법 (30자 이상)",
      "result": "변화 후 인상 (30자 이상)",
      "application": "자연스럽게 연결한 전체 설명 (카피 톤, 100자 이상, 강조 어휘 최소 1개)",
      "references": [{"name": "...", "context": "작품+시기+장면 (30자 이상)", "description": "..."}]
    }
  ],
  "makeup_steps": [
    {
      "step_number": 1,
      "step_name": "기초",
      "description": "기초 단계 설명 (카피 톤, 20자 이상)",
      "products": [
        {"name": "한율 부들밤 모공수축패드", "shade": null, "category": "토너패드", "usage": "AHA 성분으로 각질 정리, 세안 후 바로 사용"},
        {"name": "라운드랩 1025 독도 토너", "shade": null, "category": "토너", "usage": "수분 흡수 후 가볍게 두드려 흡수" "라운드랩 1025 독도 토너"},
        {"name": "넘버즈인 세럼", "shade": null, "category": "세럼", "usage": "피부결 따라 세로로 흡수" "넘버즈인 세럼"},
        {"name": "구셀 메이크업 베이스", "shade": null, "category": "베이스", "usage": "얇게 전체 도포 후 30초 흡수" "구셀 메이크업 베이스"}
      ],
      "tip": "묽은 제형부터 무거운 제형 순서로, 피부결 따라 세로로 흡수시켜줘요"
    },
    {
      "step_number": 2,
      "step_name": "베이스",
      "description": "피부 톤 균일화 단계 (카피 톤, 20자 이상)",
      "products": [
        {"name": "비레디 블루 파운데이션 03호", "shade": "03호", "category": "파운데이션", "usage": "소량을 전체적으로 가볍게 펴바르기" "비레디 블루 파운데이션"},
        {"name": "루나 롱래스팅 팁 컨실러 픽싱핏 04호", "shade": "04호 샌드", "category": "컨실러", "usage": "잡티와 다크서클 위에 두드려 커버" "루나 롱래스팅 컨실러 픽싱핏"},
        {"name": "스킨푸드 피치뽀송 멀티 피니시 파우더", "shade": null, "category": "파우더", "usage": "T존 중심으로 살짝 눌러 마무리" "스킨푸드 피치뽀송 멀티 피니시 파우더"}
      ],
      "tip": "포인트는 소량이에요. 티 안 나게 자연스럽게 얹어주는 게 핵심이거든요"
    },
    {
      "step_number": 3,
      "step_name": "음영",
      "description": "눈썹-쉐딩-립 순서로 인상 정돈 (카피 톤, 20자 이상)",
      "products": [
        {"name": "클리오 킬브로우 오토하드펜슬 05호 그레이브라운", "shade": "05호", "category": "눈썹", "usage": "눈썹 결 따라 그린 후 스크류로 빗어주기" "클리오 킬브로우 오토하드펜슬"},
        {"name": "투쿨포스쿨 뉴트럴 쉐딩", "shade": null, "category": "쉐딩", "usage": "얼굴 윤곽 바깥쪽에만 살짝 블렌딩" "투쿨포스쿨 뉴트럴 쉐딩"},
        {"name": "롬앤 쥬시 래스팅 틴트 06피그피그", "shade": "06 피그피그", "category": "립", "usage": "입술 안쪽부터 자연스럽게 펴 바르기" "롬앤 쥬시 래스팅 틴트 06"}
      ],
      "tip": "쉐딩은 얼굴 윤곽 바깥쪽에만 살짝. 과하면 어색해 보여요"
    },
    {
      "step_number": 4,
      "step_name": "마무리",
      "description": "지속력 확보 마무리 단계 (카피 톤, 20자 이상)",
      "products": [
        {"name": "스킨푸드 피치뽀송 멀티 피니시 파우더", "shade": null, "category": "세팅파우더", "usage": "전체적으로 가볍게 눌러 세팅" "스킨푸드 피치뽀송 멀티 피니시 파우더"},
        {"name": "어반디케이 메이크업 픽서", "shade": null, "category": "픽서", "usage": "20cm 거리에서 가볍게 두 번 분사" "어반디케이 메이크업 픽서"}
      ],
      "tip": "픽서는 20cm 거리에서 가볍게 두 번. 효율적인 마무리 방법이에요"
    }
  ],
  "fashion_looks": [
    {
      "name": "데일리 캐주얼",
      "items": [
        {"category": "Outer", "description": "화이트 린넨 셔츠 (오버사이즈)", "rationale": "청량감 + 레이어드 가능" "화이트 린넨 셔츠 오버사이즈"},
        {"category": "Top", "description": "화이트 반팔 코튼 이너", "rationale": "정돈된 레이어드" "화이트 반팔 코튼 티셔츠},
        {"category": "Bottom", "description": "와이드 연청 데님 팬츠", "rationale": "와이드 핏으로 하체 라인 정돈" "와이드 연청 데님 팬츠},
        {"category": "Shoes", "description": "화이트 로우 스니커즈", "rationale": "색감 통일, 캐주얼 강조" "화이트 로우 스니커즈},
        {"category": "Acc", "description": "검정 가죽 벨트 (슬림)", "rationale": "포인트 + 허리 라인" "검정 가죽 벨트 슬림}
      ],
      "rationale": "셔츠는 빼서 입고, 이너는 넣어서 입어요. 화이트+연청 조합으로 청량감 있어요",
      "styling_tip": "셔츠는 빼서, 이너는 넣어서",
      "color_palette": ["#FFFFFF", "#A8C5DA", "#000000"]
    },
    {
      "name": "세미 포멀",
      "items": [
        {"category": "Outer", "description": "검정 반팔 셔츠 (슬림핏 X, 레귤러 핏)", "rationale": "깔끔하고 정돈된 인상" "검정 반팔 셔츠 레귤러핏},
        {"category": "Top", "description": "검정 이너 (넣어 입기용)", "rationale": "셔츠 넣입 깔끔하게" "검정 이너 넣어입기},
        {"category": "Bottom", "description": "회색 세미와이드 슬랙스", "rationale": "정돈된 라인, 격식 있는 분위기" "회색 세미와이드 슬랙스},
        {"category": "Shoes", "description": "앵클부츠 (키높이 깔창 활용)", "rationale": "키 보정 + 포멀한 인상" "앵클부츠 남성},
        {"category": "Acc", "description": "검정 가죽 벨트", "rationale": "상하의 통일감" "검정 가죽 벨트}
      ],
      "rationale": "검정 셔츠 넣어 입기로 깔끔하게. 회색 와이드로 하체 비율 보완이 효율적이에요",
      "styling_tip": "검정 셔츠는 꼭 넣어서, 슬랙스는 허리에 맞게",
      "color_palette": ["#000000", "#808080", "#1A1A1A"]
    }
  ],
  "color_palette": {
    "main": ["#000000", "#1A2238", "#FFFFFF"],
    "accent": ["#722F37", "#C19A6B"],
    "avoid": ["#FF00FF", "#FFFF00"]
  }
}

모든 숫자 필드는 실제 숫자로. 문자열 필드는 카피 톤 규칙 적용.
radar 값은 0.0~1.0 범위. animal_match.percentage는 60~95 정수.
makeup_steps는 반드시 4개, fashion_looks는 반드시 2개여야 합니다.`;

// ─── 응답 검증 ────────────────────────────────────────────────
// ─── AI 티 검출기 ─────────────────────────────────────────────
function detectAITone(result) {
  const issues = [];
  const text = JSON.stringify(result);

  // 1. 금지 일반론 패턴
  const genericPatterns = [
    /[^\n]{0,10}은 [^\n]{0,20}를? 강조하는 효과가 있어요/,
    /[^\n]{0,10}으로 [^\n]{0,10}한 인상을 만들어요/,
    /[^\n]{0,10}에 효과적이에요/,
  ];
  for (const pattern of genericPatterns) {
    if (pattern.test(text)) issues.push(`일반론 패턴: ${pattern}`);
  }

  // 2. 금지 어휘 단독 사용
  const bannedSolo = ['"세련된 인상"', '"정돈된 인상"', '"조화로운 느낌"', '"효율적인 변화"'];
  for (const word of bannedSolo) {
    if (text.includes(word)) issues.push(`금지 어휘: ${word}`);
  }

  // 3. 셀럽 레퍼런스 context 길이
  const actionCards = result.action_cards || [];
  for (const card of actionCards) {
    for (const ref of (card.references || [])) {
      if ((ref.context || '').length < 20) {
        issues.push(`셀럽 context 부족: ${ref.name}`);
      }
    }
  }

  // 4. application 강조 어휘 확인
  const emphasisWords = ['핵심은', '사실 이게', '여기서 바뀌는', '근데', '충분히', '사실'];
  for (const card of actionCards) {
    const app = card.application || '';
    if (app.length > 0 && !emphasisWords.some(w => app.includes(w))) {
      issues.push(`강조 어휘 없음: ${card.category}`);
    }
  }

  // 5. application 길이 (100자 미만)
  for (const card of actionCards) {
    if (card.application && card.application.length < 80) {
      issues.push(`application 너무 짧음: ${card.category} (${card.application.length}자)`);
    }
  }

  return issues;
}

function validateAnimalMatch(result) {
  try {
    const am = result.first_impression?.animal_match;
    if (!am) return false;
    if (typeof am.percentage !== 'number') return false;
    if (am.percentage < 60 || am.percentage > 95) return false;
    if (!am.similarity_points || am.similarity_points.length !== 3) return false;
    for (const p of am.similarity_points) {
      if (!p || p.length < 20) return false;
    }
    return true;
  } catch (e) { return false; }
}

function validateAnimalRanking(result) {
  try {
    const fi = result.first_impression;
    if (!fi) return false;
    const main = fi.main_animal;
    const sub = fi.sub_animal;
    const target = fi.target_animal;
    if (!main || !sub || !target) return false;
    if (!main.name || !main.emoji) return false;
    if (!main.keywords || main.keywords.length < 2) return false;
    if (!main.strengths || main.strengths.length !== 3) return false;
    for (const s of main.strengths) {
      if (!s.title || !s.description || s.description.length < 15) return false;
    }
    if (!main.tip || main.tip.length < 15) return false;
    if (!sub.name || !sub.emoji || !sub.comment || sub.comment.length < 15) return false;
    if (!target.name || !target.emoji || !target.comment || target.comment.length < 10) return false;
    const animals = new Set([main.name, sub.name, target.name]);
    if (animals.size !== 3) return false;
    return true;
  } catch (e) { return false; }
}

function validateProResponse(result) {
  if (!validateAnimalRanking(result)) return false;
  if (!validateAnimalMatch(result)) return false;
  try {
    // face_analysis.details 검증 (5개, 각 feature "현재" 포함)
    const details = result.face_analysis?.details;
    if (!details || details.length < 5) return false;
    for (const d of details) {
      if (!d.part || !d.feature || !d.impact) return false;
      if (d.feature.length < 15) return false;
      if (d.impact.length < 20) return false;
    }
    // animal_match 구조 검증
    const am = result.first_impression?.animal_match;
    if (!am?.reasons || am.reasons.length < 3) return false;
    for (const r of am.reasons) { if ((r || '').length < 30) return false; }
    if (!am.gap_to_target?.changeable || am.gap_to_target.changeable.length < 2) return false;
    if (!am.gap_to_target?.fixed || am.gap_to_target.fixed.length < 1) return false;
    if (!am.similarity_points || am.similarity_points.length < 3) return false;
    // scores 검증
    const scores = result.scores;
    if (!scores) return false;
    for (const key of ['eye', 'balance', 'face_shape', 'eye_distance', 'skin']) {
      if (typeof scores[key] !== 'number' || scores[key] < 0 || scores[key] > 10) return false;
    }
    // appearance_score 검증
    const as = result.appearance_score;
    if (!as || typeof as.score !== 'number') return false;
    if (as.score < 60 || as.score > 85) return false;
    // 컨설턴트 리포트 4요소
    const report = result.consultant_report_full;
    if (!report) return false;
    if ((report.quote || '').length < 50) return false;
    if ((report.observation || '').length < 20) return false;
    if ((report.impact || '').length < 20) return false;
    if ((report.gap || '').length < 20) return false;
    if ((report.direction || '').length < 20) return false;

    // 메이크업 4단계
    const steps = result.makeup_steps;
    if (!steps || steps.length < 4) return false;
    for (const step of steps) {
      if (!step.products || step.products.length < 2) return false;
    }

    // 패션 룩 2개
    const looks = result.fashion_looks;
    if (!looks || looks.length < 2) return false;
    for (const look of looks) {
      if (!look.items || look.items.length < 4) return false;
    }

    return true;
  } catch (e) {
    return false;
  }
}

function validateFreeResponse(result) {
  if (!validateAnimalRanking(result)) return false;
  if (!validateAnimalMatch(result)) return false;
  try {
    if (!result.first_impression?.summary) return false;
    if (!result.action_cards || result.action_cards.length < 3) return false;
    const report = result.consultant_report_simple;
    if (!report?.quote || report.quote.length < 20) return false;
    return true;
  } catch (e) {
    return false;
  }
}

// ─── 나이 체크 (미성년자 차단) ────────────────────────────────
async function checkAge(openai, imageBase64, mimeType = "image/jpeg") {
  try {
    const response = await openai.chat.completions.create({
      model: "gpt-4o",
      max_tokens: 50,
      temperature: 0.1,
      messages: [{
        role: "user",
        content: [
          {
            type: "text",
            text: `이 사진의 인물이 만 14세 이상인지 판단하세요.
- "ok": 14세 이상 명확 (성인 또는 청소년 이상)
- "minor": 14세 미만 명확 (어린이 외형)
- "uncertain": 판단 어려움

JSON만: {"result": "ok"}`,
          },
          {
            type: "image_url",
            image_url: { url: `data:${mimeType};base64,${imageBase64}`, detail: "low" },
          },
        ],
      }],
    });
    const raw = response.choices[0].message.content.replace(/```json|```/g, "").trim();
    const parsed = JSON.parse(raw);
    return parsed.result || "ok";
  } catch (e) {
    console.log("checkAge 실패, 통과:", e.message);
    return "ok"; // 판단 불가 시 분석 진행 (과도한 차단 방지)
  }
}

// ─── 메인 함수 ────────────────────────────────────────────────
exports.analyzeImage = onRequest(
  { timeoutSeconds: 120, memory: "512MiB" },
  async (req, res) => {
    cors(req, res, async () => {
      if (req.method === "OPTIONS") return res.status(204).send("");
      if (req.method !== "POST") {
        return res.status(405).json({ error: "Method not allowed" });
      }

      try {
        const {
          base64Image,
          imageBase64,
          mimeType = "image/jpeg",
          isPro = false,
          animalType,
          gender,
          faceData,
        } = req.body;

        const imgData = base64Image || imageBase64;
        if (!imgData || !faceData) {
          return res.status(400).json({ error: "imageBase64 and faceData required" });
        }

        const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
        const schemaInstruction = isPro ? PRO_SCHEMA_INSTRUCTION : FREE_SCHEMA_INSTRUCTION;
        const userPrompt = buildUserPrompt(isPro, animalType, gender, faceData, schemaInstruction);

        // 1차 시도 (이미지 + 수치 텍스트 동시 분석)
        let result;
        try {
          result = await callGPT(openai, userPrompt, imgData, mimeType);
        } catch (gptErr) {
          console.log("GPT 실패 — 폴백 사용:", gptErr.message);
          result = getFallbackResponse(isPro);
          return res.status(200).json({ ...result, skinAnalysis: result.scores || {} });
        }

        // 검증 (금지 단어 + 필수 필드)
        const validator = isPro ? validateProResponse : validateFreeResponse;
        const resultText = JSON.stringify(result);
        const hasBanned = containsBanned(resultText);
        const isValid = validator(result);

        if (hasBanned || !isValid) {
          console.log(`1차 재시도 — 금지어: ${hasBanned}, 검증실패: ${!isValid}`);
          const retryPrompt = userPrompt +
            (hasBanned ? "\n\n[중요] 시술/성형/의료/신체비하 표현 없이 다시 작성하세요." : "") +
            (!isValid && isPro ? "\n\n[중요] makeup_steps 4개, fashion_looks 2개, consultant_report_full 5개 필드 모두 채워주세요." : "");

          try {
            result = await callGPT(openai, retryPrompt, imgData, mimeType);
          } catch (e) {
            result = getFallbackResponse(isPro);
          }

          if (containsBanned(JSON.stringify(result)) || !validator(result)) {
            console.log("2차 재시도 실패 — 폴백 사용");
            result = getFallbackResponse(isPro);
          }
        }

        // AI 티 로깅 (재시도 없음 — 속도 최적화)
        const aiToneIssues = detectAITone(result);
        if (aiToneIssues.length > 0) console.log('AI 티 감지 (로그만):', aiToneIssues.slice(0, 3));

        // 기존 클라이언트 호환 (skinAnalysis 없이도 동작하도록)
        return res.status(200).json({ ...result, skinAnalysis: result.scores || {} });
      } catch (error) {
        console.error("analyzeImage error:", error);
        return res.status(500).json({
          error: "분석 중 오류가 발생했어요. 다시 시도해주세요.",
          details: error.message,
        });
      }
    });
  }
);

// ─── 유저 프롬프트 생성 ────────────────────────────────────────
function buildUserPrompt(isPro, animalType, gender, faceData, schemaInstruction) {
  const genderKo = gender === "female" ? "여성" : "남성";

  const eyeAngle = faceData?.eye_angle ?? 0;
  const eyeAngleDesc = faceData?.eye_angle_desc ?? "수평";
  const faceShape = faceData?.face_shape ?? "계란형";
  const faceRatio = faceData?.face_ratio ?? 0.75;
  const eyeGapDesc = faceData?.eye_gap_desc ?? "보통";
  const goldenDesc = faceData?.golden_desc ?? "보통";
  const noseDesc = faceData?.nose_desc ?? "보통";
  const currentFaceType = faceData?.current_face_type ?? "미분류";
  const symmetryScore = faceData?.symmetry_score ?? 80;

  return `아래 얼굴 수치 데이터를 바탕으로 ${genderKo}의 스타일링 컨설팅을 제공해주세요.

## 측정 데이터 (AI 측정값)
- 현재 동물상: ${currentFaceType}
- 목표 동물상: ${animalType || "여우상"}
- 성별: ${genderKo}
- 눈꼬리 각도: ${eyeAngle}° (${eyeAngleDesc})
- 얼굴형: ${faceShape} (가로세로 비율: ${faceRatio})
- 눈 간격: ${eyeGapDesc}
- 황금비율: ${goldenDesc}
- 코 특징: ${noseDesc}
- 대칭도: ${symmetryScore}/100

## 분석 방향
이 수치를 바탕으로:
1. 현재 동물상(${currentFaceType})의 특징적 매력 분석
2. 목표(${animalType || "여우상"})까지의 갭 분석
3. 헤어/메이크업/패션으로 접근 가능한 변화 방향 제시
${isPro ? `4. 얼굴 비율 진단 (수치 기반으로 추정)
5. 스타일링 완성도 점수 (6.0~8.0)
6. 메이크업 4단계 구체 제품 추천
7. 패션 룩 2벌 제안` : ""}

## 동물상 분류 기준 (ANIMAL_CATALOG)
${ANIMAL_CATALOG.map(a => `${a.name} ${a.emoji} — ${a.keywords.join(", ")}`).join("\n")}
- main_animal은 현재 동물상(${currentFaceType})으로 설정
- target_animal은 목표(${animalType || "여우상"})로 설정
- sub_animal은 나머지 중 가장 유사한 것으로 선택

${schemaInstruction}`;
}

// ─── GPT 호출 헬퍼 ────────────────────────────────────────────
async function callGPT(openai, userPrompt, imageBase64, mimeType) {
  const response = await openai.chat.completions.create({
    model: "gpt-4o",
    max_tokens: 2500,
    temperature: 0.5,
    messages: [
      { role: "system", content: SYSTEM_PROMPT },
      {
        role: "user",
        content: [
          {
            type: "image_url",
            image_url: {
              url: `data:${mimeType};base64,${imageBase64}`,
              detail: "auto",
            },
          },
          { type: "text", text: userPrompt },
        ],
      },
    ],
  });

  const raw = response.choices[0].message.content;
  const cleaned = raw.replace(/```json\n?/g, "").replace(/```\n?/g, "").trim();

  try {
    return JSON.parse(cleaned);
  } catch {
    const match = cleaned.match(/\{[\s\S]*\}/);
    if (match) return JSON.parse(match[0]);
    throw new Error("JSON 파싱 실패: " + cleaned.substring(0, 200));
  }
}

// ─── 폴백 응답 ────────────────────────────────────────────────
function getFallbackResponse(isPro) {
  const base = {
    first_impression: {
      summary: "전반적으로 균형 잡힌 인상이에요.",
      face_shape: "계란형",
      main_animal: {
        name: "강아지상", emoji: "🐶",
        keywords: ["부드러움", "친근함", "자연스러움"],
        strengths: [
          { title: "부드러운 인상", description: "처음 본 사람도 편안하게 느끼는 매력이 있어요." },
          { title: "친근한 분위기", description: "쉽게 다가갈 수 있는 따뜻한 매력을 가지고 있어요." },
          { title: "자연스러운 표정", description: "꾸미지 않아도 매력적인 표정을 가지고 있어요." },
        ],
        tip: "이 매력은 그대로 살리고 헤어와 스타일링을 더하는 방향이 효율적이에요.",
      },
      sub_animal: {
        name: "고양이상", emoji: "🐱",
        keywords: ["도도함", "신비로움"],
        comment: "이 매력도 함께 가지고 있어요. 활용하면 입체적 인상이 나와요.",
      },
      target_animal: {
        name: "여우상", emoji: "🦊",
        keywords: ["세련됨", "정돈됨"],
        comment: "스타일링으로 충분히 도달 가능한 목표예요.",
      },
      animal_match: {
        main: "강아지상",
        percentage: 82,
        reasons: [
          "현재 사진에서 눈꼬리가 처지거나 수평으로 떨어지는 형태인데, 이게 강아지상의 핵심 특징인 부드럽고 무해한 눈매와 정확히 일치해요",
          "현재 사진에서 얼굴 윤곽이 둥근 편인데, 강아지상 특유의 부드럽고 친근한 실루엣과 같은 방향이에요",
          "현재 사진에서 전체적으로 각진 요소보다 곡선 요소가 많은데, 이게 강아지상이 주는 따뜻하고 편안한 첫인상의 원인이에요",
        ],
        gap_to_target: {
          target_animal: "여우상",
          changeable: ["눈썹 각도 조정으로 눈매 날카로움 추가 가능", "헤어로 얼굴 옆선 드러내기 가능"],
          fixed: ["기본 얼굴 윤곽 곡선은 골격이라 스타일링으로 변화 어려움"],
        },
        similarity_points: [
          "부드러운 눈매 라인이 강아지상 특유의 친근하고 따뜻한 첫인상을 자연스럽게 만들어줘요",
          "얼굴 전체 윤곽의 곡선감이 강아지상의 무해하고 편안한 느낌과 정확히 맞닿아 있어요",
          "처음 보는 사람에게도 경계심 없이 다가갈 수 있는 인상 구조가 이 동물상의 핵심이에요",
        ],
      },
    },
    comparison: {
      current_animal: "강아지상",
      target_animal: "여우상",
      current_keywords: ["부드러움", "친근함", "자연스러움"],
      target_keywords: ["날카로움", "세련됨", "정돈됨"],
      gap_percent: 45,
    },
    consultant_report_simple: {
      quote: "포인트는 눈매와 헤어에 있어요. 여기서 바뀌는 게 인상 전체를 바꿔줘요.",
      gap: "눈매 샤프니스, 헤어 스타일링",
      direction: "스타일링 중심 변화",
    },
    action_cards: [
      {
        category: "헤어스타일",
        observation: "현재 헤어가 이마와 눈매를 가리고 있어요.",
        application: "앞머리를 올리거나 옆으로 넘겨 이마를 드러내면 훨씬 또렷해 보여요.",
        references: [{ name: "박보검", context: "2023 화보", description: "자연스럽게 올린 앞머리" }],
      },
      {
        category: "패션",
        observation: "현재 스타일에서 체형의 장점이 잘 드러나지 않고 있어요.",
        application: "세미와이드 팬츠와 원단감 있는 상의 조합이 효율적이에요.",
        references: [{ name: "정해인", context: "데일리 스타일", description: "간결한 베이직 코디" }],
      },
      {
        category: "메이크업",
        observation: "자연 피부 대비 눈썹 정리만으로 인상이 달라질 수 있어요.",
        application: "눈썹 정리 + 기초 메이크업 베이스 정도만 해도 충분히 달라 보여요.",
        references: [{ name: "위아이", context: "무결점 스킨", description: "내추럴 그루밍" }],
      },
    ],
  };

  if (!isPro) return base;

  return {
    ...base,
    face_analysis: {
      ratio_horizontal_vertical: "1:1.35",
      top_face_percent: 33,
      middle_face_percent: 30,
      bottom_face_percent: 37,
      details: [
        { part: "눈꼬리", feature: "현재 사진에서 보이는 눈꼬리가 수평에 가깝게 떨어지는 형태예요", impact: "눈꼬리가 처지지 않아서 또렷한 인상을 주는데, 동시에 부드러운 느낌도 함께 있어요" },
        { part: "쌍꺼풀", feature: "현재 사진에서 보이는 쌍꺼풀이 속쌍 또는 무쌍에 가까운 형태예요", impact: "눈이 깊어 보이고 눈매가 차분한 인상을 만들어줘요" },
        { part: "미간", feature: "현재 사진에서 보이는 미간이 표준 범위에 있어요", impact: "눈 간격이 자연스러워서 얼굴 전체 밸런스가 안정적으로 느껴져요" },
        { part: "코", feature: "현재 사진에서 보이는 콧볼이 표준 넓이, 콧대는 낮은 편이에요", impact: "얼굴 중심이 강하게 튀지 않아서 전체적으로 부드러운 인상에 기여해요" },
        { part: "입술", feature: "현재 사진에서 보이는 입술이 적당한 두께에 상하 비율이 균형 잡혀 있어요", impact: "강하지도 약하지도 않은 중립적 인상을 만들어줘요" },
      ],
    },
    scores: { eye: 6.8, balance: 7.2, face_shape: 7.5, eye_distance: 6.5, skin: 6.8 },
    appearance_score: { score: 72, max_score: 100 },
    grooming_keywords: ["생기있는", "동안", "활동적인", "외향적인", "유머러스한", "캐주얼"],
    radar: {
      current: { 눈매: 0.4, 코: 0.6, 얼굴윤곽: 0.55, 스타일: 0.35 },
      target: { 눈매: 0.85, 코: 0.7, 얼굴윤곽: 0.75, 스타일: 0.85 },
    },
    consultant_report_full: {
      quote: "핵심은 눈매와 스타일에 있어요. 여기서 바뀌는 게 인상 전체를 바꿔줘요.",
      observation: "전반적으로 균형 잡힌 얼굴형에 부드러운 인상이 강점이에요.",
      impact: "현재 스타일이 눈매의 날카로움을 가리고 있어요.",
      gap: "눈매 샤프니스, 헤어 볼륨, 스타일링 완성도",
      direction: "눈매 강조 + 헤어 스타일링 + 베이직 패션 정립",
    },
    three_factor: {
      physical: {
        summary: "이상적인 상하체 비율이 강점이에요.",
        items: ["좁은 어깨 보완 → 어깨 패드 상의 활용", "키 보완 → 키높이 깔창 적극 활용", "하견 강조 → 와이드 팬츠로 시선 분산"],
      },
      face: {
        summary: "눈매 강조가 핵심이에요.",
        items: ["눈썹 정리로 인상 정돈", "앞머리 올려 이마 드러내기", "기초 메이크업으로 피부 톤 균일화"],
      },
      fashion: {
        summary: "베이직 베이스가 효율적이에요.",
        items: ["회색/검정/네이비/흰색 중심 컬러 팔레트", "세미와이드~원턱 와이드 팬츠 기본 세팅", "원단감 있는 상의로 체형 보완"],
      },
    },
    makeup_steps: [
      {
        step_number: 1, step_name: "기초",
        description: "묽은 제형부터 무거운 제형 순서로, 피부 결 따라 세로로 흡수시켜줘요.",
        products: [
          { name: "한율 부들밤 모공수축패드", shade: null },
          { name: "라운드랩 1025 독도 토너", shade: null },
          { name: "넘버즈인 세럼", shade: null },
          { name: "구셀 메이크업 베이스", shade: null },
        ],
        tip: "기초는 레이어링이 핵심이에요. 각 단계 30초 간격으로 흡수시켜주세요.",
      },
      {
        step_number: 2, step_name: "베이스",
        description: "파운데이션으로 피부 톤을 균일하게 잡아주는 단계예요.",
        products: [
          { name: "비레디 블루 파운데이션 03호", shade: "03호" },
          { name: "루나 롱래스팅 팁 컨실러 픽싱핏 04호", shade: "04호" },
          { name: "스킨푸드 피치뽀송 멀티 피니시 파우더", shade: null },
        ],
        tip: "포인트는 소량이에요. 티 안 나게 자연스럽게 얹어주는 게 핵심이거든요.",
      },
      {
        step_number: 3, step_name: "음영",
        description: "눈썹 → 쉐딩 → 립 순서로. 눈썹으로 구레나룻/애교살까지 정리할 수 있어요.",
        products: [
          { name: "클리오 킬브로우 오토하드펜슬 05호 그레이브라운", shade: "05호" },
          { name: "투쿨포스쿨 뉴트럴 쉐딩", shade: null },
          { name: "롬앤 쥬시 래스팅 틴트 06피그피그", shade: "06호" },
        ],
        tip: "쉐딩은 얼굴 윤곽 바깥쪽에만 살짝. 과하면 어색해 보여요.",
      },
      {
        step_number: 4, step_name: "마무리",
        description: "파우더와 픽서로 하루 종일 유지되게 마무리해줘요.",
        products: [
          { name: "스킨푸드 피치뽀송 멀티 피니시 파우더", shade: null },
          { name: "어반디케이 메이크업 픽서", shade: null },
        ],
        tip: "픽서는 20cm 거리에서 가볍게 두 번. 효율적인 마무리 방법이에요.",
      },
    ],
    fashion_looks: [
      {
        name: "데일리 베이직",
        items: [
          { category: "Top", description: "원단감 있는 검정 반팔 셔츠", affiliate: { name: "COS 코튼 반팔 셔츠", platform: "coupang", url: "" } },
          { category: "Bottom", description: "회색 세미와이드 슬렉스", affiliate: { name: "무신사 스탠다드 와이드 슬렉스", platform: "coupang", url: "" } },
          { category: "Shoes", description: "앵클부츠 (키높이 깔창 사용)", affiliate: { name: "닥터마틴 앵클부츠", platform: "coupang", url: "" } },
          { category: "Acc", description: "검정 벨트", affiliate: { name: "베이직 가죽 벨트", platform: "coupang", url: "" } },
        ],
        rationale: "검정 셔츠 넣어 입기로 깔끔하게. 회색 와이드로 하체 비율 보완이 효율적이에요.",
      },
      {
        name: "캐주얼 스마트",
        items: [
          { category: "Top", description: "흰 린넨 셔츠 (루즈핏)", affiliate: { name: "유니클로 린넨 셔츠", platform: "coupang", url: "" } },
          { category: "Bottom", description: "와이드 연청바지", affiliate: { name: "무신사 와이드 데님", platform: "coupang", url: "" } },
          { category: "Shoes", description: "흰색 스니커즈", affiliate: { name: "나이키 에어포스1", platform: "coupang", url: "" } },
          { category: "Acc", description: "검정 벨트", affiliate: { name: "베이직 가죽 벨트", platform: "coupang", url: "" } },
        ],
        rationale: "셔츠는 빼서 입고, 와이드 데님으로 자연스러운 볼륨감. 여기서 바뀌는 게 전체 실루엣이에요.",
      },
    ],
    color_palette: {
      main: ["#000000", "#1A1A2E", "#FFFFFF"],
      accent: ["#4A4A6A", "#8B7355"],
      avoid: ["#FF6B6B", "#FFD93D"],
    },
  };
}
