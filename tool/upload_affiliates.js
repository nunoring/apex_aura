// 사용법: node tool/upload_affiliates.js
// 사전 준비: npm install firebase-admin (tool/ 디렉토리에서)
// service-account.json: Firebase Console → 프로젝트 설정 → 서비스 계정 → 새 비공개 키 생성

const admin = require('firebase-admin');
const serviceAccount = require('../functions/service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// ← CEO가 쿠팡/올영 파트너스 링크 생성 후 여기에 채워넣기
const products = {
  '한율_부들밤_모공수축패드': {
    coupang: '',
    oliveyoung: '',
  },
  '라운드랩_1025_독도_토너': {
    coupang: '',
    oliveyoung: '',
  },
  '넘버즈인_세럼': {
    coupang: '',
    oliveyoung: '',
  },
  '구셀_메이크업_베이스': {
    coupang: '',
    oliveyoung: '',
  },
  '비레디_블루_파운데이션_03호': {
    coupang: '',
    oliveyoung: '',
  },
  '루나_롱래스팅_팁_컨실러_픽싱핏_04호': {
    coupang: '',
    oliveyoung: '',
  },
  '스킨푸드_피치뽀송_멀티_피니시_파우더': {
    coupang: '',
    oliveyoung: '',
  },
  '어반디케이_메이크업_픽서': {
    coupang: '',
    oliveyoung: '',
  },
  '클리오_킬브로우_오토하드펜슬_05호': {
    coupang: '',
    oliveyoung: '',
  },
  '투쿨포스쿨_뉴트럴_쉐딩': {
    coupang: '',
    oliveyoung: '',
  },
  '롬앤_쥬시_래스팅_틴트_06피그피그': {
    coupang: '',
    oliveyoung: '',
  },
  'COS_코튼_반팔_셔츠': {
    coupang: '',
  },
  '무신사_스탠다드_와이드_슬렉스': {
    coupang: '',
  },
  '닥터마틴_앵클부츠': {
    coupang: '',
  },
  '유니클로_린넨_셔츠': {
    coupang: '',
  },
  '무신사_와이드_데님': {
    coupang: '',
  },
  '나이키_에어포스1': {
    coupang: '',
  },
};

async function upload() {
  console.log(`총 ${Object.keys(products).length}개 제품 업로드 시작...`);
  let success = 0;
  let skip = 0;

  for (const [id, urls] of Object.entries(products)) {
    const hasUrl = Object.values(urls).some((v) => v.trim() !== '');
    if (!hasUrl) {
      console.log(`⏭  ${id} (URL 미입력 — 건너뜀)`);
      skip++;
      continue;
    }
    try {
      await db.collection('affiliate_products').doc(id).set(urls, { merge: true });
      console.log(`✅ ${id}`);
      success++;
    } catch (e) {
      console.error(`❌ ${id}: ${e.message}`);
    }
  }

  console.log(`\n완료: ${success}개 업로드, ${skip}개 건너뜀`);
  process.exit(0);
}

upload();
