import 'package:flutter/material.dart';

class ProductChip extends StatelessWidget {
  final String name;
  final String? shade;
  final String? category;
  final String? usage;

  const ProductChip({
    super.key,
    required this.name,
    this.shade,
    this.category,
    this.usage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, color: Color(0xFFE8D5B7), size: 6),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name + (shade != null ? ' ($shade)' : ''),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                if (usage != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    usage!,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          if (category != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                category!,
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ),
        ],
      ),
    );
  }
}
