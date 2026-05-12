import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _scanController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scanController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < 2) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      _goHome();
    }
  }

  Future<void> _goHome() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            children: [
              _buildPage1(),
              _buildPage2(),
              _buildPage3(),
            ],
          ),
          // 건너뛰기 (Page 1, 2만)
          if (_currentPage < 2)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 20,
              child: GestureDetector(
                onTap: _goHome,
                child: const Text('건너뛰기',
                    style: TextStyle(fontSize: 13, color: Color(0xFF444444))),
              ),
            ),
          // 하단 인디케이터
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildBottom(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottom() {
    return Container(
      color: const Color(0xFF0D0D0D),
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).padding.bottom + 20),
      child: Row(
        children: [
          // 도트
          Row(
            children: List.generate(3, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(right: 6),
              width: i == _currentPage ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == _currentPage
                    ? const Color(0xFFE8D5B7)
                    : const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(3),
              ),
            )),
          ),
          const Spacer(),
          // 다음/시작 버튼
          GestureDetector(
            onTap: _next,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: EdgeInsets.symmetric(
                  horizontal: _currentPage == 2 ? 28 : 20,
                  vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFE8D5B7),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _currentPage == 2 ? '내 결과 받기' : '다음',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A0F00)),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward,
                      size: 16, color: Color(0xFF1A0F00)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Page 1: 브랜딩 훅 (Hero 이미지 풀스크린) ──────────────────
  Widget _buildPage1() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 히어로 이미지 풀스크린
          Image.asset('assets/images/onboarding_hero.png', fit: BoxFit.cover),
          // 텍스트 — 하단 그라디언트 컨테이너에 포함
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(28, 50, 28, 120),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xFF0D0D0D)],
                  stops: [0.0, 0.65],
                ),
              ),
              child: const Text('당신의 얼굴을\n수치로 분석합니다',
                  style: TextStyle(
                      fontSize: 30, fontWeight: FontWeight.w800,
                      color: Colors.white, height: 1.2, letterSpacing: -0.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanCard() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E1E1E), width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // 격자 패턴
            Positioned.fill(child: CustomPaint(painter: _GridPainter())),
            // 중앙 얼굴 실루엣
            Center(
              child: Container(
                width: 80, height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: const Color(0xFF2A2A2A), width: 0.5),
                ),
                child: const Icon(Icons.person_outline,
                    color: Color(0xFF333333), size: 48),
              ),
            ),
            // 스캔 라인
            AnimatedBuilder(
              animation: _scanController,
              builder: (_, __) => Positioned(
                top: 200 * _scanController.value,
                left: 0, right: 0,
                child: Container(
                  height: 2,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Color(0xFFE8D5B7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // 코너 마커
            ..._buildCorners(),
            // 하단 텍스트
            Positioned(
              bottom: 14, left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('얼굴 스캔 중...',
                      style: TextStyle(fontSize: 10, color: Color(0xFFE8A030))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCorners() {
    const c = Color(0xFFE8D5B7);
    const s = 14.0;
    const t = 16.0;
    return [
      Positioned(top: t, left: t,
          child: CustomPaint(size: const Size(s, s), painter: _CornerPainter(0, c))),
      Positioned(top: t, right: t,
          child: CustomPaint(size: const Size(s, s), painter: _CornerPainter(1, c))),
      Positioned(bottom: t, left: t,
          child: CustomPaint(size: const Size(s, s), painter: _CornerPainter(2, c))),
      Positioned(bottom: t, right: t,
          child: CustomPaint(size: const Size(s, s), painter: _CornerPainter(3, c))),
    ];
  }

  // ─── Page 2: 기능 미리보기 ────────────────────────────────────
  Widget _buildPage2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('이런 걸 알려드려요',
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFF0F0F0),
                  letterSpacing: -0.5)),
          const SizedBox(height: 6),
          const Text('지금보다 더 매력적인 내가 될 수 있어요',
              style: TextStyle(fontSize: 14, color: Color(0xFF666666))),
          const SizedBox(height: 32),
          _buildFeatureCard(
            icon: Icons.auto_fix_high,
            iconColor: const Color(0xFF27AE60),
            title: '맞춤 변신 플랜',
            desc: '현재 상태 분석 → 선택지별 효과 제시.\n헤어·피부·그루밍·시술까지 Before/After로 안내합니다.',
            highlight: '2024~2025 트렌드 반영',
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            icon: Icons.analytics_outlined,
            iconColor: const Color(0xFF4A90D9),
            title: '추구미 갭 분석',
            desc: '목표 동물상까지의 거리를 항목별로 수치화하고\n달성 난이도와 개선 우선순위를 알려드립니다.',
            highlight: '얼굴 균형 S~D 등급 분석',
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            icon: Icons.face_retouching_natural,
            iconColor: const Color(0xFFE8A030),
            title: '동물상 정밀 분류',
            desc: '눈꼬리 각도·얼굴 비율·코 형태·눈 간격을 수치로 측정해\n강아지/고양이/늑대/여우/곰상을 AI가 정밀 판별합니다.',
            highlight: '매번 같은 결과 — 수학적 분류',
          ),
        ],
      ),
    );
  }

  Widget _heroBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(40), width: 0.5),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 11, color: Color(0xFFCCCCCC), letterSpacing: 0.3)),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
    required String highlight,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E1E1E), width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: iconColor.withAlpha(60), width: 0.5),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE8D5B7))),
                const SizedBox(height: 4),
                Text(desc,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF777777),
                        height: 1.5)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1900),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF2A2200), width: 0.5),
                  ),
                  child: Text(highlight,
                      style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFFE8A030),
                          fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Page 3: 예시 결과 카드 ───────────────────────────────────
  Widget _buildPage3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 72, 24, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('이런 결과를 받아보세요',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFF0F0F0),
                  letterSpacing: -0.5)),
          const SizedBox(height: 6),
          const Text('실제 분석 결과 미리보기 · 내 결과는 사진 업로드 후 생성',
              style: TextStyle(fontSize: 12, color: Color(0xFF555555))),
          const SizedBox(height: 16),

          // 예시 카드 헤더
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF1E1E1E), width: 0.5),
            ),
            child: Column(
              children: [
                // 얼굴 플레이스홀더 + 오버레이
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      // 예시 얼굴 이미지
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/images/onboarding_example.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      // 예시 오버레이 선들
                      Positioned.fill(child: CustomPaint(painter: _ExampleOverlayPainter())),
                      // 배지
                      Positioned(
                        top: 10, right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('예시',
                              style: TextStyle(
                                  fontSize: 10, color: Color(0xFFE8D5B7))),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // 동물상 분류
                Row(
                  children: [
                    const Text('🐺', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('현재 늑대상',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFE8D5B7))),
                        const Text('ML Kit 수치 분석',
                            style: TextStyle(
                                fontSize: 10, color: Color(0xFF555544))),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A00),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(0xFF3A3A00), width: 0.5),
                      ),
                      child: const Text('추구미: 고양이상',
                          style: TextStyle(
                              fontSize: 11, color: Color(0xFFA08040))),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 수치 3개
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1E1E1E), width: 0.5),
            ),
            child: Row(
              children: [
                _exampleStat('눈꼬리', '+3.2°', '올라감'),
                _exampleDivider(),
                _exampleStat('황금비율', '0.34', '이상적'),
                _exampleDivider(),
                _exampleStat('얼굴형', '계란형', ''),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 갭 분석 샘플
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1E1E1E), width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('갭 분석',
                    style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF555555),
                        letterSpacing: 0.5)),
                const SizedBox(height: 10),
                _exampleGapBar('헤어스타일', 0.75, const Color(0xFFE8A030), '관리 필요'),
                const SizedBox(height: 8),
                _exampleGapBar('눈매 그루밍', 0.45, const Color(0xFF27AE60), '바로 가능'),
                const SizedBox(height: 8),
                _exampleGapBar('눈매 형태', 0.85, const Color(0xFFC0392B), '골격 요인'),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 변신 플랜 티저
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1E1E1E), width: 0.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.content_cut,
                    size: 16, color: Color(0xFFE8A030)),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('추천 헤어컷: 투블럭 + 앞머리 내리기',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFFCCCCCC))),
                      SizedBox(height: 2),
                      Text('"옆머리는 2cm, 위는 6cm 길이로 잘라주세요"',
                          style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF666666),
                              fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Center(
            child: Text(
              '다음 화면에서 사진을 올리면 AI가 바로 분석해드려요',
              style: TextStyle(fontSize: 12, color: Color(0xFF444444)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _exampleStat(String label, String value, String sub) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF555555),
                  letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFDDDDDD))),
          if (sub.isNotEmpty)
            Text(sub,
                style: const TextStyle(fontSize: 9, color: Color(0xFF777777))),
        ],
      ),
    );
  }

  Widget _exampleDivider() {
    return Container(
        width: 0.5, height: 32, color: const Color(0xFF1E1E1E));
  }

  Widget _exampleGapBar(String label, double value, Color color, String tag) {
    return Row(
      children: [
        SizedBox(
          width: 76,
          child: Text(label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: const Color(0xFF222222),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 58,
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(tag,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 9, color: color)),
        ),
      ],
    );
  }
}

