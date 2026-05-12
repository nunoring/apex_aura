const { onRequest } = require("firebase-functions/v2/https");
const OpenAI = require("openai");
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

// ─── GPT 시스템 프롬프트 ─────────────────────────────────────
const SYSTEM_PROMPT = `당신은 전문 이미지 컨설턴트입니다.
얼굴 사진을 보고 외모를 분석하여 스타일링 솔루션을 제공합니다.

## 분석 철학
- 외관의 개성과 매력을 중심으로 분석
- 스타일링(헤어/메이크업/패션)으로 개선 가능한 영역에 집중
- 피지컬 × 얼굴 × 패션 3박자 조화로 한계치를 넘어서는 접근

## 외모 점수 기준
- 6점: 일반인 중 눈에 띄는 외관
- 7점: 가끔 마주칠 수 있는 외관, SNS에서 종종 보이는 유형
- 8점: 시선을 끄는 고등급 외관 (매우 드묾)
- 대부분의 일반인은 6~7점대

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

## 절대 금지
- 시술/성형/의료 언급 (필러, 보톡스, 수술, 레이저, 주사 등 일체)
- 신체 비하 표현 (못생긴, 결함, 흠, 단점 등)
- 의사/처방/치료 관련 언급`;

// ─── Free 응답 스키마 지시 ────────────────────────────────────
const FREE_SCHEMA_INSTRUCTION = `
반드시 아래 JSON 형식으로만 응답하세요. 다른 텍스트 없이 JSON만.

{
  "first_impression": {
    "summary": "첫인상 한 줄 요약 (카피 톤 적용)",
    "face_shape": "얼굴형 (예: 둥근형~하트형)",
    "animal_type": "동물상 (예: 강아지상)",
    "strengths": ["강점1", "강점2", "강점3"]
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

{
  "first_impression": {
    "summary": "첫인상 한 줄 요약",
    "face_shape": "얼굴형",
    "animal_type": "동물상",
    "strengths": ["강점1", "강점2", "강점3"]
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
    "details": ["얼굴 세부 특징 1", "얼굴 세부 특징 2", "얼굴 세부 특징 3"]
  },
  "appearance_score": {
    "score": 0.0,
    "current_limit": 0.0,
    "optimized_limit": 0.0,
    "tier_description": "현재 외관 티어 설명 1~2문장 (카피 톤 적용)"
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
    "quote": "전문가 코멘트 (카피 톤 적용)",
    "observation": "전체적 관찰 내용",
    "impact": "현재 스타일이 인상에 미치는 영향",
    "gap": "핵심 갭 요소",
    "direction": "변화 방향성"
  },
  "three_factor": {
    "physical": {"summary": "피지컬 요약", "items": ["항목1", "항목2", "항목3"]},
    "face": {"summary": "얼굴 요약", "items": ["항목1", "항목2", "항목3"]},
    "fashion": {"summary": "패션 요약", "items": ["항목1", "항목2", "항목3"]}
  },
  "action_cards": [
    {"category": "헤어스타일", "observation": "...", "application": "...", "references": [{"name": "...", "context": "...", "description": "..."}]},
    {"category": "패션", "observation": "...", "application": "...", "references": []},
    {"category": "메이크업", "observation": "...", "application": "...", "references": []}
  ],
  "makeup_steps": [
    {
      "step_number": 1,
      "step_name": "기초",
      "description": "기초 단계 설명 (카피 톤 적용)",
      "products": [{"name": "제품명", "shade": null, "platform": "coupang", "affiliate_url": ""}],
      "tip": "이 단계의 핵심 팁"
    },
    {"step_number": 2, "step_name": "베이스", "description": "...", "products": [], "tip": "..."},
    {"step_number": 3, "step_name": "음영", "description": "...", "products": [], "tip": "..."},
    {"step_number": 4, "step_name": "마무리", "description": "...", "products": [], "tip": "..."}
  ],
  "fashion_looks": [
    {
      "name": "룩 이름",
      "items": [
        {"category": "Top", "description": "아이템 설명", "affiliate": {"name": "제품명", "platform": "coupang", "url": ""}},
        {"category": "Bottom", "description": "...", "affiliate": {"name": "...", "platform": "coupang", "url": ""}},
        {"category": "Shoes", "description": "...", "affiliate": {"name": "...", "platform": "coupang", "url": ""}},
        {"category": "Acc", "description": "...", "affiliate": {"name": "...", "platform": "coupang", "url": ""}}
      ],
      "rationale": "이 룩을 추천하는 이유 (카피 톤 적용)"
    },
    {"name": "룩2 이름", "items": [], "rationale": "..."}
  ],
  "color_palette": {
    "main": ["#000000", "#1A2238", "#FFFFFF"],
    "accent": ["#722F37", "#C19A6B"],
    "avoid": ["#FF00FF", "#FFFF00"]
  }
}

모든 숫자 필드는 실제 숫자로. 문자열 필드는 카피 톤 규칙 적용.
radar 값은 0.0~1.0 범위. appearance_score.score는 6.0~8.0 범위.
6.0 미만 점수는 절대 반환하지 마세요.`;

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
        if (!imgData) {
          return res.status(400).json({ error: "imageBase64 required" });
        }

        const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
        const schemaInstruction = isPro ? PRO_SCHEMA_INSTRUCTION : FREE_SCHEMA_INSTRUCTION;

        const userPrompt = buildUserPrompt(isPro, animalType, gender, faceData, schemaInstruction);

        // 1차 시도
        let result = await callGPT(openai, userPrompt, imgData, mimeType);

        // 금지 단어 검출 + 재시도 (최대 2회)
        if (containsBanned(JSON.stringify(result))) {
          console.log("금지 단어 검출 — 1차 재시도");
          const retryPrompt = userPrompt + "\n\n[중요] 이전 응답에 금지 표현이 포함되어 있었습니다. 시술/성형/의료/신체비하 표현 없이 다시 작성하세요.";
          result = await callGPT(openai, retryPrompt, imgData, mimeType);

          if (containsBanned(JSON.stringify(result))) {
            console.log("금지 단어 검출 — 2차 재시도 (강화)");
            result = await callGPT(
              openai,
              retryPrompt + "\n시술/성형 관련 단어가 단 하나도 없어야 합니다.",
              imgData,
              mimeType
            );

            if (containsBanned(JSON.stringify(result))) {
              console.log("금지 단어 — 폴백 응답 사용");
              result = getFallbackResponse(isPro);
            }
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
  const faceMetrics = faceData
    ? `\nML Kit 수치: 눈꼬리 ${faceData.eye_angle}° (${faceData.eye_angle_desc}), 얼굴형 ${faceData.face_shape}, 눈간격 ${faceData.eye_gap_desc}, 황금비율 ${faceData.golden_desc}`
    : "";

  return `이 얼굴 사진을 분석해주세요.

분석 대상: ${genderKo}${animalType ? `, 목표 동물상: ${animalType}` : ""}${faceMetrics}

분석 범위:
- 얼굴형, 이목구비 특징, 피부 상태
- 현재 헤어스타일이 인상에 미치는 영향
- 동물상 분류 및 목표 동물상 설정
- 그루밍/스타일링 방향성
${isPro ? `- 얼굴 비율 (상/중/하안부 %), 가로세로 비율
- 외모 점수 (6.0~8.0 범위)
- 메이크업 4단계 제품 추천
- 패션 룩 2벌 추천
- 어울리는 컬러 팔레트` : ""}

${schemaInstruction}`;
}

// ─── GPT 호출 헬퍼 ────────────────────────────────────────────
async function callGPT(openai, userPrompt, imageBase64, mimeType) {
  const response = await openai.chat.completions.create({
    model: "gpt-4o",
    max_tokens: 4000,
    temperature: 0.7,
    messages: [
      { role: "system", content: SYSTEM_PROMPT },
      {
        role: "user",
        content: [
          {
            type: "image_url",
            image_url: {
              url: `data:${mimeType};base64,${imageBase64}`,
              detail: "high",
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
      animal_type: "강아지상",
      strengths: ["부드러운 인상", "균형 잡힌 이목구비", "자연스러운 매력"],
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
