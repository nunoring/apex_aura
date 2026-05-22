import 'dart:math' as math;
import 'package:flutter/material.dart';

class Strength {
  final String title;
  final String description;
  const Strength({required this.title, required this.description});

  factory Strength.fromJson(Map<String, dynamic> json) => Strength(
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
      );
}

class MainAnimalFlipCard extends StatefulWidget {
  final String name;
  final String emoji;
  final List<String> keywords;
  final List<Strength> strengths;
  final String tip;
  final String? imagePath;

  const MainAnimalFlipCard({
    super.key,
    required this.name,
    required this.emoji,
    required this.keywords,
    required this.strengths,
    required this.tip,
    this.imagePath,
  });

  @override
  State<MainAnimalFlipCard> createState() => _MainAnimalFlipCardState();
}

class _MainAnimalFlipCardState extends State<MainAnimalFlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  bool _isFlipped = false;

  static const _gold = Color(0xFFE8D5B7);
  static const _bg = Color(0xFF161616);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _anim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _flip() {
    _isFlipped ? _ctrl.reverse() : _ctrl.forward();
    setState(() => _isFlipped = !_isFlipped);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) {
          final showFront = _anim.value < 0.5;
          final angle = _anim.value * math.pi;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: showFront
                ? _front()
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: _back(),
                  ),
          );
        },
      ),
    );
  }

  Widget _front() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _bg,
        border: Border.all(color: _gold, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('메인 동물상',
              style: TextStyle(
                  color: _gold, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 16),
          // 이미지 우선, 없으면 이모지
          if (widget.imagePath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                widget.imagePath!,
                width: 110,
                height: 110,
                fit: BoxFit.cover,
                alignment: const Alignment(0, -0.6),
                errorBuilder: (_, __, ___) =>
                    Text(widget.emoji, style: const TextStyle(fontSize: 60)),
              ),
            )
          else
            Text(widget.emoji, style: const TextStyle(fontSize: 60)),
          const SizedBox(height: 12),
          Text(widget.name,
              style: const TextStyle(
                  color: _gold, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(
            widget.keywords.join('  ·  '),
            style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 13),
          ),
          const SizedBox(height: 20),
          const Text('AI가 가장 강하게 감지한 매력이에요',
              style: TextStyle(
                  color: Color(0xFF888877), fontSize: 12, fontStyle: FontStyle.italic)),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.touch_app_outlined, size: 14, color: Color(0xFF555555)),
            const SizedBox(width: 4),
            Text('탭하면 자세히 보기',
                style: TextStyle(color: _gold.withAlpha(120), fontSize: 11)),
          ]),
        ],
      ),
    );
  }

  Widget _back() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _bg,
        border: Border.all(color: _gold, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            if (widget.imagePath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  widget.imagePath!,
                  width: 28, height: 28, fit: BoxFit.cover,
                  alignment: const Alignment(0, -0.6),
                  errorBuilder: (_, __, ___) =>
                      Text(widget.emoji, style: const TextStyle(fontSize: 22)),
                ),
              )
            else
              Text(widget.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text('${widget.name}의 매력',
                style: const TextStyle(
                    color: _gold, fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 16),
          ...widget.strengths.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Text('✨ ', style: TextStyle(fontSize: 13)),
                      Text(s.title,
                          style: const TextStyle(
                              color: _gold, fontSize: 13, fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 3),
                    Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: Text(s.description,
                          style: const TextStyle(
                              color: Color(0xFFDDDDDD), fontSize: 12, height: 1.5)),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _gold.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡 활용 팁',
                    style: TextStyle(
                        color: _gold, fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(widget.tip,
                    style: const TextStyle(
                        color: Color(0xFFDDDDDD), fontSize: 12, height: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text('다시 탭하면 앞으로',
                style: TextStyle(color: _gold.withAlpha(100), fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