// ─── 보조 Painters ─────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..strokeWidth = 0.5;
    const step = 24.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}

class _CornerPainter extends CustomPainter {
  final int corner; // 0=TL, 1=TR, 2=BL, 3=BR
  final Color color;

  _CornerPainter(this.corner, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    final s = size.width;
    switch (corner) {
      case 0: // TL
        canvas.drawLine(Offset(0, s), const Offset(0, 0), paint);
        canvas.drawLine(const Offset(0, 0), Offset(s, 0), paint);
      case 1: // TR
        canvas.drawLine(Offset(0, 0), Offset(s, 0), paint);
        canvas.drawLine(Offset(s, 0), Offset(s, s), paint);
      case 2: // BL
        canvas.drawLine(const Offset(0, 0), Offset(0, s), paint);
        canvas.drawLine(Offset(0, s), Offset(s, s), paint);
      case 3: // BR
        canvas.drawLine(Offset(s, 0), Offset(s, s), paint);
        canvas.drawLine(Offset(s, s), Offset(0, s), paint);
    }
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}

class _ExampleOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final linePaint = Paint()
      ..color = const Color(0xFFE8D5B7).withAlpha(100)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    final eyePaint = Paint()
      ..color = const Color(0xFFE8A030).withAlpha(160)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final dotPaint = Paint()
      ..color = const Color(0xFFE8A030)
      ..style = PaintingStyle.fill;

