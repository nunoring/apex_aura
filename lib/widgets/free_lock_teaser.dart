import 'package:flutter/material.dart';
import 'price_comparison_widget.dart';

class FreeLockTeaser extends StatelessWidget {
  final VoidCallback onUpgradeTap;
  const FreeLockTeaser({super.key, required this.onUpgradeTap});

  static const _lockedItems = [
    '외모 점수 + 최적화 한계',
    '4축 레이더 갭 분석',
    '그루밍 키워드 6개',
    '전문가 풀 리포트',
    '3박자 솔루션 (피지컬/얼굴/패션)',
    '메이크업 4단계 + 제품 추천',
    '패션 룩 2~3벌 + 쇼핑 링크',
    '전체 분석 PDF 저장',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFFE8D5B7).withAlpha(128)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pro에서 잠금 해제',
              style: TextStyle(
                  color: Color(0xFFE8D5B7),
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const SizedBox(height: 12),
          _item(_lockedItems[0], revealed: true),
          ..._lockedItems
              .skip(1)
              .map((item) => _item(item, revealed: false)),
          const SizedBox(height: 16),
          const PriceComparisonWidget(),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onUpgradeTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE8D5B7),
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Pro 시작하기 — 첫 달 4,900원',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _item(String text, {required bool revealed}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            revealed ? Icons.check_circle : Icons.lock_outline,
            color: revealed ? const Color(0xFFE8D5B7) : Colors.white24,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(text,
              style: TextStyle(
                color: revealed ? Colors.white : Colors.white24,
                fontSize: 13,
              )),
        ],
      ),
    );
  }
}
