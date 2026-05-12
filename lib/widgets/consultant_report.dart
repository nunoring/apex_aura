import 'package:flutter/material.dart';

class ConsultantReport extends StatelessWidget {
  final String quote;
  final String gap;
  final String direction;
  final String? observation;
  final String? impact;
  final bool isPro;

  const ConsultantReport({
    super.key,
    required this.quote,
    required this.gap,
    required this.direction,
    this.observation,
    this.impact,
    required this.isPro,
  });

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
            children: const [
              Icon(Icons.format_quote, color: Color(0xFFE8D5B7), size: 20),
              SizedBox(width: 8),
              Text('컨설턴트 리포트',
                  style: TextStyle(
                      color: Color(0xFFE8D5B7), fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text('"$quote"',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontStyle: FontStyle.italic)),
          const SizedBox(height: 16),
          if (isPro && observation != null) _buildRow('관찰', observation!),
          if (isPro && impact != null) _buildRow('영향', impact!),
          _buildRow('핵심 갭', gap),
          _buildRow('방향성', direction),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(label,
                style: const TextStyle(
                    color: Color(0xFFE8D5B7),
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value,
                style:
                    const TextStyle(color: Colors.white70, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