    // 얼굴 바운딩박스
    final boxRect = Rect.fromCenter(
        center: Offset(cx, cy), width: size.width * 0.55, height: size.height * 0.82);
    canvas.drawRRect(
        RRect.fromRectAndRadius(boxRect, const Radius.circular(8)),
        Paint()
          ..color = const Color(0xFFE8D5B7).withAlpha(60)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke);

    // 중심 세로선
    canvas.drawLine(Offset(cx, boxRect.top), Offset(cx, boxRect.bottom),
        Paint()
          ..color = const Color(0xFFE8D5B7).withAlpha(30)
          ..strokeWidth = 0.8
          ..style = PaintingStyle.stroke);

    // 눈 연결선
    final leX = cx - size.width * 0.13;
    final reX = cx + size.width * 0.13;
    final eyeY = cy - size.height * 0.12;
    canvas.drawLine(Offset(leX, eyeY + 2), Offset(reX, eyeY - 2), eyePaint);

    // 가로선들
    for (final y in [eyeY, cy + size.height * 0.05, cy + size.height * 0.2]) {
      canvas.drawLine(Offset(boxRect.left, y), Offset(boxRect.right, y), linePaint);
    }

    // 랜드마크 점
    for (final pos in [
      Offset(leX, eyeY + 2),
      Offset(reX, eyeY - 2),
      Offset(cx, cy + size.height * 0.05),
      Offset(cx - 12, cy + size.height * 0.2),
      Offset(cx + 12, cy + size.height * 0.2),
    ]) {
      canvas.drawCircle(pos, 3.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_ExampleOverlayPainter old) => false;
}
