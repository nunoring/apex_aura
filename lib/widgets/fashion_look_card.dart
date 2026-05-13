import 'package:flutter/material.dart';

class FashionLookCard extends StatelessWidget {
  final String name;
  final List<Map> items;
  final String rationale;

  const FashionLookCard({
    super.key,
    required this.name,
    required this.items,
    required this.rationale,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name,
              style: const TextStyle(
                  color: Color(0xFFE8D5B7),
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const SizedBox(height: 8),
          Text(rationale,
              style: const TextStyle(color: Colors.white60, fontSize: 13)),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${item['category'] ?? ''}  ${item['description'] ?? ''}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              )),
        ],
      ),
    );
  }
}
