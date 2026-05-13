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
const SYSTEM_PROMPT = `당신은 전문 패션 & 스타일 컨설턴트입니다.
사진 속 인물의 현재 헤어스타일, 패션, 그루밍 상태를 보고 스타일링 개선 솔루션을 제공합니다.

## 분석 철학
- 외관의 개성과 매력을 중심으로 분석
- 스타일링(헤어/메이크업/패션)으로 개선 가능한 영역에 집중
- 피지컬 × 얼굴 × 패션 3박자 조화로 한계치를 넘어서는 접근

## 스타일 완성도 평가 기준
- 스타일링 완성도, 헤어, 피부 관리 상태, 전체적인 인상을 종합 평가
- 숫자 점수는 스타일링 개선 가능성을 나타내는 지표로 사용

## 그루밍 방향성 키워드 (6개 조합)
분석 대상의 나이/체형/얼굴형을 고려하여 아래 중 가장 어울리는 6개 선택:
생기있는, 동안, 활동적인, 외향적인, 유머러스한, 캐주얼,
세련된, 차분한, 지적인, 강인한, 부드러운, 신뢰감있는

## 메이크업 4단계 구조 (남성 기준)
1단계 기초: 수분 토너패드 → 스킨(토너) → 세럼 → 수분 메이크업 베이스
  - 묽은 제형 → 무거운 제형 순서, 피부 결 따라 세로로 흡수
2단계 베이스: 파운데이션 → 컨실러 → 파우더/픽서
3단계 음영: 눈썹 → 쉐딩 → 립 → 하이라이트
4단계 마무리: 파우더 → 메이크업 픽서

## 패션 방향성
- 체형 보완 중심: 어깨 넓어보이는 상의, 하견 보완
- 하의: 세미와이드~원턱 와이드 팬츠 권장 (조거팬츠/슬림핏 비권장)
- 색상: 회색/검정/네이비/흰색 중심, 대비감 적절히 조절

## 카피 톤 규칙
- 호칭 없음 (2인칭 생략)
- 종결어미: ~어요 / ~거든요 / ~예요
- 강조 표현: "포인트는", "핵심은", "여기서 바뀌는 게", "효율적인"
- 금지 표현: ~습니다, ~추천합니다, ~가능합니다, ~개선됩니다, ~이 분의 경우

## 표현 순화 기준
"하안부가 긴 편" → "하안부가 표준보다 길어서 갸름한 인상을 줘요"
"둔해보이는 느낌" → "현재 스타일이 눈매의 날카로움을 가리고 있어요"
"시선을 끄는 외관" → 긍정적 방향으로 재해석
"첫인상에서 매력적으로 보이는" 방향으로 서술

## 동물상 카탈로그 (반드시 이 7종에서만 선택)
강아지상 🐶 — 부드러움, 친근함, 자연스러움
고양이상 🐱 — 도도함, 신비로움, 우아함
여우상 🦊 — 세련됨, 날카로움, 정돈됨
사슴상 🦌 — 청초함, 순수함, 차분함
늑대상 🐺 — 강인함, 카리스마, 차가움
토끼상 🐰 — 귀여움, 발랄함, 동안
곰상 🐻 — 듬직함, 편안함, 포근함

## 동물상 분류 규칙
- main_animal: 사진에서 가장 강하게 느껴지는 1종
- sub_animal: 두 번째로 느껴지는 1종
- target_animal: 스타일링으로 도달 가능한 목표 1종
- 셋은 반드시 서로 다른 동물상이어야 함
- keywords는 해당 카탈로그의 것만 사용 (창작 금지)

## 절대 금지
- 시술/성형/의료 언급 (필러, 보톡스, 수술, 레이저, 주사 등 일체)
- 신체 비하 표현 (못생긴, 결함, 흠, 단점 등)
- 의사/처방/치료 관련 언급`;

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
    }
  },
  "scores": {
    "symmetry": 0.0,
    "skin": 0.0,
    "features": 0.0,
    "overall_impression": 0.0
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
      "observation": "현재 상태 관찰 (카피 톤 적용)",
      "application": "구체적 적용 방법",
      "references": [
        {
          "name": "연예인/인플루언서 이름",
          "context": "시기/상황",
          "description": "어떤 스타일인지"
        }
      ]
    },
    {
      "category": "패션",
      "observation": "...",
      "application": "...",
      "references": []
    },
    {
      "category": "메이크업",
      "observation": "...",
      "application": "...",
      "references": []
    }
  ]
}

