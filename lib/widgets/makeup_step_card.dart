import 'package:flutter/material.dart';
import 'affiliate_chip.dart';

class MakeupStepCard extends StatelessWidget {
  final int stepNumber;
  final String stepName;
  final String description;
  final List<Map> products;
  final String tip;

  const MakeupStepCard({
    super.key,
    required this.stepNumber,
    required this.stepName,
    required this.description,
    required this.products,
    required this.tip,
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
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                    color: Color(0xFFE8D5B7), shape: BoxShape.circle),
                child: Center(
                  child: Text('$stepNumber',
                      style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),
              ),
              const SizedBox(width: 10),
              Text(stepName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ],
          ),
          const SizedBox(height: 10),
          Text(description,
              style:
                  const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 12),
          ...products.map((p) => AffiliateChip(
                name: p['name']?.toString() ?? '',
                url: p['affiliate_url']?.toString() ?? '',
                platform: p['platform']?.toString() ?? 'coupang',
              )),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8D5B7).withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline,
                    color: Color(0xFFE8D5B7), size: 14),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(tip,
                        style: const TextStyle(
                            color: Color(0xFFE8D5B7), fontSize: 12))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
