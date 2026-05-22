import 'package:flutter/material.dart';

class SubAnimalCard extends StatelessWidget {
  final String name;
  final String emoji;
  final List<String> keywords;
  final String comment;
  final String? imagePath;

  static const _gold = Color(0xFFE8D5B7);

  const SubAnimalCard({
    super.key,
    required this.name,
    required this.emoji,
    required this.keywords,
    required this.comment,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border.all(color: _gold.withAlpha(77), width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('+ 보조 매력',
              style: TextStyle(
                  color: Color(0xFF888877), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          const SizedBox(height: 10),
          Row(children: [
            if (imagePath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  imagePath!,
                  width: 36, height: 36, fit: BoxFit.cover,
                  alignment: const Alignment(0, -0.6),
                  errorBuilder: (_, __, ___) =>
                      Text(emoji, style: const TextStyle(fontSize: 22)),
                ),
              )
            else
              Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Text(name,
                style: const TextStyle(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 4),
          Text(keywords.join('  ·  '),
              style: const TextStyle(color: _gold, fontSize: 12)),
          const SizedBox(height: 8),
          Text('"$comment"',
              style: const TextStyle(
                  color: Color(0xFFCCCCCC), fontSize: 12, fontStyle: FontStyle.italic, height: 1.5)),
        ],
      ),
    );
  }
}
