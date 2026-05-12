import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/foundation.dart';
import 'config.dart';

class SubscriptionService {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.error);
      await Purchases.configure(PurchasesConfiguration(kRevenueCatApiKey));
      _initialized = true;
    } catch (e) {
      debugPrint('RevenueCat init error: $e');
    }
  }

  // 현재 구독 여부 확인
  static Future<bool> isSubscribed() async {
    if (kDevMode) return true; // 개발자 모드: 항상 구독 상태
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // RevenueCat에 사용자 ID 설정 (로그인 시 호출)
  static Future<void> setUserId(String userId) async {
    try {
      await Purchases.logIn(userId);
    } catch (_) {}
  }

  // 구매 가능한 상품 목록 가져오기
  static Future<List<Package>> getPackages() async {
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.current?.availablePackages ?? [];
    } catch (e) {
      return [];
    }
  }

  // 구매 실행
  static Future<bool> purchase(Package package) async {
    try {
      final info = await Purchases.purchasePackage(package);
      return info.entitlements.active.isNotEmpty;
    } on PurchasesErrorCode catch (e) {
      if (e == PurchasesErrorCode.purchaseCancelledError) return false;
      rethrow;
    }
  }

  // 구매 복원
  static Future<bool> restore() async {
    try {
      final info = await Purchases.restorePurchases();
      return info.entitlements.active.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
