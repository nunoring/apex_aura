import 'package:flutter/material.dart';

class AppearanceScoreWidget extends StatelessWidget {
  final double score;
  final double currentLimit;
  final double optimizedLimit;
  final String tierDescription;

  const AppearanceScoreWidget({
    super.key,
    required this.score,
    required this.currentLimit,
    required this.optimizedLimit,
    required this.tierDescription,
  });

  bool get _showScore => score >= 6.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8D5B7).withAlpha(77)),
      ),
      child: Column(
        children: [
          const Text('외모 점수',
              style: TextStyle(
                  color: Color(0xFFE8D5B7),
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const SizedBox(height: 16),
          if (_showScore) ...[
            Text(score.toStringAsFixed(1),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 56,
                    fontWeight: FontWeight.bold)),
            const Text('/ 10',
                style: TextStyle(color: Colors.white38, fontSize: 20)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _limitBadge('현재 한계', currentLimit),
                const SizedBox(width: 16),
                const Icon(Icons.arrow_forward,
                    color: Color(0xFFE8D5B7), size: 16),
                const SizedBox(width: 16),
                _limitBadge('최적화 시', optimizedLimit, highlight: true),
              ],
            ),
          ] else ...[
            const Icon(Icons.analytics_outlined,
                color: Colors.white38, size: 48),
            const SizedBox(height: 8),
            const Text('외모 점수 분석 불가',
                style: TextStyle(color: Colors.white54)),
          ],
          const SizedBox(height: 16),
          Text(tierDescription,
              style:
                  const TextStyle(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _limitBadge(String label, double value, {bool highlight = false}) {
    return Column(
      children: [
        Text(label,
            style:
                const TextStyle(color: Colors.white38, fontSize: 11)),
        Text(value.toStringAsFixed(1),
            style: TextStyle(
              color:
                  highlight ? const Color(0xFFE8D5B7) : Colors.white54,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            )),
      ],
    );
  }
}
