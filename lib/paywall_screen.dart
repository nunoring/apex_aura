import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'config.dart';
import 'subscription_service.dart';

class PaywallBottomSheet extends StatefulWidget {
  const PaywallBottomSheet({super.key});

  // 구독 여부 반환 (true = 구독 완료)
  static Future<bool> show(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PaywallBottomSheet(),
    );
    return result ?? false;
  }

  @override
  State<PaywallBottomSheet> createState() => _PaywallBottomSheetState();
}

class _PaywallBottomSheetState extends State<PaywallBottomSheet> {
  List<Package> _packages = [];
  bool _loading = true;
  bool _purchasing = false;
  int _selectedIndex = 0; // 0=월간, 1=연간

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    final pkgs = await SubscriptionService.getPackages();
    if (mounted) setState(() { _packages = pkgs; _loading = false; });
  }

  String _priceLabel(Package p) {
    return p.storeProduct.priceString;
  }

  bool get _isMonthly => _packages.isNotEmpty &&
      (_packages[_selectedIndex].packageType == PackageType.monthly ||
       _packages[_selectedIndex].storeProduct.identifier == kMonthlyProductId);

  Future<void> _purchase() async {
    if (_packages.isEmpty) return;
    setState(() => _purchasing = true);
    try {
      final ok = await SubscriptionService.purchase(_packages[_selectedIndex]);
      if (mounted) Navigator.pop(context, ok);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('구매 실패: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _purchasing = true);
    final ok = await SubscriptionService.restore();
    if (mounted) {
      setState(() => _purchasing = false);
      if (ok) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('복원할 구독이 없어요.'),
            backgroundColor: Color(0xFF2A1A00),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1E1E1E), width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // 자물쇠 아이콘
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1900),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2A2200), width: 0.5),
            ),
            child: const Icon(Icons.lock_outline, color: Color(0xFFE8D5B7), size: 28),
          ),
          const SizedBox(height: 14),

          const Text('AI 외모 컨설턴트',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800,
                  color: Color(0xFFE8D5B7), letterSpacing: 0.5)),
          const SizedBox(height: 6),
          const Text('24시간 무제한 분석 · 1:1 컨설팅 수준의 깊이',
              style: TextStyle(fontSize: 12, color: Color(0xFF777777))),

          const SizedBox(height: 20),

          // 기능 목록 (컨설팅 톤)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                _featureRow('🔍 단점 분석 + 비의료 보완책 (헤어·메이크업·패션)', true),
                _featureRow('🎯 닮은꼴 셀럽 매칭 + 시각 비교', true),
                _featureRow('💄 메이크업 4단계 + 추천 제품 정밀 가이드', true),
                _featureRow('👔 패션 룩 2~3개 + 코디 + 컬러 팔레트', true),
                _featureRow('📈 외모 점수 1~10등급 + 인상 분석', true),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 플랜 선택
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: Color(0xFFE8D5B7)),
            )
          else if (_packages.isEmpty)
            _buildFallbackPricing()
          else
            _buildPackageSelector(),

          const SizedBox(height: 16),

          // 구매 버튼
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _purchasing ? null : _purchase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8D5B7),
                  disabledBackgroundColor: const Color(0xFF2A2A2A),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _purchasing
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Color(0xFF1A0F00)))
                    : const Text('구독 시작하기',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700,
                            color: Color(0xFF1A0F00))),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // 복원 + 약관
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: _purchasing ? null : _restore,
                child: const Text('구매 복원',
                    style: TextStyle(fontSize: 11, color: Color(0xFF444444))),
              ),
              const Text('·', style: TextStyle(color: Color(0xFF333333))),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('나중에',
                    style: TextStyle(fontSize: 11, color: Color(0xFF444444))),
              ),
            ],
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  Widget _featureRow(String text, bool isPro) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isPro ? Icons.check_circle : Icons.check_circle_outline,
            size: 16,
            color: isPro ? const Color(0xFF27AE60) : const Color(0xFF444444),
          ),
          const SizedBox(width: 10),
          Text(text,
              style: TextStyle(
                  fontSize: 12,
                  color: isPro ? const Color(0xFFCCCCCC) : const Color(0xFF555555))),
          if (!isPro) ...[
            const Spacer(),
            const Text('무료', style: TextStyle(fontSize: 10, color: Color(0xFF555555))),
          ],
        ],
      ),
    );
  }

  Widget _buildPackageSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(_packages.length, (i) {
          final pkg = _packages[i];
          final isSelected = i == _selectedIndex;
          final isMontly = pkg.packageType == PackageType.monthly ||
              pkg.storeProduct.identifier == kMonthlyProductId;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(right: i < _packages.length - 1 ? 8 : 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF1E1900) : const Color(0xFF161616),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFE8A030) : const Color(0xFF222222),
                    width: isSelected ? 1.5 : 0.5,
                  ),
                ),
                child: Column(
                  children: [
                    if (!isMontly)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8A030).withAlpha(30),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('인기',
                            style: TextStyle(fontSize: 9, color: Color(0xFFE8A030))),
                      ),
                    Text(isMontly ? '월간' : '연간',
                        style: TextStyle(
                            fontSize: 11,
                            color: isSelected ? const Color(0xFFE8D5B7) : const Color(0xFF666666))),
                    const SizedBox(height: 4),
                    Text(_priceLabel(pkg),
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700,
                            color: isSelected ? const Color(0xFFE8A030) : const Color(0xFF888888))),
                    if (!isMontly)
                      const Text('월 2,491원',
                          style: TextStyle(fontSize: 9, color: Color(0xFF666666))),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // RevenueCat 미설정 시 fallback UI
  Widget _buildFallbackPricing() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(child: _fallbackOption('월간', '₩3,900', '/ 월', false, 0)),
          const SizedBox(width: 8),
          Expanded(child: _fallbackOption('연간', '₩29,900', '/ 년  월 2,491원', true, 1)),
        ],
      ),
    );
  }

  Widget _fallbackOption(String period, String price, String sub, bool popular, int idx) {
    final isSelected = idx == _selectedIndex;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E1900) : const Color(0xFF161616),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFFE8A030) : const Color(0xFF222222),
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Column(
          children: [
            if (popular)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8A030).withAlpha(30),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('인기', style: TextStyle(fontSize: 9, color: Color(0xFFE8A030))),
              ),
            Text(period, style: TextStyle(
                fontSize: 11,
                color: isSelected ? const Color(0xFFE8D5B7) : const Color(0xFF666666))),
            const SizedBox(height: 4),
            Text(price, style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: isSelected ? const Color(0xFFE8A030) : const Color(0xFF888888))),
            Text(sub, style: const TextStyle(fontSize: 9, color: Color(0xFF666666)),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
