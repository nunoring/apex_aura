import 'package:flutter/material.dart';

class GroomingKeywordChip extends StatelessWidget {
  final String label;
  const GroomingKeywordChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8D5B7).withAlpha(31),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: const Color(0xFFE8D5B7).withAlpha(102)),
      ),
      child: Text(label,
          style:
              const TextStyle(color: Color(0xFFE8D5B7), fontSize: 13)),
    );
  }
}
