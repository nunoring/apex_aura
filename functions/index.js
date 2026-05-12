// v7 - 피부 Vision AI 분석 추가 (병렬 실행)
const { onRequest } = require("firebase-functions/v2/https");
const fetch = require("node-fetch");

const OPENAI_API_KEY = process.env.OPENAI_API_KEY;

exports.analyzeImage = onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");

  if (req.method === "OPTIONS") {
    res.set("Access-Control-Allow-Methods", "POST");
    res.set("Access-Control-Allow-Headers", "Content-Type");
    res.status(204).send("");
    return;
  }

  try {
    const { base64Image, animalType, impression, faceData, gender } = req.body;
    const currentFaceType = faceData?.current_face_type || null;
    const isFemale = gender === 'female';
    const genderKo = isFemale ? '여성' : '남성';

    const imageContent = {
      type: "image_url",
      image_url: { url: `data:image/jpeg;base64,${base64Image}`, detail: "high" }
    };

    // 1단계 + 피부 분석: 병렬 실행
    const [step1Res, skinRes] = await Promise.all([
      // 전반 외모 설명 (피부 제외)
      fetch("https://api.openai.com/v1/chat/completions", {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${OPENAI_API_KEY}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model: "gpt-4o",
          max_tokens: 900,
          messages: [{
            role: "user",
            content: [
              {
                type: "text",
                text: `이 사진에 있는 ${genderKo}의 외모를 매우 구체적으로 묘사해주세요. 반드시 사진에서 실제로 보이는 것만 기반으로 작성하세요.

다음 항목별로 상세히 설명해주세요:
1. 헤어스타일: 현재 길이, 스타일, 가르마 위치, 볼륨감, 문제점 (예: "옆머리가 귀를 덮어 얼굴이 넓어 보임")
2. 눈매: 눈꼬리 방향, 쌍꺼풀 유무, 눈 크기, 눈 간격, 눈매 특징
3. 이목구비: 코 형태/높이, 입술 두께, 턱선 형태, 광대 위치
4. 얼굴형: 전체적인 윤곽, 이마 넓이, 얼굴 길이
5. 헤어/그루밍 현재 상태: 지금 당장 보이는 개선 포인트

각 항목에서 "사진에서 보면", "현재 ~하게 보임", "~한 특징이 관찰됨" 같은 표현을 사용하여 이 사람에게만 해당하는 관찰 내용을 작성하세요.`
              },
              imageContent
            ]
          }]
        }),
      }),
      // 피부 집중 분석
      fetch("https://api.openai.com/v1/chat/completions", {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${OPENAI_API_KEY}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model: "gpt-4o",
          max_tokens: 400,
          response_format: { type: "json_object" },
          messages: [{
            role: "user",
            content: [
              {
                type: "text",
                text: `이 남성의 피부 상태만 집중 분석해주세요. 사진에서 실제로 보이는 것만 기반으로 판단하세요. 반드시 아래 JSON만 응답:
{
  "tone": "밝음/중간/어두움 중 택1",
  "texture": "매끄러움/보통/거침 중 택1",
  "dark_circles": "없음/약간/심함 중 택1",
  "pores": "작음/보통/눈에띔 중 택1",
  "spots": "없음/약간/있음 중 택1",
  "oiliness": "건성/정상/지성/복합성 중 택1",
  "redness": "없음/약간/있음 중 택1",
  "overall": "좋음/보통/관리필요 중 택1",
  "main_concern": "가장 두드러지는 피부 고민 한 가지 (15자 이내)",
  "score": 0.0
}`
              },
              imageContent
            ]
          }]
        }),
      }),
    ]);

    const step1Data = await step1Res.json();
    const skinRaw = await skinRes.json();
    const description = step1Data.choices[0].message.content;
    const skinAnalysis = JSON.parse(skinRaw.choices[0].message.content);

    // ML Kit + 피부 수치 텍스트
    const faceMetrics = faceData ? `
## ML Kit 정밀 측정 수치:
- 눈꼬리 각도: ${faceData.eye_angle}도 (${faceData.eye_angle_desc})
- 얼굴형: ${faceData.face_shape} (비율: ${faceData.face_ratio})
- 눈 간격: ${faceData.eye_gap_desc} (비율: ${faceData.eye_gap_ratio})
- 황금비율: ${faceData.golden_desc} (수치: ${faceData.golden_ratio})
- 코 폭: ${faceData.nose_desc}

## Vision AI 피부 분석:
- 피부 톤: ${skinAnalysis.tone}
- 피부 결: ${skinAnalysis.texture}
- 다크서클: ${skinAnalysis.dark_circles}
- 모공: ${skinAnalysis.pores}
- 잡티: ${skinAnalysis.spots}
- 유수분 타입: ${skinAnalysis.oiliness}
- 붉은기: ${skinAnalysis.redness}
- 주요 고민: ${skinAnalysis.main_concern}
- 전반 상태: ${skinAnalysis.overall}
` : '';

    // 2단계: 종합 분석
    const step2 = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${OPENAI_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "gpt-4o",
        max_tokens: 2800,
        response_format: { type: "json_object" },
        messages: [
          {
            role: "system",
            content: `당신은 10년 경력의 외모 전문 컨설턴트입니다. 현재 분석 대상: ${genderKo}.
AI 수치와 Vision AI 피부 분석, 그리고 위의 상세 외모 관찰 결과를 기반으로 분석하세요.
반드시 아래 JSON 구조로만 응답하세요. 키 이름 절대 변경 금지. 모든 텍스트는 한국어.
뻔한 조언 금지. 구체적인 제품명, 시술명, 헤어컷 이름을 명시하세요.
모든 추천에는 반드시 이유(근거)를 함께 제시하세요.

[개인화 필수 규칙]
- 모든 분석과 추천은 반드시 "사진에서 보이는 것처럼", "현재 이 분의 경우", "사진에서 관찰되는 ~때문에" 같은 표현으로 시작하여 이 사람만을 위한 분석임을 명확히 하세요.
- 일반론적인 조언 완전 금지. 반드시 이 사람 사진에서 실제로 보이는 구체적 특징을 언급하세요.
- curriculum의 current_problem은 반드시 사진에서 실제로 관찰된 문제점을 서술하세요.
- realistic_feedback은 "이 분의 경우 ~가 관찰되어 ~한 한계가 있지만, ~을 통해 개선 가능합니다" 형식으로 작성하세요.
skin 커리큘럼은 반드시 Vision AI 피부 분석 결과를 기반으로 작성하세요.
alternative는 반드시 강아지상/고양이상/곰상/늑대상/여우상 중 하나만 선택하세요.
${isFemale ? '여성이므로: 수염 관련 항목 제외. 헤어는 여성 스타일 기준. 시술은 여성에게 적합한 것으로 추천.' : ''}

[동물상별 전문 지식 — 성별(${genderKo}) 기준으로 추천 근거 활용]
[동물상별 헤어 스타일 가이드 — 2024~2025 트렌드 반영, 성별(${genderKo}) 기준]
※ 헤어 추천 시 반드시 선택지 2~3개를 제시하고 각각의 이유를 설명하세요. 미용실 원장에게 말하는 멘트 형식은 사용하지 마세요.

강아지상 ${genderKo} 헤어 선택지:
${isFemale
  ? `① 히메컷 (이유: 얼굴 양옆을 감싸 둥근 얼굴 보완, 요즘 유행)\n② 레이어드 미디엄컷 (이유: 아래로 갈수록 가벼워져 갸름해 보임)\n③ 아이돌 단발 (이유: 얼굴선 정리, 시크한 인상 추가)`
  : `① 다운펌+센터파트 (이유: 2024~2025 트렌드, 부드럽게 내려오는 결로 온화한 인상 강화)\n② C컷 세미 리젠트 (이유: 이마를 살짝 드러내 얼굴 갸름하게, 클래식한 느낌)\n③ 자연 웨이브 미디엄 (이유: 자연스럽고 관리 쉬움, 둥근 얼굴에 잘 어울림)
투블럭은 지양 (이유: 옆 볼륨 제거로 오히려 얼굴 더 넓어 보일 수 있음)`}

고양이상 ${genderKo} 헤어 선택지:
${isFemale
  ? `① 쉐도우펌 (이유: 날카로운 인상 완화, 부드러운 곡선미)\n② 리프컷 (이유: 얼굴형 부드럽게 감싸)\n③ 텍스처 단발 (이유: 볼륨감으로 갸름한 얼굴 보완)`
  : `① 쉐도우펌+앞머리 (이유: 올라간 눈꼬리 완화, 2024 남성 트렌드)\n② 다운펌 (이유: 부드럽게 내려오는 결이 날카로운 이미지 중화)\n③ 허쉬컷 스타일 남성 버전 (이유: 측면 볼륨으로 갸름한 얼굴 보완)`}

늑대상 ${genderKo} 헤어 선택지:
${isFemale
  ? `① 레이어드 웨이브 (이유: 갸름한 얼굴에 볼륨감 추가)\n② 리본컷 (이유: 얼굴 양쪽 볼륨 커버)\n③ 히메컷 (이유: 얼굴 보완 + 부드러운 인상)`
  : `① 다운펌+5:5가르마 (이유: 강한 인상 유지, 세련된 느낌)\n② 텍스처 크롭 (이유: 요즘 유행, 자연스럽고 힘 있어 보임)\n③ 자연 리젠트 (이유: 이마 강조로 남성미 유지)`}

곰상 ${genderKo} 헤어 선택지:
${isFemale
  ? `① 스트레이트 미디엄 (이유: 볼륨 없어 얼굴 정리)\n② C컷 단발 (이유: 얼굴 라인 정리)\n③ 세미 단발 (이유: 얼굴 작아 보이는 효과)`
  : `① 다운펌 미디엄 (이유: 볼륨 제어, 부드럽고 트렌디)\n② 자연 크롭 (이유: 과하지 않고 단정함)\n③ 세미 리젠트 (이유: 이마 강조로 얼굴 길어 보임)\n볼륨 많은 스타일 금지 (이유: 큰 골격에 볼륨 더하면 더 커 보임)`}

여우상 ${genderKo} 헤어 선택지:
${isFemale
  ? `① 긴 레이어드+웨이브 (이유: 샤프함 중화, 여성스러운 인상)\n② 텍스처 미디엄 (이유: 부드러운 질감으로 접근성 향상)\n③ 히메컷 (이유: 얼굴 감싸며 날카로움 완화)`
  : `① 다운펌+자연 가르마 (이유: 예리한 이미지 중화, 트렌디)\n② 웨이브 미디엄 (이유: 부드러운 질감으로 접근하기 쉬운 인상)\n③ 텍스처 크롭 (이유: 스타일리시하면서 날카로움 완화)`}

[${genderKo} 피부 타입별 성분 추천 근거]
- 지성: BHA(살리실산) + 나이아신아마이드 (이유: BHA가 모공 속 각질 용해, 나이아신아마이드가 피지 분비 조절)
- 건성: 세라마이드 + 히알루론산 + 스쿠알란 (이유: 세라마이드로 피부 장벽 복구, 히알루론산으로 수분 유지, 스쿠알란으로 유분 보충)
- 복합성: T존-BHA, 볼-세라마이드 분리 사용 (이유: 부위별 피부 상태 다름, 일괄 적용 시 T존은 번들거리고 볼은 당김)
- 민감성: 시카/판테놀/무향 무알코올 제품 (이유: 향료·알코올·파라벤이 민감한 피부 자극 유발)
- 다크서클: 카페인+비타민K 아이크림 (이유: 혈액순환 촉진 + 멍 옅어지는 효과)
- 잡티/색소침착: 비타민C + 알파아부틴 (이유: 멜라닌 생성 억제 + 기존 색소 분해)

[시술 추천 근거 — ${genderKo} 기준]
- 눈매 교정(쌍꺼풀/매몰법): 눈동자 노출 증가로 또렷하고 맑은 느낌, 회복 3~7일
- 보조개 성형: 회복 짧고(2~3일) 즉각적인 친근한 인상 연출, 비용 50~80만원
- 코 필러: 비순각 90~95도가 이상적인 코 비율, 효과 6~12개월, 비용 20~40만원
- 코 성형: 반영구적, 비용 200~500만원, 회복 2~3주
- 사각턱 보톡스: 효과 6개월, 완전 제거보다 20~30% 남기는 것이 자연스러움, 비용 15~30만원
- 광대 축소술: 넓은 광대 개선, 얼굴 갸름해 보임, 비용 300~500만원
- 앞트임: 눈 간격 넓어 보이는 효과, 회복 1주일
- 피부과 레이저(토닝): 잡티/모공/피부결 개선, 비용 5~15만원/회, 효과 누적

gap_analysis 작성 규칙 (절대 예시값 복사 금지):
- score: 0.0(목표와 거의 일치)~1.0(매우 큰 차이), 실제 분석 기반 수치
- level 결정 기준:
  * "easy": 헤어·그루밍 등 즉시 개선 가능한 항목
  * "mid": 꾸준한 관리/노력이 필요한 항목
  * "hard": 골격·눈매 등 수술 없이 바꾸기 어려운 항목
- 피부 항목 level은 Vision AI overall을 그대로 반영: 좋음→"easy", 보통→"mid", 관리필요→"hard"
- 전체 인상 level은 현재 인상과 목표 추구미(${animalType})의 실제 거리 기반으로 판단`
          },
          {
            role: "user",
            content: `## 이미지 분석:
${description}

${faceMetrics}

## 목표 추구미: ${animalType} (${impression})
${currentFaceType ? `## 현재 동물상 (ML Kit 수치로 수학적 결정, 변경 금지): ${currentFaceType}` : ''}

위 데이터를 종합하여 아래 JSON으로 응답하세요.
※ current_impression은 반드시 위에서 지정된 현재 동물상(${currentFaceType || '직접 판단'})을 기반으로 작성하세요.
※ gap_analysis의 score/tag/level은 형식 예시(0.0, "easy")이므로 반드시 실제 분석값으로 교체하세요:

{
  "current_impression": "${currentFaceType ? currentFaceType + ' 계열' : '현재 인상 한 줄'} (10자 이내)",
  "impression_analysis": "현재 [인상 특징] 때문에 [목표 추구미]와 [거리감 설명]. [구체적 개선 방향 1~2가지]가 핵심. (50자 이내)",
  "features": "특징1 · 특징2 · 특징3",
  "difficulty": 3,
  "difficulty_text": "달성 난이도 설명",
  "gap_analysis": [
    {"item": "눈매", "score": 0.0, "tag": "바로 가능", "level": "easy"},
    {"item": "헤어스타일", "score": 0.0, "tag": "바로 가능", "level": "easy"},
    {"item": "피부", "score": 0.0, "tag": "바로 가능", "level": "easy"},
    {"item": "전체 인상", "score": 0.0, "tag": "바로 가능", "level": "easy"}
  ],
  "realistic_feedback": "현재 얼굴 수치 기반 솔직한 피드백. '눈꼬리 각도 -2.1°로 강아지상 특성이 강해 고양이상까지는 시술 없이 한계가 있다' 처럼 구체적 수치 언급. 골격 한계는 솔직하게, 하지만 관리로 가능한 부분은 희망을 줄 것.",
  "alternative": null,
  "curriculum": {
    "hair": {
      "title": "헤어 플랜",
      "before": "사진에서 관찰된 현재 헤어 상태 (구체적으로, 예: 옆머리가 귀를 완전히 덮어 얼굴이 실제보다 넓어 보임. 앞머리 없어 이마 전체가 무거워 보임)",
      "options": [
        {"label": "선택지 이름 (예: 다운펌+센터파트)", "effect": "이 스타일을 선택하면 어떤 변화를 얻을 수 있는지 (예: 부드럽게 내려오는 결로 온화한 인상 + 얼굴 갸름해 보임, 관리 쉬움)"},
        {"label": "선택지 이름", "effect": "이 스타일의 효과"},
        {"label": "선택지 이름", "effect": "이 스타일의 효과"}
      ],
      "tip": "어떤 선택지를 고르든 공통으로 해야 할 관리 팁 1~2줄"
    },
    "skin": {
      "title": "피부 플랜",
      "before": "Vision AI 분석 기반 현재 피부 상태 (구체적으로, 예: T존 피지 과다로 번들거림, 볼 부위 건조해 당기는 복합성 피부)",
      "options": [
        {"label": "① 피지 집중 케어", "effect": "BHA(살리실산)+나이아신아마이드로 모공 각질 제거 + 피지 분비 조절. 아침: 약산성 클렌저 → 토너 → 수분크림 → 선크림. 저녁: 이중세안 → BHA 토너 → 세럼"},
        {"label": "② 수분 베리어 케어", "effect": "세라마이드+히알루론산으로 피부 장벽 복구 + 수분 유지. 건조한 볼 부위 집중 관리"},
        {"label": "③ 피부과 치료", "effect": "레이저토닝으로 모공/피지선 직접 치료, 5~10만원/회. 가장 빠른 개선 효과"}
      ],
      "tip": "공통: 자외선차단제 SPF50 매일 필수. 피부 타입별 세안 후 즉시 보습 도포"
    },
    "grooming": {
      "title": "그루밍 플랜",
      "before": "사진에서 관찰된 현재 그루밍 상태 (눈썹 정리 여부, 수염 상태 등)",
      "options": [
        {"label": "① 눈썹 정리", "effect": "눈썹 형태 + 정리 방법. 어떤 인상 변화를 얻을 수 있는지"},
        {"label": "${isFemale ? '② 메이크업 팁' : '② 수염 관리'}", "effect": "${isFemale ? '자연스러운 메이크업으로 얼굴상 강화 방법' : '수염 스타일별 효과. 클린면도 vs 5mm유지 vs 수염기르기 각각의 인상 차이'}"},
        {"label": "③ 디테일 케어", "effect": "코털/귀밑털/손톱 등 디테일 관리로 얻는 전체적 인상 향상"}
      ],
      "tip": "그루밍은 헤어보다 인상에 즉각적인 영향. 주 1~2회 정기 관리 권장"
    },
    "procedure": {
      "title": "시술 로드맵",
      "before": "현재 얼굴에서 시술로 개선 가능한 부분 (사진 기반 관찰, 예: 눈꼬리가 내려가 있어 눈매 교정 효과 클 것으로 예상)",
      "options": [
        {"label": "① 즉시 가능 (비침습)", "effect": "시술명 + 효과 + 비용 + 회복기간. 예: 보톡스(눈꼬리) — 눈꼬리 개선, 15~25만원, 회복 없음"},
        {"label": "② 가성비 우선 추천", "effect": "현재 상태에서 비용 대비 효과가 가장 큰 시술. 시술명 + 구체적 효과 + 비용"},
        {"label": "③ 장기 로드맵", "effect": "1순위(즉시) → 2순위(3개월 후) → 3순위(장기) 순서로 투자 계획"}
      ],
      "tip": "시술 전 반드시 2~3곳 상담 후 결정. 비용 대비 효과 순서대로 진행 권장"
    }
  },
  "product_recommendations": [
    {
      "category": "스킨케어",
      "reason": "추천 이유 (Vision AI 피부 분석 기반, 15자 이내)",
      "items": [
        {"name": "제품 유형명", "key_ingredient": "핵심 성분", "price_range": "가격대 (예: 2-5만원)", "priority": "high"},
        {"name": "제품 유형명", "key_ingredient": "핵심 성분", "price_range": "가격대", "priority": "mid"}
      ]
    },
    {
      "category": "헤어",
      "reason": "추천 이유 (헤어 분석 기반, 15자 이내)",
      "items": [
        {"name": "제품 유형명", "key_ingredient": "핵심 성분/특징", "price_range": "가격대", "priority": "high"},
        {"name": "제품 유형명", "key_ingredient": "핵심 성분/특징", "price_range": "가격대", "priority": "mid"}
      ]
    },
    {
      "category": "그루밍",
      "reason": "추천 이유 (그루밍 분석 기반, 15자 이내)",
      "items": [
        {"name": "제품 유형명", "key_ingredient": "핵심 성분/특징", "price_range": "가격대", "priority": "high"}
      ]
    }
  ]
}`
          }
        ]
      }),
    });

    const step2Data = await step2.json();
    const result = JSON.parse(step2Data.choices[0].message.content);

    res.json({ ...result, skinAnalysis });

  } catch (e) {
    console.error(e);
    res.status(500).json({ error: e.message });
  }
});
