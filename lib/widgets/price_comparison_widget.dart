import 'package:flutter/material.dart';

class PriceComparisonWidget extends StatelessWidget {
  const PriceComparisonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: const [
                Text('오프라인 컨설팅',
                    style:
                        TextStyle(color: Colors.white54, fontSize: 12)),
                SizedBox(height: 4),
                Text('300,000원',
                    style: TextStyle(
                        color: Colors.white38,
                        fontSize: 18,
                        decoration: TextDecoration.lineThrough)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward,
              color: Color(0xFFE8D5B7)),
          Expanded(
            child: Column(
              children: const [
                Text('Apex Aura Pro',
                    style: TextStyle(
                        color: Color(0xFFE8D5B7), fontSize: 12)),
                SizedBox(height: 4),
                Text('9,900원',
                    style: TextStyle(
                        color: Color(0xFFE8D5B7),
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                Text('/월',
                    style: TextStyle(
                        color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
