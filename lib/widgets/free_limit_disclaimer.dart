import 'package:flutter/material.dart';

class FreeLimitDisclaimer extends StatelessWidget {
  const FreeLimitDisclaimer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      '* Free 분석은 핵심 방향성만 제공합니다. 전체 데이터는 Pro에서 확인하세요.',
      style: TextStyle(color: Colors.white38, fontSize: 11),
      textAlign: TextAlign.center,
    );
  }
}
