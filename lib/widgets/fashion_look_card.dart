import 'package:flutter/material.dart';
import 'affiliate_chip.dart';

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
              style: const TextStyle(
                  color: Colors.white60, fontSize: 13)),
          const SizedBox(height: 12),
          ...items.map((item) {
            final aff = item['affiliate'] as Map?;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item['category']} — ${item['description']}',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13),
                ),
                if (aff != null) ...[
                  const SizedBox(height: 6),
                  AffiliateChip(
                    name: aff['name']?.toString() ?? '',
                    url: aff['url']?.toString() ?? '',
                    platform: aff['platform']?.toString() ?? 'coupang',
                  ),
                ],
                const SizedBox(height: 8),
              ],
            );
          }),
        ],
      ),
    );
  }
}