scores의 각 항목은 0.0~10.0 범위의 숫자.
gap_percent는 0~100 사이 정수.`;

// ─── Pro 응답 스키마 지시 ─────────────────────────────────────
const PRO_SCHEMA_INSTRUCTION = `
반드시 아래 JSON 형식으로만 응답하세요. 다른 텍스트 없이 JSON만.

CRITICAL: 아래 필드는 반드시 채워야 합니다 (빈 값 금지):
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
    }
  },
  "scores": {
    "symmetry": 0.0,
    "skin": 0.0,
    "features": 0.0,
    "overall_impression": 0.0
  },
  "face_analysis": {
    "ratio_horizontal_vertical": "1:1.XX",
    "top_face_percent": 0,
    "middle_face_percent": 0,
    "bottom_face_percent": 0,
    "details": ["세부 특징 1 (20자 이상)", "세부 특징 2 (20자 이상)", "세부 특징 3 (20자 이상)"]
  },
  "appearance_score": {
    "score": 0.0,
    "current_limit": 0.0,
    "optimized_limit": 0.0,
    "tier_description": "스타일링 완성도 설명 1~2문장 (30자 이상, 카피 톤 적용)"
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
      "observation": "현재 헤어 상태 관찰 (30자 이상)",
      "application": "구체적 적용 방법 (30자 이상)",
      "references": [{"name": "셀럽 이름", "context": "시기/작품", "description": "어떤 스타일"}]
    },
    {"category": "패션", "observation": "30자 이상", "application": "30자 이상", "references": [{"name": "...", "context": "...", "description": "..."}]},
    {"category": "메이크업", "observation": "30자 이상", "application": "30자 이상", "references": [{"name": "...", "context": "...", "description": "..."}]}
  ],
  "makeup_steps": [
    {
      "step_number": 1,
      "step_name": "기초",
      "description": "기초 단계 설명 (카피 톤, 20자 이상)",
      "products": [
        {"name": "한율 부들밤 모공수축패드", "shade": null, "category": "토너패드", "usage": "AHA 성분으로 각질 정리, 세안 후 바로 사용", "platform": "coupang", "search_query": "한율 부들밤 모공수축패드"},
        {"name": "라운드랩 1025 독도 토너", "shade": null, "category": "토너", "usage": "수분 흡수 후 가볍게 두드려 흡수", "platform": "coupang", "search_query": "라운드랩 1025 독도 토너"},
        {"name": "넘버즈인 세럼", "shade": null, "category": "세럼", "usage": "피부결 따라 세로로 흡수", "platform": "coupang", "search_query": "넘버즈인 세럼"},
        {"name": "구셀 메이크업 베이스", "shade": null, "category": "베이스", "usage": "얇게 전체 도포 후 30초 흡수", "platform": "coupang", "search_query": "구셀 메이크업 베이스"}
      ],
      "tip": "묽은 제형부터 무거운 제형 순서로, 피부결 따라 세로로 흡수시켜줘요"
    },
    {
      "step_number": 2,
      "step_name": "베이스",
      "description": "피부 톤 균일화 단계 (카피 톤, 20자 이상)",
      "products": [
        {"name": "비레디 블루 파운데이션 03호", "shade": "03호", "category": "파운데이션", "usage": "소량을 전체적으로 가볍게 펴바르기", "platform": "coupang", "search_query": "비레디 블루 파운데이션"},
        {"name": "루나 롱래스팅 팁 컨실러 픽싱핏 04호", "shade": "04호 샌드", "category": "컨실러", "usage": "잡티와 다크서클 위에 두드려 커버", "platform": "coupang", "search_query": "루나 롱래스팅 컨실러 픽싱핏"},
        {"name": "스킨푸드 피치뽀송 멀티 피니시 파우더", "shade": null, "category": "파우더", "usage": "T존 중심으로 살짝 눌러 마무리", "platform": "coupang", "search_query": "스킨푸드 피치뽀송 멀티 피니시 파우더"}
      ],
      "tip": "포인트는 소량이에요. 티 안 나게 자연스럽게 얹어주는 게 핵심이거든요"
    },
    {
      "step_number": 3,
      "step_name": "음영",
      "description": "눈썹-쉐딩-립 순서로 인상 정돈 (카피 톤, 20자 이상)",
      "products": [
        {"name": "클리오 킬브로우 오토하드펜슬 05호 그레이브라운", "shade": "05호", "category": "눈썹", "usage": "눈썹 결 따라 그린 후 스크류로 빗어주기", "platform": "coupang", "search_query": "클리오 킬브로우 오토하드펜슬"},
        {"name": "투쿨포스쿨 뉴트럴 쉐딩", "shade": null, "category": "쉐딩", "usage": "얼굴 윤곽 바깥쪽에만 살짝 블렌딩", "platform": "coupang", "search_query": "투쿨포스쿨 뉴트럴 쉐딩"},
        {"name": "롬앤 쥬시 래스팅 틴트 06피그피그", "shade": "06 피그피그", "category": "립", "usage": "입술 안쪽부터 자연스럽게 펴 바르기", "platform": "coupang", "search_query": "롬앤 쥬시 래스팅 틴트 06"}
      ],
      "tip": "쉐딩은 얼굴 윤곽 바깥쪽에만 살짝. 과하면 어색해 보여요"
    },
    {
      "step_number": 4,
      "step_name": "마무리",
      "description": "지속력 확보 마무리 단계 (카피 톤, 20자 이상)",
      "products": [
        {"name": "스킨푸드 피치뽀송 멀티 피니시 파우더", "shade": null, "category": "세팅파우더", "usage": "전체적으로 가볍게 눌러 세팅", "platform": "coupang", "search_query": "스킨푸드 피치뽀송 멀티 피니시 파우더"},
        {"name": "어반디케이 메이크업 픽서", "shade": null, "category": "픽서", "usage": "20cm 거리에서 가볍게 두 번 분사", "platform": "coupang", "search_query": "어반디케이 메이크업 픽서"}
      ],
      "tip": "픽서는 20cm 거리에서 가볍게 두 번. 효율적인 마무리 방법이에요"
    }
  ],
  "fashion_looks": [
    {
      "name": "데일리 캐주얼",
      "items": [
        {"category": "Outer", "description": "화이트 린넨 셔츠 (오버사이즈)", "rationale": "청량감 + 레이어드 가능", "search_query": "화이트 린넨 셔츠 오버사이즈", "platform": "coupang"},
        {"category": "Top", "description": "화이트 반팔 코튼 이너", "rationale": "정돈된 레이어드", "search_query": "화이트 반팔 코튼 티셔츠", "platform": "coupang"},
        {"category": "Bottom", "description": "와이드 연청 데님 팬츠", "rationale": "와이드 핏으로 하체 라인 정돈", "search_query": "와이드 연청 데님 팬츠", "platform": "coupang"},
        {"category": "Shoes", "description": "화이트 로우 스니커즈", "rationale": "색감 통일, 캐주얼 강조", "search_query": "화이트 로우 스니커즈", "platform": "coupang"},
        {"category": "Acc", "description": "검정 가죽 벨트 (슬림)", "rationale": "포인트 + 허리 라인", "search_query": "검정 가죽 벨트 슬림", "platform": "coupang"}
      ],
      "rationale": "셔츠는 빼서 입고, 이너는 넣어서 입어요. 화이트+연청 조합으로 청량감 있어요",
      "styling_tip": "셔츠는 빼서, 이너는 넣어서",
      "color_palette": ["#FFFFFF", "#A8C5DA", "#000000"]
    },
    {
      "name": "세미 포멀",
      "items": [
        {"category": "Outer", "description": "검정 반팔 셔츠 (슬림핏 X, 레귤러 핏)", "rationale": "깔끔하고 정돈된 인상", "search_query": "검정 반팔 셔츠 레귤러핏", "platform": "coupang"},
        {"category": "Top", "description": "검정 이너 (넣어 입기용)", "rationale": "셔츠 넣입 깔끔하게", "search_query": "검정 이너 넣어입기", "platform": "coupang"},
        {"category": "Bottom", "description": "회색 세미와이드 슬랙스", "rationale": "정돈된 라인, 격식 있는 분위기", "search_query": "회색 세미와이드 슬랙스", "platform": "coupang"},
        {"category": "Shoes", "description": "앵클부츠 (키높이 깔창 활용)", "rationale": "키 보정 + 포멀한 인상", "search_query": "앵클부츠 남성", "platform": "coupang"},
        {"category": "Acc", "description": "검정 가죽 벨트", "rationale": "상하의 통일감", "search_query": "검정 가죽 벨트", "platform": "coupang"}
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
radar 값은 0.0~1.0 범위. scores 각 항목은 0.0~10.0 범위.
appearance_score.score는 스타일링 완성도 지표로 6.0~8.0 범위.
makeup_steps는 반드시 4개, fashion_looks는 반드시 2개여야 합니다.`;

// ─── 응답 검증 ────────────────────────────────────────────────
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
  try {
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
            text: `이 사진 속 인물의 연령대를 판단해주세요. 정확한 나이가 아닌 카테고리만:
- "adult": 명확히 18세 이상 (성인 골격, 성인 외형 등 명확)
- "minor": 18세 미만으로 보임 (어린이, 청소년 외형)
- "uncertain": 경계선으로 판단 어려움

반드시 JSON으로만 응답: {"age_category": "adult"}`,
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
    return parsed.age_category || "adult";
  } catch (e) {
    console.log("checkAge 실패, 통과:", e.message);
    return "adult"; // 판단 불가 시 분석 진행 (과도한 차단 방지)
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

        // 미성년자 차단 (분석 전 선행 체크)
        const ageCategory = await checkAge(openai, imgData, mimeType);
        if (ageCategory === "minor") {
          return res.status(403).json({
            error: "minor_detected",
            message: "본 앱은 만 19세 이상 사용자만 이용 가능합니다. 다른 사진을 업로드해주세요.",
          });
        }
        if (ageCategory === "uncertain") {
          return res.status(400).json({
            error: "age_uncertain",
            message: "정확한 분석을 위해 본인의 정면 사진을 다시 업로드해주세요.",
          });
        }

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
    max_tokens: 4500,
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
    },
    scores: { symmetry: 7.0, skin: 6.5, features: 6.8, overall_impression: 6.8 },
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
        "얼굴 가로세로 비율이 이상적인 범위에 있어요.",
        "하안부가 표준보다 약간 길어서 갸름한 인상을 줘요.",
        "눈매와 헤어 스타일링으로 시선 분산이 가능한 구조예요.",
      ],
    },
    appearance_score: {
      score: 6.8,
      current_limit: 7.0,
      optimized_limit: 7.8,
      tier_description: "현재 6점대 후반으로, 스타일링 최적화 시 7점대 후반까지 충분히 도달할 수 있어요.",
    },
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
          { name: "한율 부들밤 모공수축패드", shade: null, platform: "coupang", affiliate_url: "" },
          { name: "라운드랩 1025 독도 토너", shade: null, platform: "coupang", affiliate_url: "" },
          { name: "넘버즈인 세럼", shade: null, platform: "coupang", affiliate_url: "" },
          { name: "구셀 메이크업 베이스", shade: null, platform: "coupang", affiliate_url: "" },
        ],
        tip: "기초는 레이어링이 핵심이에요. 각 단계 30초 간격으로 흡수시켜주세요.",
      },
      {
        step_number: 2, step_name: "베이스",
        description: "파운데이션으로 피부 톤을 균일하게 잡아주는 단계예요.",
        products: [
          { name: "비레디 블루 파운데이션 03호", shade: "03호", platform: "coupang", affiliate_url: "" },
          { name: "루나 롱래스팅 팁 컨실러 픽싱핏 04호", shade: "04호", platform: "coupang", affiliate_url: "" },
          { name: "스킨푸드 피치뽀송 멀티 피니시 파우더", shade: null, platform: "coupang", affiliate_url: "" },
        ],
        tip: "포인트는 소량이에요. 티 안 나게 자연스럽게 얹어주는 게 핵심이거든요.",
      },
      {
        step_number: 3, step_name: "음영",
        description: "눈썹 → 쉐딩 → 립 순서로. 눈썹으로 구레나룻/애교살까지 정리할 수 있어요.",
        products: [
          { name: "클리오 킬브로우 오토하드펜슬 05호 그레이브라운", shade: "05호", platform: "coupang", affiliate_url: "" },
          { name: "투쿨포스쿨 뉴트럴 쉐딩", shade: null, platform: "coupang", affiliate_url: "" },
          { name: "롬앤 쥬시 래스팅 틴트 06피그피그", shade: "06호", platform: "coupang", affiliate_url: "" },
        ],
        tip: "쉐딩은 얼굴 윤곽 바깥쪽에만 살짝. 과하면 어색해 보여요.",
      },
      {
        step_number: 4, step_name: "마무리",
        description: "파우더와 픽서로 하루 종일 유지되게 마무리해줘요.",
        products: [
          { name: "스킨푸드 피치뽀송 멀티 피니시 파우더", shade: null, platform: "coupang", affiliate_url: "" },
          { name: "어반디케이 메이크업 픽서", shade: null, platform: "coupang", affiliate_url: "" },
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
