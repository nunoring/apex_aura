import 'package:flutter/material.dart';

class AnimalCompareCard extends StatelessWidget {
  final String currentAnimal;
  final String targetAnimal;
  final List<String> currentKeywords;
  final List<String> targetKeywords;

  const AnimalCompareCard({
    super.key,
    required this.currentAnimal,
    required this.targetAnimal,
    required this.currentKeywords,
    required this.targetKeywords,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(child: _buildSide(currentAnimal, currentKeywords, isTarget: false)),
          Column(
            children: [
              const Icon(Icons.arrow_forward, color: Color(0xFFE8D5B7)),
              const SizedBox(height: 4),
              const Text('변화', style: TextStyle(color: Color(0xFFE8D5B7), fontSize: 11)),
            ],
          ),
          Expanded(child: _buildSide(targetAnimal, targetKeywords, isTarget: true)),
        ],
      ),
    );
  }

  Widget _buildSide(String animal, List<String> keywords, {required bool isTarget}) {
    return Column(
      children: [
        Text(isTarget ? '목표' : '현재',
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 8),
        Text(animal,
            style: TextStyle(
              color: isTarget ? const Color(0xFFE8D5B7) : Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            )),
        const SizedBox(height: 8),
        ...keywords.map((k) => Text('• $k',
            style: const TextStyle(color: Colors.white70, fontSize: 12))),
      ],
    );
  }
}
