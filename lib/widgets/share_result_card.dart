import 'package:flutter/material.dart';

class ShareResultCard extends StatelessWidget {
  final String mainAnimal;
  final String mainEmoji;
  final int mainPercent;
  final String subAnimal;
  final String subEmoji;
  final int subPercent;
  final String targetAnimal;
  final String targetEmoji;
  final int totalScore;
  final String tier;
  final Color tierColor;
  final int gapPercent;

  const ShareResultCard({
    super.key,
    required this.mainAnimal,
    required this.mainEmoji,
    required this.mainPercent,
    required this.subAnimal,
    required this.subEmoji,
    required this.subPercent,
    required this.targetAnimal,
    required this.targetEmoji,
    required this.totalScore,
    required this.tier,
    required this.tierColor,
    required this.gapPercent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8D5B7).withAlpha(80), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 앱 이름
          const Text('닮은꼴 찾기',
              style: TextStyle(
                  fontSize: 10, color: Color(0xFF555555),
                  letterSpacing: 3, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),

          // 메인 동물상
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(mainEmoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mainAnimal,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold,
                          color: Color(0xFFE8D5B7))),
                  Text('$mainPercent%',
                      style: TextStyle(
                          fontSize: 16, color: tierColor,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 복합 바
          Row(
            children: [
              Expanded(
                flex: mainPercent,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8D5B7),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                flex: subPercent,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A90D9),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                flex: (100 - mainPercent - subPercent).clamp(0, 100),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('$mainEmoji $mainAnimal $mainPercent%',
                  style: const TextStyle(fontSize: 9, color: Color(0xFF888888))),
              const SizedBox(width: 8),
              Text('$subEmoji $subAnimal $subPercent%',
                  style: const TextStyle(fontSize: 9, color: Color(0xFF666666))),
            ],
          ),
          const SizedBox(height: 14),

          // 구분선
          Container(height: 0.5, color: const Color(0xFF1E1E1E)),
          const SizedBox(height: 14),

          // 점수 + 목표
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('얼굴 균형 점수',
                        style: TextStyle(fontSize: 9, color: Color(0xFF555555))),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text('$totalScore',
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.w900,
                                color: tierColor)),
                        Text('/100  $tier등급',
                            style: TextStyle(fontSize: 11, color: tierColor.withAlpha(160))),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('목표',
                      style: TextStyle(fontSize: 9, color: Color(0xFF555555))),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(targetEmoji, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 4),
                      Text(targetAnimal,
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFFE8A030),
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Text('갭 $gapPercent%',
                      style: const TextStyle(fontSize: 9, color: Color(0xFF666666))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // "나도 따라해보기" CTA — 공유 카드 마지막 줄
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8D5B7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app_rounded, size: 14, color: Color(0xFF1A0F00)),
                SizedBox(width: 6),
                Text('나도 따라해보기',
                    style: TextStyle(
                        fontSize: 13, color: Color(0xFF1A0F00),
                        fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Text('Play 스토어 → 닮은꼴 찾기 검색',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 9, color: Color(0xFF555555))),
          const SizedBox(height: 10),

          // 해시태그
          const Text('#ApexAura  #동물상분석  #나의동물상',
              style: TextStyle(fontSize: 9, color: Color(0xFF444444), letterSpacing: 0.5)),
        ],
      ),
    );
  }
}
