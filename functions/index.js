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
    const { base64Image, animalType, impression, faceData, gender, extraInstruction } = req.body;
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
        max_tokens: 3500,
        response_format: { type: "json_object" },
        messages: [
          {
            role: "system",
            content: `당신은 전문 이미지 컨설턴트입니다. 스타일리스트와 퍼스널 컬러리스트를 합친 역할로,
사진을 보고 동물상 분석과 스타일링 제안을 제공합니다.

[페르소나 규칙]
- 호칭 없음 (2인칭 생략)
- 종결어미: ~어요 / ~거든요 / ~예요
- 강조 표현: "포인트는", "핵심은", "여기서 바뀌는 게", "효율적인"
- 절대 금지 종결어미: ~습니다, ~추천합니다, ~가능합니다, ~개선됩니다, ~이 분의 경우

[절대 금지 단어]
필러, 보톡스, 성형, 수술, 리프팅, 레이저, 시술, 이식, 윤곽술,
처방, 치료, 진료, 임상, 의학적, 의사, 약물, 호르몬,
못생긴, 결함, 흠, 단점, 못난, 추한

[분석 방법]
각 진단 항목: 관찰 → 영향 → 갭 → 방향
각 추천: What → Why → How → Examples(셀럽 레퍼런스) → Caution(선택)

[셀럽 레퍼런스 규칙]
- 이름 + 맥락(작품/시기) + 스타일 설명 1줄
- 실존 인물만 사용

[응답 형식] 반드시 아래 JSON 구조로만 응답. 다른 텍스트 없음:
성별(${genderKo}) 기준으로 작성. 모든 텍스트 한국어.

{
  "comparison": {
    "current_animal": "${currentFaceType || '직접 판단'}",
    "target_animal": "${animalType}",
    "current_keywords": ["키워드1", "키워드2", "키워드3"],
    "target_keywords": ["키워드1", "키워드2", "키워드3"],
    "gap_percent": 0
  },
  "radar": {
    "current": {"눈매": 0.0, "코": 0.0, "얼굴윤곽": 0.0, "스타일": 0.0},
    "target": {"눈매": 0.0, "코": 0.0, "얼굴윤곽": 0.0, "스타일": 0.0}
  },
  "consultant_report": {
    "quote": "전체 인상 요약 한 문장 (~어요 종결)",
    "observation": "관찰 내용 30자 이상",
    "impact": "주는 인상 20자 이상",
    "gap": "목표와의 차이 20자 이상",
    "direction": "스타일링 방향 20자 이상"
  },
  "action_cards": [
    {
      "category": "헤어스타일",
      "icon": "scissors",
      "observation": "관찰 30자 이상",
      "principle": "원리 설명 50자 이상",
      "application": "적용 방법 30자 이상",
      "references": [
        {"name": "이름", "context": "맥락", "description": "설명 1줄"},
        {"name": "이름", "context": "맥락", "description": "설명 1줄"}
      ],
      "caution": null
    },
    {
      "category": "패션/스타일링",
      "icon": "shirt",
      "observation": "...",
      "principle": "...",
      "application": "...",
      "references": [{"name": "...", "context": "...", "description": "..."}, {"name": "...", "context": "...", "description": "..."}],
      "caution": null
    },
    {
      "category": "${isFemale ? '메이크업' : '그루밍'}",
      "icon": "${isFemale ? 'makeup' : 'grooming'}",
      "observation": "...",
      "principle": "...",
      "application": "...",
      "references": [{"name": "...", "context": "...", "description": "..."}, {"name": "...", "context": "...", "description": "..."}],
      "caution": null
    }
  ],
  "milestones": [
    {"days": 30, "description": "30일 체감 변화"},
    {"days": 60, "description": "60일 변화"},
    {"days": 90, "description": "90일 최종 목표"}
  ]
}`
          },
          {
            role: "user",
            content: [
              {
                type: "text",
                text: `## 1차 이미지 분석:
${description}

${faceMetrics}

## 분석 요청:
- 현재 동물상: ${currentFaceType || '직접 판단'}
- 목표 동물상: ${animalType}
- 성별: ${genderKo}

첨부된 사진을 분석해서 위 JSON 형식으로만 응답해줘.${extraInstruction ? '\n\n⚠️ 추가 지시: ' + extraInstruction : ''}`
              },
              imageContent
            ]
          }
        ]
      }),
    });

    const step2Data = await step2.json();
    let result;
    try {
      const cleaned = step2Data.choices[0].message.content.replace(/```json|```/g, '').trim();
      result = JSON.parse(cleaned);
    } catch (e) {
      console.error('JSON 파싱 실패:', e);
      throw new Error('분석 결과 파싱 오류');
    }

    res.json({ ...result, skinAnalysis });

  } catch (e) {
    console.error(e);
    res.status(500).json({ error: e.message });
  }
});
