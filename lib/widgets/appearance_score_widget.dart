import 'package:flutter/material.dart';

class AppearanceScoreWidget extends StatelessWidget {
  final int score;
  final int maxScore;
  final Map<String, double> scores;

  const AppearanceScoreWidget({
    super.key,
    required this.score,
    required this.maxScore,
    required this.scores,
  });

  static const _labelMap = {
    'eye': '눈매',
    'balance': '균형감',
    'face_shape': '얼굴형',
    'eye_distance': '눈간격',
    'skin': '피부',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8D5B7).withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$score',
                style: const TextStyle(
                  color: Color(0xFFE8D5B7),
                  fontSize: 52,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  ' / 100',
                  style: TextStyle(color: Colors.white38, fontSize: 18),
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('외모 점수',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 4),
                  _scoreTierBadge(score),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...(_labelMap.keys.map((key) => _scoreRow(
                _labelMap[key] ?? key,
                scores[key] ?? 6.5,
              ))),
        ],
      ),
    );
  }

  Widget _scoreRow(String label, double value) {
    final color = value >= 7.5
        ? const Color(0xFFE8D5B7)
        : value >= 6.0
            ? Colors.white54
            : Colors.white24;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(label,
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (value / 10).clamp(0.0, 1.0),
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value.toStringAsFixed(1),
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _scoreTierBadge(int s) {
    String label;
    Color color;
    if (s >= 80) {
      label = '상위 10%';
      color = const Color(0xFFE8D5B7);
    } else if (s >= 70) {
      label = '상위 30%';
      color = Colors.white70;
    } else {
      label = '상위 50%';
      color = Colors.white38;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(31),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(102)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11)),
    );
  }
}
