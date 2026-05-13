import 'package:flutter/material.dart';

class AnimalMatchWidget extends StatelessWidget {
  final String animalType;
  final int percentage;
  final List<String> similarityPoints;

  const AnimalMatchWidget({
    super.key,
    required this.animalType,
    required this.percentage,
    required this.similarityPoints,
  });

  String get _emoji {
    const map = {
      '강아지': '🐶', '고양이': '🐱', '여우': '🦊',
      '곰': '🐻', '토끼': '🐰', '사슴': '🦌', '늑대': '🐺',
    };
    for (final e in map.entries) {
      if (animalType.contains(e.key)) return e.value;
    }
    return '✨';
  }

  Color _barColor() {
    if (percentage >= 85) return const Color(0xFF27AE60);
    if (percentage >= 70) return const Color(0xFFE8A030);
    return const Color(0xFF4A90D9);
  }

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
          // 헤더
          Row(
            children: [
              Text(_emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(animalType,
                        style: const TextStyle(
                            color: Color(0xFFE8D5B7),
                            fontSize: 17,
                            fontWeight: FontWeight.bold)),
                    Text('$percentage% 매칭',
                        style: TextStyle(
                            color: _barColor(), fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 퍼센트 바
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(_barColor()),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 16),
          const Text('닮은 이유',
              style: TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          ...similarityPoints.map((point) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('✓  ',
                        style: TextStyle(color: Color(0xFFE8D5B7), fontSize: 13)),
                    Expanded(
                      child: Text(point,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13, height: 1.5)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
