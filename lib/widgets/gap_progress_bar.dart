import 'package:flutter/material.dart';

class GapProgressBar extends StatelessWidget {
  final int gapPercent;

  const GapProgressBar({super.key, required this.gapPercent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('변화 거리', style: TextStyle(color: Colors.white70)),
              Text('$gapPercent%',
                  style: const TextStyle(
                      color: Color(0xFFE8D5B7), fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: gapPercent / 100,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation(Color(0xFFE8D5B7)),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
