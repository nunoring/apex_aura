import 'package:flutter/material.dart';

class ResultCTA extends StatelessWidget {
  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback onReanalyze;

  const ResultCTA({
    super.key,
    required this.onSave,
    required this.onShare,
    required this.onReanalyze,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: onSave,
          icon: const Icon(Icons.download),
          label: const Text('결과 저장'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE8D5B7),
            foregroundColor: Colors.black,
            minimumSize: const Size(double.infinity, 52),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onShare,
                icon: const Icon(Icons.share, size: 16),
                label: const Text('공유'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white24),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onReanalyze,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('재분석'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white24),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
