import 'package:flutter/material.dart';

class ColorPaletteGuide extends StatelessWidget {
  final List<String> main;
  final List<String> accent;
  final List<String> avoid;

  const ColorPaletteGuide({
    super.key,
    required this.main,
    required this.accent,
    required this.avoid,
  });

  Color _fromHex(String hex) {
    final h = hex.replaceAll('#', '');
    if (h.length != 6) return Colors.grey;
    return Color(int.parse('FF$h', radix: 16));
  }

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
          const Text('컬러 팔레트',
              style: TextStyle(
                  color: Color(0xFFE8D5B7),
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _row('메인', main),
          const SizedBox(height: 8),
          _row('포인트', accent),
          const SizedBox(height: 8),
          _row('피할 색', avoid, isAvoid: true),
        ],
      ),
    );
  }

  Widget _row(String label, List<String> colors,
      {bool isAvoid = false}) {
    return Row(
      children: [
        SizedBox(
            width: 52,
            child: Text(label,
                style: const TextStyle(
                    color: Colors.white54, fontSize: 12))),
        ...colors.map((hex) => Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: _fromHex(hex),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white12),
                  ),
                ),
                if (isAvoid)
                  const Icon(Icons.close, color: Colors.white, size: 14),
              ],
            )),
      ],
    );
  }
}
