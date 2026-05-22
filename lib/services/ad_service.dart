import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// 보상형 동영상 광고 서비스
// 분석 시작 전 영상 1편 시청 → 완료 시 분석 진행
//
// AdMob ID 발급 후 _rewardedAdUnitId를 실제 ID로 교체.
// 발급: https://admob.google.com → 앱 등록 → 광고 단위 추가 (보상형)
class AdService {
  static bool _initialized = false;
  static RewardedAd? _rewardedAd;
  static bool _isLoading = false;

  // 테스트 광고 ID (Google 공식) — 출시 직전 실 ID로 교체
  // Android: ca-app-pub-3940256099942544/5224354917
  // iOS:     ca-app-pub-3940256099942544/1712485313
  static String get _rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313';
    }
    throw UnsupportedError('Platform not supported');
  }

  static Future<void> init() async {
    if (_initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      _preload();
    } catch (e) {
      debugPrint('AdMob init error: $e');
    }
  }

  // 미리 광고 로드 (분석 시작 대기 줄임)
  static void _preload() {
    if (_isLoading || _rewardedAd != null) return;
    _isLoading = true;
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoading = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed to load: $error');
          _rewardedAd = null;
          _isLoading = false;
        },
      ),
    );
  }

  // 광고 표시 → 영상 완료 시 true, 중단/실패 시 false
  static Future<bool> showRewardedAd() async {
    await init();
    // 광고 없으면 즉시 로드 시도하고 잠시 대기
    if (_rewardedAd == null) {
      _preload();
      // 최대 5초 대기
      for (int i = 0; i < 50; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (_rewardedAd != null) break;
      }
    }
    if (_rewardedAd == null) {
      debugPrint('Rewarded ad not ready, skipping');
      return true; // 광고 못 띄우면 통과 (사용자 차단 X)
    }

    bool rewarded = false;
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _preload(); // 다음 광고 미리 로드
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Ad failed to show: $error');
        ad.dispose();
        _rewardedAd = null;
        _preload();
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        rewarded = true;
      },
    );
    return rewarded;
  }
}
