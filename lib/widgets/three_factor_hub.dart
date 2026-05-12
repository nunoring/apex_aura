import 'package:flutter/material.dart';

class ThreeFactorHub extends StatelessWidget {
  final Map physical;
  final Map face;
  final Map fashion;

  const ThreeFactorHub({
    super.key,
    required this.physical,
    required this.face,
    required this.fashion,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('3박자 솔루션',
            style: TextStyle(
                color: Color(0xFFE8D5B7),
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        _FactorCard(icon: Icons.fitness_center, title: '피지컬', data: physical),
        const SizedBox(height: 12),
        _FactorCard(icon: Icons.face, title: '얼굴', data: face),
        const SizedBox(height: 12),
        _FactorCard(icon: Icons.style, title: '패션', data: fashion),
      ],
    );
  }
}

class _FactorCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Map data;

  const _FactorCard(
      {required this.icon, required this.title, required this.data});

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
            children: [
              Icon(icon, color: const Color(0xFFE8D5B7), size: 18),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      color: Color(0xFFE8D5B7),
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ...data.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• ${e.value}',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13)),
              )),
        ],
      ),
    );
  }
}
