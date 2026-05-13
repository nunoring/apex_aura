import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as dart_ui;
import 'package:gal/gal.dart';
import 'subscription_service.dart';
import 'paywall_screen.dart';
import 'services/pdf_service.dart';
import 'services/share_service.dart';
import 'widgets/animal_compare_card.dart';
import 'widgets/gap_progress_bar.dart';
import 'widgets/gap_radar_chart.dart';
import 'widgets/consultant_report.dart';
import 'widgets/action_card.dart';
import 'widgets/appearance_score_widget.dart';
import 'widgets/grooming_keyword_chip.dart';
import 'widgets/three_factor_hub.dart';
import 'widgets/makeup_step_card.dart';
import 'widgets/affiliate_chip.dart';
import 'widgets/fashion_look_card.dart';
import 'widgets/color_palette_guide.dart';
import 'widgets/result_cta.dart';
import 'widgets/free_lock_teaser.dart';
import 'widgets/free_limit_disclaimer.dart';
import 'widgets/price_comparison_widget.dart';
import 'widgets/pro_paywall_sheet.dart';
import 'widgets/animal_match_widget.dart';
import 'widgets/main_animal_flip_card.dart';
import 'widgets/sub_animal_card.dart';
import 'widgets/target_animal_card.dart';

class ResultScreen extends StatefulWidget {
  final String animalType;
  final double sliderValue;
  final Map<String, dynamic> analysisResult;
  final File imageFile;
  final Map<String, dynamic> faceData;
  final String gender;

  const ResultScreen({
    super.key,
    required this.animalType,
    required this.sliderValue,
    required this.analysisResult,
    required this.imageFile,
    required this.faceData,
    this.gender = 'male',
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  final PageController _pageController = PageController();
  bool _isSharing = false;
  int _currentPage = 0;
  int _curriculumTab = 0;
  bool _isSubscribed = false;
  bool _isPro = false;
  List<Widget> _pages = [];
  final GlobalKey _shareKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initPageFlow();
  }

  Future<void> _initPageFlow() async {
    final isPro = await SubscriptionService.isSubscribed();
    if (!mounted) return;
    setState(() {
      _isPro = isPro;
      _isSubscribed = isPro;
      _pages = isPro ? _buildProPages() : _buildFreePages();
      _pageTitles = isPro
          ? ['첫인상', '외모 점수', '갭 분석', '3박자 솔루션', '메이크업', '패션 룩']
          : ['첫인상', '수치 분석', '갭 분석', '변신 플랜'];
    });
  }

  List<Widget> _buildFreePages() => [
    _buildPage1(),
    _buildPage2Free(),
    _buildPage3Free(),
    _buildPage4Free(),
  ];

  List<Widget> _buildProPages() => [
    _buildPage1Pro(),
    _buildPage2Pro(),
    _buildPage3Pro(),
    _buildPage4Pro(),
    _buildPage5Pro(),
    _buildPage6Pro(),
  ];

  // ─── Pro Page 1: 첫인상 + 외모 점수 ─────────────────────────────
  Widget _buildPage1Pro() {
    final fi = analysisResult['first_impression'] as Map<String, dynamic>?;
    final animalMatch = fi?['animal_match'] as Map<String, dynamic>?;
    final mainAnimal = fi?['main_animal'] as Map<String, dynamic>?;
    final appearanceScore = analysisResult['appearance_score'] as Map<String, dynamic>?;
    final rawScores = analysisResult['scores'] as Map<String, dynamic>?;

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildPage1(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (animalMatch != null) ...[
                  const Divider(color: Color(0xFF1E1E1E)),
                  const SizedBox(height: 12),
                  AnimalMatchWidget(
                    animalType: mainAnimal?['name']?.toString() ?? widget.animalType,
                    percentage: (animalMatch['percentage'] as num?)?.toInt() ?? 80,
                    similarityPoints: List<String>.from(animalMatch['similarity_points'] ?? []),
                  ),
                ],
                if (appearanceScore != null && rawScores != null) ...[
                  const SizedBox(height: 16),
                  AppearanceScoreWidget(
                    score: (appearanceScore['score'] as num?)?.toInt() ?? 70,
                    maxScore: (appearanceScore['max_score'] as num?)?.toInt() ?? 100,
                    scores: {
                      'eye': (rawScores['eye'] as num?)?.toDouble() ?? 6.5,
                      'balance': (rawScores['balance'] as num?)?.toDouble() ?? 6.5,
                      'face_shape': (rawScores['face_shape'] as num?)?.toDouble() ?? 6.5,
                      'eye_distance': (rawScores['eye_distance'] as num?)?.toDouble() ?? 6.5,
                      'skin': (rawScores['skin'] as num?)?.toDouble() ?? 6.5,
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaceRatioCard(Map<String, dynamic> fa) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('얼굴 비율 진단', style: TextStyle(color: Color(0xFFE8D5B7), fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ratioItem('상안부', '${fa['top_face_percent'] ?? '-'}%'),
              _ratioItem('중안부', '${fa['middle_face_percent'] ?? '-'}%'),
              _ratioItem('하안부', '${fa['bottom_face_percent'] ?? '-'}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ratioItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFE8D5B7))),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF666666))),
      ],
    );
  }

  // ─── Pro Page 2: 동물상 매칭 ─────────────────────────────────────
  Widget _buildPage2Pro() {
    final fi = analysisResult['first_impression'] as Map<String, dynamic>?;
    final mainA = fi?['main_animal'] as Map<String, dynamic>?;
    final subA = fi?['sub_animal'] as Map<String, dynamic>?;
    final targetA = fi?['target_animal'] as Map<String, dynamic>?;

    if (mainA == null) {
      return const Center(
        child: Text('동물상 데이터를 불러오는 중이에요',
            style: TextStyle(color: Color(0xFF555555))));
    }

    final strengths = (mainA['strengths'] as List? ?? [])
        .map((s) => Strength.fromJson(s as Map<String, dynamic>))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('당신의 동물상',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          const Text('두 가지 동물상의 매력을 함께 가지고 있어요',
              style: TextStyle(fontSize: 13, color: Color(0xFF666666))),
          const SizedBox(height: 20),

          MainAnimalFlipCard(
            name: mainA['name']?.toString() ?? '',
            emoji: mainA['emoji']?.toString() ?? '',
            keywords: List<String>.from(mainA['keywords'] ?? []),
            strengths: strengths,
            tip: mainA['tip']?.toString() ?? '',
          ),
          const SizedBox(height: 12),

          if (subA != null)
            SubAnimalCard(
              name: subA['name']?.toString() ?? '',
              emoji: subA['emoji']?.toString() ?? '',
              keywords: List<String>.from(subA['keywords'] ?? []),
              comment: subA['comment']?.toString() ?? '',
            ),
          const SizedBox(height: 10),

          if (targetA != null)
            TargetAnimalCard(
              name: targetA['name']?.toString() ?? '',
              emoji: targetA['emoji']?.toString() ?? '',
              keywords: List<String>.from(targetA['keywords'] ?? []),
              comment: targetA['comment']?.toString() ?? '',
            ),
        ],
      ),
    );
  }

  // (구) Pro Page 2 외모 점수 — Page 1로 이동됨
  Widget _buildPage2ProScore() {
    final s = _abilityScores;
    final appearanceScore = analysisResult['appearance_score'] as Map<String, dynamic>?;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 총점 카드
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1E1E1E), width: 0.5),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text('${appearanceScore?['score'] ?? s.total}',
                        style: TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: s.tierColor)),
                    const Text(' / 100', style: TextStyle(fontSize: 18, color: Color(0xFF444444))),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: s.tierColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: s.tierColor.withAlpha(80), width: 0.5),
                      ),
                      child: Text(s.tier, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: s.tierColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  appearanceScore?['tier_description']?.toString() ?? s.tagline,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                ),
                if (appearanceScore != null) ...[
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _proScoreMini('현재 한계', '${appearanceScore['current_limit'] ?? '-'}')),
                    Expanded(child: _proScoreMini('최적화 시', '${appearanceScore['optimized_limit'] ?? '-'}')),
                  ]),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 항목별 점수 바
          ...s.stats.map((stat) {
            final label = stat.$1;
            final score = stat.$2;
            final color = score >= 70 ? const Color(0xFF27AE60) : score >= 50 ? const Color(0xFFE8A030) : const Color(0xFFC0392B);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA))),
                    const Spacer(),
                    Text('$score', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: score / 100,
                      backgroundColor: const Color(0xFF222222),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _proScoreMini(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFE8D5B7))),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF555555))),
      ],
    );
  }

  // ─── Pro Page 3: 갭 분석 + 레이더 차트 ───────────────────────────
  Widget _buildPage3Pro() {
    final r = analysisResult;
    final comparison = r['comparison'] as Map<String, dynamic>?;
    final radar = r['radar'] as Map<String, dynamic>?;
    final report = r['consultant_report'] as Map<String, dynamic>?;
    final currentKw = List<String>.from(comparison?['current_keywords'] ?? []);
    final targetKw = List<String>.from(comparison?['target_keywords'] ?? []);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AnimalCompareCard (Free 버전 재사용)
          _buildPage3Free(),
          if (radar != null) ...[
            const SizedBox(height: 16),
            const Text('능력치 레이더', style: TextStyle(fontSize: 13, color: Color(0xFF666666))),
            const SizedBox(height: 12),
            _buildRadarChart(radar),
          ],
          if (report != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1E1E1E), width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: const [
                    Icon(Icons.person_outline, size: 14, color: Color(0xFFE8A030)),
                    SizedBox(width: 6),
                    Text('컨설턴트 풀 리포트', style: TextStyle(fontSize: 12, color: Color(0xFFE8A030), fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 10),
                  if (report['quote'] != null)
                    Text('"${report['quote']}"',
                        style: const TextStyle(fontSize: 13, color: Color(0xFFE8D5B7), fontStyle: FontStyle.italic, height: 1.5)),
                  const SizedBox(height: 8),
                  if (report['observation'] != null)
                    _reportRow('관찰', report['observation'].toString()),
                  if (report['impact'] != null)
                    _reportRow('인상', report['impact'].toString()),
                  if (report['gap'] != null)
                    _reportRow('갭', report['gap'].toString()),
                  if (report['direction'] != null)
                    _reportRow('방향', report['direction'].toString()),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _reportRow(String label, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 36, child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF555555)))),
          Expanded(child: Text(content, style: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA), height: 1.5))),
        ],
      ),
    );
  }

  Widget _buildRadarChart(Map<String, dynamic> radar) {
    final current = (radar['current'] as Map<String, dynamic>? ?? {});
    final target = (radar['target'] as Map<String, dynamic>? ?? {});
    final keys = current.keys.toList();
    if (keys.isEmpty) return const SizedBox.shrink();

    List<RadarDataSet> dataSets = [
      RadarDataSet(
        fillColor: const Color(0xFFE8A030).withAlpha(40),
        borderColor: const Color(0xFFE8A030),
        borderWidth: 1.5,
        entryRadius: 3,
        dataEntries: keys.map((k) => RadarEntry(value: ((current[k] as num?)?.toDouble() ?? 0.5) * 10)).toList(),
      ),
      RadarDataSet(
        fillColor: const Color(0xFF4A90D9).withAlpha(25),
        borderColor: const Color(0xFF4A90D9),
        borderWidth: 1.5,
        entryRadius: 3,
        dataEntries: keys.map((k) => RadarEntry(value: ((target[k] as num?)?.toDouble() ?? 0.8) * 10)).toList(),
      ),
    ];

    return SizedBox(
      height: 220,
      child: RadarChart(
        RadarChartData(
          dataSets: dataSets,
          radarBackgroundColor: Colors.transparent,
          borderData: FlBorderData(show: false),
          radarBorderData: const BorderSide(color: Color(0xFF2A2A2A), width: 0.5),
          titleTextStyle: const TextStyle(color: Color(0xFF666666), fontSize: 11),
          getTitle: (i, angle) => RadarChartTitle(text: i < keys.length ? keys[i] : ''),
          tickCount: 3,
          ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 0),
          tickBorderData: const BorderSide(color: Color(0xFF1E1E1E), width: 0.5),
          gridBorderData: const BorderSide(color: Color(0xFF1E1E1E), width: 0.5),
        ),
      ),
    );
  }

  // ─── Pro Page 4: 3박자 솔루션 ─────────────────────────────────────
  Widget _buildPage4Pro() {
    final r = analysisResult;
    final threeFactor = r['three_factor'] as Map<String, dynamic>?;
    final actionCards = (r['action_cards'] as List?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('3박자 솔루션', style: TextStyle(fontSize: 14, color: Color(0xFFE8D5B7), fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('신체관리 · 얼굴관리 · 패션', style: TextStyle(fontSize: 11, color: Color(0xFF555555))),
          const SizedBox(height: 16),

          if (threeFactor != null) ...[
            _threeFactorCard('💪 신체관리', threeFactor['physical']?.toString() ?? ''),
            const SizedBox(height: 10),
            _threeFactorCard('👤 얼굴관리', threeFactor['face']?.toString() ?? ''),
            const SizedBox(height: 10),
            _threeFactorCard('👔 패션', threeFactor['fashion']?.toString() ?? ''),
          ] else ...[
            ...actionCards.map((card) {
              final c = card as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _threeFactorCard(c['category']?.toString() ?? '', c['principle']?.toString() ?? ''),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _threeFactorCard(String title, String content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E1E1E), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, color: Color(0xFFE8D5B7), fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA), height: 1.6)),
        ],
      ),
    );
  }

  // ─── Pro Page 5: 메이크업 4단계 ──────────────────────────────────
  Widget _buildPage5Pro() {
    final steps = List<Map<String, dynamic>>.from(
        (analysisResult['makeup_steps'] as List?)?.map((e) => e as Map<String, dynamic>) ?? []);
    final actionCards = (analysisResult['action_cards'] as List?) ?? [];
    final makeupCard = actionCards.cast<Map<String, dynamic>>()
        .firstWhere((c) => c['icon'] == 'makeup' || c['category']?.toString().contains('메이크업') == true,
            orElse: () => <String, dynamic>{});

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('메이크업 가이드', style: TextStyle(fontSize: 14, color: Color(0xFFE8D5B7), fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),

          if (steps.isNotEmpty)
            ...steps.asMap().entries.map((e) {
              final step = e.value;
              final products = List<Map<String, dynamic>>.from(
                  (step['products'] as List?)?.map((p) => p as Map<String, dynamic>) ?? []);
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1E1E1E), width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        width: 24, height: 24,
                        decoration: const BoxDecoration(color: Color(0xFFE8A030), shape: BoxShape.circle),
                        child: Center(child: Text('${step['step_number'] ?? e.key + 1}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1A0F00)))),
                      ),
                      const SizedBox(width: 10),
                      Text(step['step_name']?.toString() ?? '',
                          style: const TextStyle(fontSize: 13, color: Color(0xFFE8D5B7), fontWeight: FontWeight.w600)),
                    ]),
                    if (step['description'] != null) ...[
                      const SizedBox(height: 8),
                      Text(step['description'].toString(),
                          style: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA), height: 1.5)),
                    ],
                    if (products.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ...products.map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('• ${p['name'] ?? ''} — ${p['description'] ?? ''}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF777777))),
                      )),
                    ],
                    if (step['tip'] != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1500),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('💡 ${step['tip']}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFFE8A030))),
                      ),
                    ],
                  ],
                ),
              );
            })
          else if (makeupCard.isNotEmpty) ...[
            _threeFactorCard(makeupCard['category']?.toString() ?? '메이크업', makeupCard['application']?.toString() ?? ''),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6, runSpacing: 4,
              children: (makeupCard['references'] as List? ?? []).map((ref) {
                final rm = ref as Map;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF2A2A2A), width: 0.5),
                  ),
                  child: Text('${rm['name']} · ${rm['context']}',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF666666))),
                );
              }).toList(),
            ),
          ] else
            const Center(child: Text('메이크업 데이터가 없어요', style: TextStyle(fontSize: 13, color: Color(0xFF444444)))),

          // Phase 2: _buildAffiliateDisclaimer() 복원
        ],
      ),
    );
  }

  // ─── Pro Page 6: 패션 룩 + PDF ────────────────────────────────────
  Widget _buildPage6Pro() {
    final looks = List<Map<String, dynamic>>.from(
        (analysisResult['fashion_looks'] as List?)?.map((e) => e as Map<String, dynamic>) ?? []);
    final palette = analysisResult['color_palette'] as Map<String, dynamic>?;
    final hasFashionCard = (analysisResult['action_cards'] as List?)
        ?.cast<Map<String, dynamic>>()
        .any((c) => c['category']?.toString().contains('패션') == true) ?? false;
    final fashionCard = hasFashionCard
        ? (analysisResult['action_cards'] as List)
            .cast<Map<String, dynamic>>()
            .firstWhere((c) => c['category']?.toString().contains('패션') == true)
        : <String, dynamic>{};

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 90,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('패션 룩', style: TextStyle(fontSize: 14, color: Color(0xFFE8D5B7), fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),

          if (looks.isNotEmpty)
            ...looks.map((look) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1E1E1E), width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(look['name']?.toString() ?? '',
                      style: const TextStyle(fontSize: 13, color: Color(0xFFE8D5B7), fontWeight: FontWeight.w600)),
                  if (look['rationale'] != null) ...[
                    const SizedBox(height: 6),
                    Text(look['rationale'].toString(),
                        style: const TextStyle(fontSize: 12, color: Color(0xFF888888), height: 1.5)),
                  ],
                  if ((look['items'] as List?)?.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    ...(look['items'] as List).map((item) {
                      final im = item as Map;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text('• ${im['name'] ?? im.toString()}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF666666))),
                      );
                    }),
                  ],
                ],
              ),
            ))
          else if (fashionCard.isNotEmpty)
            _threeFactorCard(fashionCard['category']?.toString() ?? '패션', fashionCard['application']?.toString() ?? '')
          else
            const Center(child: Text('패션 데이터가 없어요', style: TextStyle(fontSize: 13, color: Color(0xFF444444)))),

          if (palette != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1E1E1E), width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('컬러 팔레트', style: TextStyle(fontSize: 13, color: Color(0xFFE8D5B7), fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  _paletteRow('메인', List<String>.from(palette['main'] ?? []), const Color(0xFF27AE60)),
                  _paletteRow('포인트', List<String>.from(palette['accent'] ?? []), const Color(0xFFE8A030)),
                  _paletteRow('피할 색', List<String>.from(palette['avoid'] ?? []), const Color(0xFFC0392B)),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _isSharing ? null : _saveLongImage,
            icon: const Icon(Icons.photo_library_outlined, size: 18),
            label: const Text('현재 화면 갤러리 저장'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E1E1E),
              foregroundColor: const Color(0xFFE8D5B7),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => PdfService.generateAndOpen(analysisResult),
            icon: const Icon(Icons.download, size: 18),
            label: const Text('전체 분석 PDF 저장'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE8D5B7),
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
          // Phase 2: _buildAffiliateDisclaimer() 복원
        ],
      ),
    );
  }

  Widget _paletteRow(String label, List<String> colors, Color tagColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 44, child: Text(label, style: TextStyle(fontSize: 11, color: tagColor))),
          Expanded(
            child: Wrap(
              spacing: 6,
              children: colors.map((c) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tagColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: tagColor.withAlpha(50), width: 0.5),
                ),
                child: Text(c, style: TextStyle(fontSize: 10, color: tagColor)),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Phase 2: 어필리에이트 활성화 시 주석 해제
  // Widget _buildAffiliateDisclaimer() {
  //   return Container(
  //     width: double.infinity,
  //     padding: const EdgeInsets.all(12),
  //     decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(8)),
  //     child: const Text(
  //       '이 페이지의 제품 추천은 쿠팡 파트너스 활동의 일환으로,\n이에 따른 일정액의 수수료를 제공받습니다.',
  //       style: TextStyle(color: Colors.white54, fontSize: 11),
  //       textAlign: TextAlign.center,
  //     ),
  //   );
  // }

  Widget _buildPlaceholderPage(String title, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: const Color(0xFF333333)),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(fontSize: 16, color: Color(0xFF555555))),
          const SizedBox(height: 8),
          const Text('준비 중이에요',
              style: TextStyle(fontSize: 13, color: Color(0xFF444444))),
        ],
      ),
    );
  }

  // Free Page 2: 수치 분석 (구독 체크 없음)
  Widget _buildPage2Free() {
    return _buildPage2();
  }

  // Free Page 3: 갭 분석
  Widget _buildPage3Free() {
    final r = analysisResult;
    final comparison = r['comparison'] as Map<String, dynamic>?;
    final report = r['consultant_report'] as Map<String, dynamic>?;
    final gapPercent = (comparison?['gap_percent'] as num?)?.toDouble() ?? 50.0;
    final currentAnimal = comparison?['current_animal']?.toString() ?? '';
    final targetAnimal = comparison?['target_animal']?.toString() ?? widget.animalType;
    final currentKw = List<String>.from(comparison?['current_keywords'] ?? []);
    final targetKw = List<String>.from(comparison?['target_keywords'] ?? []);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AnimalCompareCard
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1E1E1E), width: 0.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('현재', style: TextStyle(fontSize: 10, color: Color(0xFF555555))),
                      const SizedBox(height: 4),
                      Text(currentAnimal,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFFE8D5B7))),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4, runSpacing: 4,
                        children: currentKw.map((kw) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF2A2A2A), width: 0.5),
                          ),
                          child: Text(kw, style: const TextStyle(fontSize: 10, color: Color(0xFF888888))),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.arrow_forward, size: 16, color: Color(0xFF444444)),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('목표', style: TextStyle(fontSize: 10, color: Color(0xFF555555))),
                      const SizedBox(height: 4),
                      Text(targetAnimal,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFFE8A030))),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4, runSpacing: 4, alignment: WrapAlignment.end,
                        children: targetKw.map((kw) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1500),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF2A2000), width: 0.5),
                          ),
                          child: Text(kw, style: const TextStyle(fontSize: 10, color: Color(0xFFE8A030))),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // GapProgressBar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1E1E1E), width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Text('갭 거리', style: TextStyle(fontSize: 12, color: Color(0xFF666666))),
                  const Spacer(),
                  Text('${gapPercent.round()}%', style: const TextStyle(fontSize: 13, color: Color(0xFFE8D5B7), fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: gapPercent / 100,
                    backgroundColor: const Color(0xFF222222),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      gapPercent > 60 ? const Color(0xFFC0392B) : gapPercent > 30 ? const Color(0xFFE8A030) : const Color(0xFF27AE60),
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  gapPercent > 60 ? '목표까지 큰 변화가 필요해요' : gapPercent > 30 ? '스타일링으로 충분히 도달할 수 있어요' : '현재와 목표가 가까워요',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ConsultantReport
          if (report != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1E1E1E), width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: const [
                    Icon(Icons.person_outline, size: 14, color: Color(0xFFE8A030)),
                    SizedBox(width: 6),
                    Text('컨설턴트 리포트', style: TextStyle(fontSize: 12, color: Color(0xFFE8A030), fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 10),
                  if (report['quote'] != null)
                    Text('"${report['quote']}"',
                        style: const TextStyle(fontSize: 13, color: Color(0xFFE8D5B7), fontStyle: FontStyle.italic, height: 1.5)),
                  if (report['gap'] != null) ...[
                    const SizedBox(height: 10),
                    Text(report['gap'].toString(),
                        style: const TextStyle(fontSize: 12, color: Color(0xFF888888), height: 1.5)),
                  ],
                  if (report['direction'] != null) ...[
                    const SizedBox(height: 6),
                    Text(report['direction'].toString(),
                        style: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA), height: 1.5)),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Free Page 4: 변신 플랜 + Pro 후크
  Widget _buildPage4Free() {
    final r = analysisResult;
    final actionCards = (r['action_cards'] as List?) ?? [];

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 90,
      ),
      child: RepaintBoundary(
        key: _shareKey,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('변신 플랜', style: TextStyle(fontSize: 14, color: Color(0xFFE8D5B7), fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),

          // 액션 카드 3개
          ...actionCards.map((card) {
            final c = card as Map<String, dynamic>;
            final refs = (c['references'] as List?) ?? [];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1E1E1E), width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c['category']?.toString() ?? '',
                      style: const TextStyle(fontSize: 13, color: Color(0xFFE8A030), fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  if (c['observation'] != null)
                    Text(c['observation'].toString(),
                        style: const TextStyle(fontSize: 12, color: Color(0xFF888888), height: 1.5)),
                  if (c['application'] != null) ...[
                    const SizedBox(height: 6),
                    Text(c['application'].toString(),
                        style: const TextStyle(fontSize: 13, color: Color(0xFFCCCCCC), height: 1.5)),
                  ],
                  if (refs.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6, runSpacing: 4,
                      children: refs.map((ref) {
                        final rm = ref as Map;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF2A2A2A), width: 0.5),
                          ),
                          child: Text('${rm['name']} · ${rm['context']}',
                              style: const TextStyle(fontSize: 10, color: Color(0xFF666666))),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            );
          }),

          const SizedBox(height: 16),

          // Pro 잠금 티저
          GestureDetector(
            onTap: _showPaywall,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1200),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8A030).withAlpha(60), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline, size: 20, color: Color(0xFFE8A030)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pro 전용 — 6가지 심층 분석',
                            style: TextStyle(fontSize: 13, color: Color(0xFFE8D5B7), fontWeight: FontWeight.w600)),
                        SizedBox(height: 3),
                        Text('외모 점수 · 메이크업 · 패션 룩 · 90일 마일스톤',
                            style: TextStyle(fontSize: 11, color: Color(0xFF888866))),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 18, color: Color(0xFFE8A030)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Free 안내 문구
          const Center(
            child: Text('무료 분석 · 상세 결과는 Pro에서 확인하세요',
                style: TextStyle(fontSize: 11, color: Color(0xFF444444))),
          ),
          const SizedBox(height: 24),

          // CTA 버튼들
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => ShareService.shareCard(_shareKey),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF2A2A2A), width: 0.5),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.share_outlined, size: 16, color: Color(0xFF888888)),
                        SizedBox(width: 6),
                        Text('공유', style: TextStyle(fontSize: 13, color: Color(0xFF888888))),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context, true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8D5B7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.refresh, size: 16, color: Color(0xFF1A0F00)),
                        SizedBox(width: 6),
                        Text('다시 분석', style: TextStyle(fontSize: 13, color: Color(0xFF1A0F00), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),    // Column
    ),      // RepaintBoundary
    );
  }

  Future<void> _showPaywall() async {
    final ok = await PaywallBottomSheet.show(context);
    if (ok && mounted) _initPageFlow();
  }

  Widget _buildGapPage() {
    final r = analysisResult;
    final gapList = r['gap_analysis'] as List?;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('갭 분석',
              style: TextStyle(fontSize: 14, color: Color(0xFFE8D5B7), fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('${r['comparison']?['current_animal'] ?? ''} → ${r['comparison']?['target_animal'] ?? widget.animalType}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF555555))),
          const SizedBox(height: 16),
          if (gapList != null && gapList.isNotEmpty)
            ...gapList.map((g) {
              final item = g['item']?.toString() ?? '';
              final score = (g['score'] as num?)?.toDouble() ?? 0.5;
              final tag = g['tag']?.toString() ?? '';
              final level = g['level']?.toString() ?? 'mid';
              final color = level == 'easy'
                  ? const Color(0xFF27AE60)
                  : level == 'hard'
                      ? const Color(0xFFC0392B)
                      : const Color(0xFFE8A030);
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(item, style: const TextStyle(fontSize: 13, color: Color(0xFFCCCCCC))),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withAlpha(30),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: color.withAlpha(80), width: 0.5),
                        ),
                        child: Text(tag, style: TextStyle(fontSize: 10, color: color)),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: score.clamp(0.0, 1.0),
                        backgroundColor: const Color(0xFF222222),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              );
            }),
          if (gapList == null || gapList.isEmpty) ...[
            const SizedBox(height: 40),
            const Center(
              child: Text('갭 분석 데이터가 없어요',
                  style: TextStyle(fontSize: 13, color: Color(0xFF444444))),
            ),
          ],
        ],
      ),
    );
  }

  // 능력치 점수 계산 (공유 카드와 앱 내 동일하게 사용)
  ({
    int total,
    String tier,
    Color tierColor,
    String tagline,
    String topPercent,
    List<(String, int)> stats,
  }) get _abilityScores {
    final goldenRatio = double.tryParse(faceData['golden_ratio']?.toString() ?? '0') ?? 0.0;
    final faceRatio   = double.tryParse(faceData['face_ratio']?.toString() ?? '0') ?? 0.0;
    final eyeAngle    = double.tryParse(faceData['eye_angle']?.toString() ?? '0') ?? 0.0;
    final eyeGap      = double.tryParse(faceData['eye_gap_ratio']?.toString() ?? '0') ?? 0.0;
    final skin        = analysisResult['skinAnalysis'] as Map<String, dynamic>?;
    final skinRaw     = skin?['overall']?.toString() ?? '보통';

    // 황금비율: 이상 범위(0.28~0.38)에 가까울수록 높은 점수, 이탈 시 35까지 하락 가능
    final goldenScore = ((1.0 - ((goldenRatio - 0.33).abs() / 0.15).clamp(0.0, 1.0)) * 55 + 35).round().clamp(30, 100);
    // 얼굴형: 계란형(0.65~0.85)에 가까울수록 높은 점수
    final shapeScore  = ((1.0 - ((faceRatio - 0.75).abs()  / 0.25).clamp(0.0, 1.0)) * 55 + 35).round().clamp(30, 100);
    // 눈매: 뚜렷한 특징(강한 올라감/내려감) + 적당한 각도 모두 높은 점수
    final eyeAbsScore = (eyeAngle.abs() / 6.0).clamp(0.0, 1.0);
    final eyeIdealScore = (1.0 - ((eyeAngle.abs() - 3.0).abs() / 5.0).clamp(0.0, 1.0));
    final eyeScore    = ((eyeAbsScore * 0.4 + eyeIdealScore * 0.6) * 55 + 38).round().clamp(30, 100);
    // 눈간격: 보통(0.35~0.45) 기준
    final gapScore    = ((1.0 - ((eyeGap - 0.40).abs()     / 0.15).clamp(0.0, 1.0)) * 50 + 38).round().clamp(30, 100);
    // 피부: 실제 차이를 반영한 점수 폭
    final skinScore   = skinRaw == '좋음' ? 88 : skinRaw == '관리필요' ? 50 : 68;

    final total = ((goldenScore + shapeScore + eyeScore + gapScore + skinScore) / 5).round();

    String tier; Color tierColor; String tagline; String topPercent;
    if (total >= 82) {
      tier = 'S'; tierColor = const Color(0xFFFFD700);
      tagline = '당신 혹시... 연예인 아닌가요? 🤔'; topPercent = '상위 5%';
    } else if (total >= 70) {
      tier = 'A'; tierColor = const Color(0xFF27AE60);
      tagline = '이 정도면 충분히 매력적이에요 👍'; topPercent = '상위 20%';
    } else if (total >= 56) {
      tier = 'B'; tierColor = const Color(0xFF4A90D9);
      tagline = '변신 잠재력이 있어요. 지금 시작하면 달라집니다 ✨'; topPercent = '상위 45%';
    } else if (total >= 42) {
      tier = 'C'; tierColor = const Color(0xFFE8A030);
      tagline = 'AI가 변신 플랜 드려요. 관리하면 확실히 달라져요 💪'; topPercent = '평균 이하';
    } else {
      tier = 'D'; tierColor = const Color(0xFFC0392B);
      tagline = '걱정 마세요. 맞춤 플랜으로 바꿔드릴게요 🔥'; topPercent = '개선 여지 많음';
    }

    return (
      total: total,
      tier: tier,
      tierColor: tierColor,
      tagline: tagline,
      topPercent: topPercent,
      stats: [
        ('눈매',   eyeScore),
        ('균형감', goldenScore),
        ('얼굴형', shapeScore),
        ('눈간격', gapScore),
        ('피부',   skinScore),
      ],
    );
  }

  List<String> _pageTitles = ['첫인상', '수치 분석', '변신 플랜'];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String get animalType => widget.animalType;
  double get sliderValue => widget.sliderValue;
  Map<String, dynamic> get analysisResult => widget.analysisResult;
  File get imageFile => widget.imageFile;
  Map<String, dynamic> get faceData => widget.faceData;

  Color _tagColor(String level) {
    if (level == 'hard') return const Color(0xFFC0392B);
    if (level == 'mid') return const Color(0xFFE8A030);
    return const Color(0xFF27AE60);
  }

  Color _tagBg(String level) {
    if (level == 'hard') return const Color(0xFF2A0A0A);
    if (level == 'mid') return const Color(0xFF2A1A00);
    return const Color(0xFF0A1F0A);
  }

  String _tagText(String level, String fallback) {
    if (level == 'hard') return '골격 요인';
    if (level == 'mid') return '관리 필요';
    if (level == 'easy') return '바로 가능';
    return fallback;
  }

  String _shortTitle(String text) {
    return text.length > 15 ? '${text.substring(0, 15)}...' : text;
  }

  static String _animalImgKey(String type) {
    return switch (type) {
      '강아지상' => 'dog',
      '고양이상' => 'cat',
      '곰상'   => 'bear',
      '늑대상' => 'wolf',
      '여우상' => 'fox',
      _       => 'dog',
    };
  }

  static const _faceTypeInfo = {
    '강아지상': (
      emoji: '🐶',
      impression: '친근하고 온화한 인상. 보는 사람을 편안하게 만드는 부드러운 눈매가 특징이에요.',
      features: '내려간 눈꼬리 · 넓은 눈 간격 · 둥근 얼굴형',
    ),
    '고양이상': (
      emoji: '🐱',
      impression: '신비롭고 도도한 인상. 올라간 눈꼬리와 선명한 눈매가 세련된 분위기를 만들어요.',
      features: '올라간 눈꼬리 · 좁은 눈 간격 · 선명한 눈매',
    ),
    '곰상': (
      emoji: '🐻',
      impression: '귀엽고 포근한 인상. 둥근 얼굴형과 부드러운 눈매로 호감도가 높아요.',
      features: '둥근 얼굴형 · 부드러운 눈매 · 작은 눈',
    ),
    '늑대상': (
      emoji: '🐺',
      impression: '강렬하고 카리스마 있는 인상. 갸름한 얼굴과 수평 눈꼬리가 냉철한 분위기를 줘요.',
      features: '갸름한 얼굴 · 수평 눈꼬리 · 강렬한 눈빛',
    ),
    '여우상': (
      emoji: '🦊',
      impression: '섹시하고 영리해 보이는 인상. 강하게 올라간 눈꼬리와 예리한 눈매가 시선을 사로잡아요.',
      features: '많이 올라간 눈꼬리 · 갸름한 얼굴 · 예리한 눈매',
    ),
  };

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) Navigator.pop(context, true);
      },
      child: Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _pages.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : PageView(
                      controller: _pageController,
                      onPageChanged: (i) => setState(() => _currentPage = i),
                      children: _pages,
                    ),
            ),
            _buildPageIndicator(),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('분석 완료',
                  style: TextStyle(fontSize: 10, color: Color(0xFF555555), letterSpacing: 1)),
              const SizedBox(height: 2),
              Text(_pageTitles[_currentPage],
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFFF0F0F0))),
            ],
          ),
          const Spacer(),
          // 페이지 번호
          Text('${_currentPage + 1} / ${_pageTitles.length}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF444444))),
          const SizedBox(width: 14),
          // 공유 버튼
          GestureDetector(
            onTap: _isSharing ? null : _shareResult,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1C),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF2A2A2A), width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isSharing ? Icons.hourglass_empty : Icons.ios_share,
                    size: 13,
                    color: const Color(0xFFE8D5B7),
                  ),
                  const SizedBox(width: 5),
                  const Text('공유',
                      style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFFE8D5B7),
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pageTitles.length, (i) {
              final isActive = i == _currentPage;
              return GestureDetector(
                onTap: () => _pageController.animateToPage(i,
                    duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFFE8D5B7) : const Color(0xFF333333),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          const Text('← 스와이프로 이동 →',
              style: TextStyle(fontSize: 10, color: Color(0xFF333333))),
        ],
      ),
    );
  }

  // Page 1: 첫인상 — 사진 크게 + 동물상 판정 카드 + 인상 헤드라인 + 난이도
  Widget _buildPage1() {
    final r = analysisResult;
    // 신 JSON 우선, 구 JSON 폴백
    final fi = r['first_impression'] as Map<String, dynamic>?;
    final comparison = r['comparison'] as Map<String, dynamic>?;
    final impression = r['current_impression']?.toString()
        ?? fi?['summary']?.toString()
        ?? comparison?['current_animal']?.toString()
        ?? '';
    final gapPercent = (comparison?['gap_percent'] as num?)?.toInt() ?? 50;
    final difficulty = (r['difficulty'] as num?)?.toInt()
        ?? (gapPercent > 60 ? 4 : gapPercent > 30 ? 3 : 2);
    final currentType = faceData['current_face_type']?.toString()
        ?? comparison?['current_animal']?.toString()
        ?? fi?['animal_type']?.toString()
        ?? '';
    final info = _faceTypeInfo[currentType];
    final targetInfo = _faceTypeInfo[animalType];
    final isSameType = currentType == animalType;

    Color diffColor;
    String diffLabel;
    if (difficulty <= 2) { diffColor = const Color(0xFF27AE60); diffLabel = '관리로 달성 가능'; }
    else if (difficulty <= 3) { diffColor = const Color(0xFFE8A030); diffLabel = '꾸준한 노력 필요'; }
    else { diffColor = const Color(0xFFC0392B); diffLabel = '골격적 한계 있음'; }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 분석 사진 — 전체 폭, 오버레이 선이 잘 보이는 높이
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              height: 260,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(imageFile, fit: BoxFit.cover),
                  CustomPaint(painter: FaceOverlayPainter(faceData)),
                  // 현재 동물상 배지 (좌하단)
                  Positioned(
                    bottom: 10, left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(180),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(info?.emoji ?? '', style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(currentType,
                                  style: const TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w700,
                                      color: Color(0xFFE8D5B7))),
                              const Text('AI 판정',
                                  style: TextStyle(fontSize: 9, color: Color(0xFF888877))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (faceData['head_tilt_warning'] == true)
                    Positioned(
                      bottom: 10, right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(180),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.rotate_right, size: 11,
                                color: Color(0xFFE8A030)),
                            const SizedBox(width: 4),
                            Text(
                              faceData['head_warn_type'] == 'yaw'
                                  ? '${faceData['head_yaw']}° 수평 보정됨'
                                  : '${faceData['head_tilt']}° 기울기 보정됨',
                              style: const TextStyle(
                                  fontSize: 9, color: Color(0xFFAA8844)),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          const SizedBox(height: 8),
          // 비교 카드 → Page 2(동물상 매칭)로 이동됨

          // 첫인상 분석 카드 — 현재→목표 중복 표시 제거, 인상 내용에 집중
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1E1E1E), width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('첫인상 분석',
                    style: TextStyle(fontSize: 10, color: Color(0xFF555555), letterSpacing: 0.5)),
                const SizedBox(height: 10),
                Text(impression,
                    style: const TextStyle(
                        fontSize: 15, color: Color(0xFFF0F0F0), fontWeight: FontWeight.w600,
                        height: 1.3)),
                const SizedBox(height: 3),
                Text(
                  r['features']?.toString()
                    ?? (r['first_impression']?['strengths'] as List?)?.join(' · ')
                    ?? (r['comparison']?['current_keywords'] as List?)?.join(' · ')
                    ?? '',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF555555))),
                Builder(builder: (context) {
                  final analysis = r['impression_analysis']?.toString()
                    ?? r['consultant_report_simple']?['direction']?.toString()
                    ?? r['consultant_report_full']?['direction']?.toString()
                    ?? '';
                  if (analysis.isEmpty) return const SizedBox.shrink();
                  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const SizedBox(height: 10),
                    Text('→ $analysis', style: const TextStyle(fontSize: 12, color: Color(0xFFA08040), height: 1.5)),
                  ]);
                }),
                const SizedBox(height: 8),
                Text(
                  r['difficulty_text']?.toString()
                    ?? '목표까지 $gapPercent% 갭',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF666666), height: 1.4)),
              ],
            ),
          ),
          // 능력치 종합 카드
          const SizedBox(height: 12),
          _buildAbilityCard(),
          // 비구독자에게 잠금 힌트
          if (!_isSubscribed) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final ok = await PaywallBottomSheet.show(context);
                if (ok && mounted) {
                  setState(() => _isSubscribed = true);
                  _pageController.animateToPage(1,
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOut);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF141200),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF2A2200), width: 0.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline, size: 16, color: Color(0xFFE8A030)),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('정밀 수치 · 변신 플랜 · 추천 제품 잠금 해제',
                              style: TextStyle(fontSize: 12, color: Color(0xFFE8D5B7),
                                  fontWeight: FontWeight.w600)),
                          SizedBox(height: 2),
                          Text('구독하고 나머지 3페이지를 모두 확인하세요',
                              style: TextStyle(fontSize: 11, color: Color(0xFF888866))),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 16, color: Color(0xFFE8A030)),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Page 2: 수치 분석 — 각 지표 범위 바 + 해석 + 갭 분석
  Widget _buildPage2() {
    final r = analysisResult;
    final gapList = r['gap_analysis'] as List? ?? [];
    final eyeAngle = double.tryParse(faceData['eye_angle']?.toString() ?? '0') ?? 0.0;
    final faceRatio = double.tryParse(faceData['face_ratio']?.toString() ?? '0') ?? 0.0;
    final eyeGapRatio = double.tryParse(faceData['eye_gap_ratio']?.toString() ?? '0') ?? 0.0;
    final goldenRatio = double.tryParse(faceData['golden_ratio']?.toString() ?? '0') ?? 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 눈꼬리 각도
          _buildMetricDetailCard(
            title: '눈꼬리 각도',
            value: '${faceData['eye_angle']}°',
            verdict: faceData['eye_angle_desc']?.toString() ?? '',
            min: -10, max: 10, current: eyeAngle,
            leftLabel: '내려감\n(강아지/곰상)',
            rightLabel: '올라감\n(고양이/여우상)',
            idealMin: -3, idealMax: 3,
            idealLabel: '수평',
            meaning: eyeAngle > 3
                ? '올라간 눈꼬리는 고양이·여우상에 가까운 도도하고 강한 인상을 줍니다.'
                : eyeAngle < -3
                    ? '내려간 눈꼬리는 강아지·곰상에 가까운 온화하고 친근한 인상을 줍니다.'
                    : '수평 눈꼬리는 늑대상에 가까운 냉철하고 중성적인 인상을 줍니다.',
          ),
          const SizedBox(height: 10),

          // 황금비율
          _buildMetricDetailCard(
            title: '황금비율',
            value: faceData['golden_ratio']?.toString() ?? '-',
            verdict: faceData['golden_desc']?.toString() ?? '',
            min: 0.2, max: 0.5, current: goldenRatio,
            leftLabel: '코가\n짧은 편',
            rightLabel: '코가\n긴 편',
            idealMin: 0.28, idealMax: 0.38,
            idealLabel: '이상적',
            meaning: goldenRatio >= 0.28 && goldenRatio <= 0.38
                ? '이마·코·턱 비율이 이상적인 황금비율 범위(0.28~0.38)에 해당합니다.'
                : goldenRatio < 0.28
                    ? '코 영역이 상대적으로 짧아 이상적 비율보다 낮아요. 눈썹 정리로 보완 가능합니다.'
                    : '코 영역이 상대적으로 길어 보이는 편이에요. 헤어·메이크업으로 비율 조정이 가능합니다.',
          ),
          const SizedBox(height: 10),

          // 얼굴형 (다이어그램 포함)
          _buildFaceShapeCard(faceRatio),
          const SizedBox(height: 10),

          // 눈 간격
          _buildMetricDetailCard(
            title: '눈 간격',
            value: faceData['eye_gap_desc']?.toString() ?? '-',
            verdict: '비율 ${faceData['eye_gap_ratio']}',
            min: 0.25, max: 0.55, current: eyeGapRatio,
            leftLabel: '좁음\n(고양이/여우)',
            rightLabel: '넓음\n(강아지/곰)',
            idealMin: 0.35, idealMax: 0.45,
            idealLabel: '보통',
            meaning: eyeGapRatio > 0.45
                ? '넓은 눈 간격은 강아지·곰상에 가까운 친근하고 편안한 인상을 줍니다.'
                : eyeGapRatio < 0.35
                    ? '좁은 눈 간격은 고양이·여우·늑대상에 가까운 날카롭고 세련된 인상을 줍니다.'
                    : '균형 잡힌 눈 간격으로 다양한 인상을 소화할 수 있어요.',
          ),
          const SizedBox(height: 10),
          _buildSymmetryCard(),
          const SizedBox(height: 10),
          _buildSkinAnalysisCard(),
          const SizedBox(height: 20),

          // 갭 분석
          const Text('추구미 갭 분석',
              style: TextStyle(fontSize: 11, color: Color(0xFF555555), letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text('${animalType}까지의 항목별 거리',
              style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
          const SizedBox(height: 10),
          ...gapList.map((gap) {
            final level = gap['level']?.toString() ?? '';
            final tagColor = _tagColor(level);
            final tagBg = _tagBg(level);
            final tagText = _tagText(level, gap['tag']?.toString() ?? '');
            final score = (gap['score'] as num?)?.toDouble() ?? 0.0;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF161616),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 72,
                    child: Text(gap['item']?.toString() ?? '',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: score,
                        backgroundColor: const Color(0xFF2A2A2A),
                        valueColor: AlwaysStoppedAnimation<Color>(tagColor),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(color: tagBg, borderRadius: BorderRadius.circular(6)),
                    child: Text(tagText,
                        textAlign: TextAlign.center, maxLines: 2,
                        style: TextStyle(fontSize: 10, color: tagColor)),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAbilityCard() {
    final s = _abilityScores;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: s.tierColor.withAlpha(60), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목 + 기준 설명
          Row(
            children: [
              const Text('얼굴 균형 점수',
                  style: TextStyle(fontSize: 12, color: Color(0xFF888888))),
              const SizedBox(width: 6),
              const Expanded(
                child: Text('황금비율 · 눈매 · 얼굴형 · 눈간격 · 피부 5가지 AI 채점',
                    style: TextStyle(fontSize: 9, color: Color(0xFF444444))),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 총점 + 등급
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('얼굴 균형 점수',
                      style: TextStyle(fontSize: 10, color: Color(0xFF555555), letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('${s.total}',
                          style: TextStyle(
                              fontSize: 32, fontWeight: FontWeight.w900,
                              color: s.tierColor, height: 1.0)),
                      const Text(' / 100',
                          style: TextStyle(fontSize: 13, color: Color(0xFF555555))),
                    ],
                  ),
                  Text(s.topPercent,
                      style: TextStyle(fontSize: 11, color: s.tierColor.withAlpha(180))),
                ],
              ),
              const Spacer(),
              // 등급 원형 배지
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: s.tierColor.withAlpha(20),
                  shape: BoxShape.circle,
                  border: Border.all(color: s.tierColor, width: 2),
                ),
                child: Center(
                  child: Text(s.tier,
                      style: TextStyle(
                          fontSize: 26, fontWeight: FontWeight.w900, color: s.tierColor)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(s.tagline,
              style: TextStyle(fontSize: 11, color: s.tierColor.withAlpha(180), height: 1.4)),
          const SizedBox(height: 14),
          Container(height: 0.5, color: const Color(0xFF1E1E1E)),
          const SizedBox(height: 12),
          // 능력치 바 5개
          ...s.stats.map((stat) {
            final pct = stat.$2 / 100.0;
            final barColor = stat.$2 >= 80
                ? const Color(0xFF27AE60)
                : stat.$2 >= 65
                    ? const Color(0xFF4A90D9)
                    : const Color(0xFFE8A030);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 42,
                    child: Text(stat.$1,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF777777))),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: const Color(0xFF1E1E1E),
                        valueColor: AlwaysStoppedAnimation<Color>(barColor),
                        minHeight: 7,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 28,
                    child: Text('${stat.$2}',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700, color: barColor)),
                  ),
                ],
              ),
            );
          }),
          // 비구독자: 변신 플랜 점수 개선 가능성 → 페이월 연결
          if (!_isSubscribed) ...[
            Container(height: 0.5, color: const Color(0xFF1E1E1E)),
            const SizedBox(height: 12),
            Builder(builder: (context) {
              final gapList = analysisResult['gap_analysis'] as List? ?? [];
              final improvable = gapList
                  .where((g) => g['level']?.toString() != '골격 요인')
                  .length;
              final gain = (improvable * 3 + 4).clamp(6, 20);
              return GestureDetector(
                onTap: () async {
                  final ok = await PaywallBottomSheet.show(context);
                  if (ok && mounted) {
                    setState(() => _isSubscribed = true);
                    _pageController.animateToPage(2,
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOut);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1200),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE8A030).withAlpha(80), width: 0.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.trending_up, size: 15, color: Color(0xFFE8A030)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '변신 플랜 실천 시 최대 +$gain점 개선 가능',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFFE8D5B7),
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Text('잠금 해제 →',
                          style: TextStyle(fontSize: 11, color: Color(0xFFE8A030))),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // 얼굴형 시각 카드
  Widget _buildFaceShapeCard(double faceRatio) {
    final shape = faceData['face_shape']?.toString() ?? '-';
    final inIdeal = faceRatio >= 0.65 && faceRatio <= 0.85;
    final dotColor = inIdeal ? const Color(0xFF27AE60) : const Color(0xFFE8A030);
    final meaning = faceRatio > 0.85
        ? '둥근 얼굴형으로 강아지·곰상에 가까워요. 긴 헤어스타일로 갸름해 보이게 할 수 있어요.'
        : faceRatio < 0.65
            ? '갸름한 얼굴형으로 늑대·여우·고양이상에 가까워요. 볼륨 있는 헤어가 잘 어울려요.'
            : '균형 잡힌 계란형 얼굴로 대부분의 헤어스타일과 잘 어울립니다.';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E1E1E), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('얼굴형', style: TextStyle(fontSize: 12, color: Color(0xFF888888))),
              const Spacer(),
              Text(shape, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: dotColor)),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text('비율 ${faceData['face_ratio']}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF666666))),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 얼굴형 다이어그램 3종
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _faceShapeIcon('갸름형', 0.58, faceRatio < 0.65),
              _faceShapeIcon('계란형', 0.74, faceRatio >= 0.65 && faceRatio <= 0.85),
              _faceShapeIcon('둥근형', 0.92, faceRatio > 0.85),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: dotColor.withAlpha(15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: dotColor.withAlpha(40), width: 0.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(inIdeal ? Icons.check_circle_outline : Icons.info_outline,
                    size: 13, color: dotColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(meaning,
                      style: TextStyle(fontSize: 11, color: dotColor.withAlpha(200), height: 1.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _faceShapeIcon(String label, double faceRatio, bool isActive) {
    // faceRatio = 얼굴폭/얼굴길이 → 타원: 높이 고정, 너비 = 높이 × faceRatio
    const ovalH = 40.0;
    final ovalW = ovalH * faceRatio;
    return Column(
      children: [
        Container(
          width: 52, height: 58,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF1E1900) : const Color(0xFF141414),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? const Color(0xFFE8A030) : const Color(0xFF222222),
              width: isActive ? 1.5 : 0.5,
            ),
          ),
          child: Center(
            child: Container(
              width: ovalW,
              height: ovalH,
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFFE8A030).withAlpha(40)
                    : const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.all(Radius.elliptical(ovalW / 2, ovalH / 2)),
                border: Border.all(
                  color: isActive ? const Color(0xFFE8A030) : const Color(0xFF444444),
                  width: 1.2,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontSize: 9,
                color: isActive ? const Color(0xFFE8A030) : const Color(0xFF444444))),
      ],
    );
  }

  // 수치 상세 카드 — 범위 바 + 이상 구간 + 해석
  Widget _buildMetricDetailCard({
    required String title,
    required String value,
    required String verdict,
    required double min, required double max, required double current,
    required String leftLabel, required String rightLabel,
    required double idealMin, required double idealMax,
    required String idealLabel,
    required String meaning,
  }) {
    final pct = ((current - min) / (max - min)).clamp(0.0, 1.0);
    final idealStartPct = ((idealMin - min) / (max - min)).clamp(0.0, 1.0);
    final idealEndPct = ((idealMax - min) / (max - min)).clamp(0.0, 1.0);
    final inIdeal = current >= idealMin && current <= idealMax;
    final dotColor = inIdeal ? const Color(0xFF27AE60) : const Color(0xFFE8A030);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E1E1E), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목 + 수치
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(title,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
              const Spacer(),
              Text(value,
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800, color: dotColor)),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(verdict,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF666666))),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 범위 바
          LayoutBuilder(builder: (context, constraints) {
            final w = constraints.maxWidth;
            return Column(
              children: [
                SizedBox(
                  height: 20,
                  child: Stack(
                    children: [
                      // 트랙
                      Positioned(
                        top: 7, left: 0, right: 0,
                        child: Container(height: 6, decoration: BoxDecoration(
                          color: const Color(0xFF222222),
                          borderRadius: BorderRadius.circular(3),
                        )),
                      ),
                      // 이상 구간 하이라이트
                      Positioned(
                        top: 7,
                        left: w * idealStartPct,
                        width: w * (idealEndPct - idealStartPct),
                        child: Container(height: 6, decoration: BoxDecoration(
                          color: const Color(0xFF27AE60).withAlpha(60),
                          borderRadius: BorderRadius.circular(3),
                        )),
                      ),
                      // 현재 위치 도트 ("나" 라벨로 내 수치임을 명시)
                      Positioned(
                        top: 0,
                        left: (w * pct - 10).clamp(0.0, w - 20),
                        child: Container(
                          width: 20, height: 20,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: dotColor.withAlpha(100), blurRadius: 6)],
                          ),
                          child: Center(
                            child: Text('나',
                                style: TextStyle(
                                    fontSize: 7,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black.withAlpha(160))),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // "이상적" 라벨을 실제 이상 구간 중앙에 정렬 (bar 정중앙이 아님)
                SizedBox(
                  height: 18,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(leftLabel, textAlign: TextAlign.left,
                            style: const TextStyle(
                                fontSize: 9, color: Color(0xFF444444), height: 1.3)),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(rightLabel, textAlign: TextAlign.right,
                            style: const TextStyle(
                                fontSize: 9, color: Color(0xFF444444), height: 1.3)),
                      ),
                      Positioned(
                        left: (w * (idealStartPct + idealEndPct) / 2 - 22)
                            .clamp(0.0, w - 44),
                        top: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF27AE60).withAlpha(30),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(idealLabel,
                              style: const TextStyle(
                                  fontSize: 9, color: Color(0xFF27AE60))),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 12),

          // 해석
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: dotColor.withAlpha(15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: dotColor.withAlpha(40), width: 0.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(inIdeal ? Icons.check_circle_outline : Icons.info_outline,
                    size: 13, color: dotColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(meaning,
                      style: TextStyle(fontSize: 11, color: dotColor.withAlpha(200), height: 1.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Page 3: 액션 플랜 — 피드백 + 커리큘럼 탭
  Widget _buildPage3() {
    final r = analysisResult;
    final curriculum = r['curriculum'] as Map<String, dynamic>?;

    final tabs = [
      (key: 'hair',      label: '헤어',   icon: Icons.content_cut),
      (key: 'skin',      label: '피부',   icon: Icons.spa_outlined),
      (key: 'grooming',  label: '그루밍', icon: Icons.face_retouching_natural),
      (key: 'procedure', label: '시술',   icon: Icons.medical_services_outlined),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 현실 피드백
          if ((r['realistic_feedback'] ?? r['consultant_report_simple']?['quote'] ?? r['consultant_report_full']?['quote']) != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1E1E1E), width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.analytics_outlined, size: 14, color: Color(0xFFE8A030)),
                      SizedBox(width: 6),
                      Text('AI 현실 진단',
                          style: TextStyle(fontSize: 12, color: Color(0xFFE8A030),
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    (r['realistic_feedback'] ?? r['consultant_report_simple']?['quote'] ?? r['consultant_report_full']?['quote'] ?? '').toString(),
                    style: const TextStyle(fontSize: 13, color: Color(0xFFAAAAAA), height: 1.6)),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],


          // 변신 액션 플랜
          Builder(builder: (context) {
            final diagnosis = r['diagnosis'] as String?;
            final targetDesc = r['target_description'] as String?;
            final actionPlan = (r['action_plan'] as List?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList();
            final expectedEffect = r['expected_effect'] as String?;

            if (actionPlan != null && actionPlan.isNotEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (diagnosis != null) ...[
                    _buildInfoCard('현재 상태 진단', diagnosis),
                    const SizedBox(height: 10),
                  ],
                  if (targetDesc != null) ...[
                    _buildInfoCard('목표 이미지', targetDesc),
                    const SizedBox(height: 16),
                  ],
                  const Text('변신 액션 플랜',
                      style: TextStyle(fontSize: 14, color: Color(0xFFE8D5B7), fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  ...actionPlan.map(_buildActionCard),
                  if (expectedEffect != null) ...[
                    const SizedBox(height: 4),
                    _buildInfoCard('예상 효과', expectedEffect),
                  ],
                  const SizedBox(height: 20),
                ],
              );
            }

            // 폴백: 기존 curriculum 렌더링
            if (curriculum == null) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('맞춤 액션 플랜',
                    style: TextStyle(fontSize: 14, color: Color(0xFFE8D5B7), fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                ...tabs.asMap().entries.map((e) {
                  final data = curriculum[e.value.key];
                  if (data == null) return const SizedBox.shrink();
                  return _buildBeforeAfterCard(icon: e.value.icon, data: data as Map<String, dynamic>);
                }),
                const SizedBox(height: 20),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActionCard(Map<String, dynamic> plan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E1E1E), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            plan['category'] ?? '',
            style: const TextStyle(
              color: Color(0xFFE8A030),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            plan['current_problem'] ?? '',
            style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13, height: 1.6),
          ),
          const SizedBox(height: 6),
          Text(
            plan['recommendation'] ?? '',
            style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 13, height: 1.6),
          ),
          const SizedBox(height: 6),
          Text(
            plan['examples'] ?? '',
            style: const TextStyle(color: Color(0xFF888888), fontSize: 12, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E1E1E), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFE8D5B7),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13, height: 1.6),
          ),
        ],
      ),
    );
  }

  // Page 4: 추천 제품
  Widget _buildPage4() {
    final products = analysisResult['product_recommendations'] as List?;
    final categoryIcons = {
      '스킨케어': Icons.spa_outlined,
      '헤어': Icons.content_cut,
      '그루밍': Icons.face_retouching_natural,
    };
    final categoryColors = {
      '스킨케어': const Color(0xFF27AE60),
      '헤어': const Color(0xFF4A90D9),
      '그루밍': const Color(0xFFE8A030),
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('맞춤 제품 추천',
              style: TextStyle(fontSize: 14, color: Color(0xFFE8D5B7), fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('분석 결과 기반 실제 도움이 되는 성분과 제품 유형',
              style: TextStyle(fontSize: 11, color: Color(0xFF555555))),
          const SizedBox(height: 16),

          if (products == null || products.isEmpty)
            const Center(
              child: Text('추천 제품 정보가 없어요.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF444444))),
            )
          else
            ...products.map((cat) {
              final category = cat['category']?.toString() ?? '';
              final reason = cat['reason']?.toString() ?? '';
              final items = cat['items'] as List? ?? [];
              final icon = categoryIcons[category] ?? Icons.shopping_bag_outlined;
              final catColor = categoryColors[category] ?? const Color(0xFF888888);

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF1E1E1E), width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 카테고리 헤더
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                      decoration: BoxDecoration(
                        color: catColor.withAlpha(15),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                        border: Border(bottom: BorderSide(color: catColor.withAlpha(30), width: 0.5)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: catColor.withAlpha(30),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(icon, size: 16, color: catColor),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(category,
                                    style: TextStyle(
                                        fontSize: 13, fontWeight: FontWeight.w700, color: catColor)),
                                if (reason.isNotEmpty)
                                  Text(reason,
                                      style: const TextStyle(fontSize: 10, color: Color(0xFF777777))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 제품 목록
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: items.asMap().entries.map((entry) {
                          final i = entry.key;
                          final item = entry.value;
                          final priority = item['priority']?.toString() ?? 'mid';
                          final isHigh = priority == 'high';
                          return Container(
                            margin: EdgeInsets.only(bottom: i < items.length - 1 ? 10 : 0),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isHigh
                                  ? const Color(0xFF1A1500)
                                  : const Color(0xFF171717),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isHigh
                                    ? const Color(0xFF2A2000)
                                    : const Color(0xFF222222),
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(item['name']?.toString() ?? '',
                                                style: const TextStyle(
                                                    fontSize: 13, color: Color(0xFFDDDDDD),
                                                    fontWeight: FontWeight.w500)),
                                          ),
                                          if (isHigh)
                                            Container(
                                              margin: const EdgeInsets.only(left: 6),
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE8A030).withAlpha(30),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(
                                                    color: const Color(0xFFE8A030).withAlpha(60),
                                                    width: 0.5),
                                              ),
                                              child: const Text('우선',
                                                  style: TextStyle(
                                                      fontSize: 9, color: Color(0xFFE8A030))),
                                            ),
                                        ],
                                      ),
                                      if (item['key_ingredient'] != null) ...[
                                        const SizedBox(height: 3),
                                        Text('핵심 성분: ${item['key_ingredient']}',
                                            style: const TextStyle(
                                                fontSize: 11, color: Color(0xFF666666))),
                                      ],
                                    ],
                                  ),
                                ),
                                if (item['price_range'] != null) ...[
                                  const SizedBox(width: 8),
                                  Text(item['price_range'].toString(),
                                      style: const TextStyle(
                                          fontSize: 11, color: Color(0xFF555555))),
                                ],
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    final query = Uri.encodeComponent(
                                        '${item['name'] ?? ''} $category');
                                    launchUrl(
                                      Uri.parse(
                                          'https://search.shopping.naver.com/search/all?query=$query'),
                                      mode: LaunchMode.externalApplication,
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0A1A0A),
                                      borderRadius: BorderRadius.circular(7),
                                      border: Border.all(
                                          color: const Color(0xFF1A3A1A),
                                          width: 0.5),
                                    ),
                                    child: const Text('찾기',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: Color(0xFF4A9A4A))),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 16),
          // 재분석 CTA — 결과 마지막 전환 유도
          GestureDetector(
            onTap: () => Navigator.pop(context, true),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF141200),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2A2200), width: 0.5),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh_rounded, size: 16, color: Color(0xFFE8A030)),
                  SizedBox(width: 8),
                  Text('새로운 사진으로 다시 분석하기',
                      style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFFE8D5B7),
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F0F),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1A1A1A), width: 0.5),
            ),
            child: const Text(
              '⚠️ 본 분석은 AI 기반 스타일 가이드로, 의학적 진단이 아닙니다. 참고용으로만 활용하세요.',
              style: TextStyle(fontSize: 10, color: Color(0xFF444444), height: 1.5),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _shareResult() async {
    setState(() => _isSharing = true);
    try {
      final Uint8List image = await _screenshotController.captureFromWidget(
        _buildShareCard(),
        pixelRatio: 3.0,
        context: context,
      );

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/apex_aura_result.png');
      await file.writeAsBytes(image);

      final s = _abilityScores;
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '나는 ${s.tier}등급 ${faceData['current_face_type'] ?? animalType}! (${s.total}/100점)\n'
              '${s.tagline}\n\n'
              '내 얼굴 AI 분석하기 👇\n'
              'https://play.google.com/store/apps/details?id=com.vacman.apex_aura',
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  // 긴 이미지 저장 — 현재 페이지 캡처 후 갤러리 저장
  Future<void> _saveLongImage() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      final boundary = _shareKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        // shareKey 없으면 현재 페이지 전체를 screenshot으로 캡처
        final image = await _screenshotController.captureFromWidget(
          _buildShareCard(), pixelRatio: 3.0, context: context);
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/apex_aura_long.png');
        await file.writeAsBytes(image);
        await Gal.putImage(file.path, album: 'Apex Aura');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('갤러리에 저장됐어요'), duration: Duration(seconds: 2)));
        }
        return;
      }
      final img = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await img.toByteData(format: dart_ui.ImageByteFormat.png);
      if (byteData == null) return;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/apex_aura_long.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());
      await Gal.putImage(file.path, album: 'Apex Aura');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('갤러리에 저장됐어요'), duration: Duration(seconds: 2)));
      }
    } catch (e) {
      debugPrint('saveLongImage error: $e');
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Widget _buildCurrentFaceTypeCard() {
    final currentType = faceData['current_face_type']?.toString();
    final info = currentType != null ? _faceTypeInfo[currentType] : null;
    if (info == null) return const SizedBox.shrink();

    // 분류 근거 수치
    final eyeAngle = faceData['eye_angle']?.toString() ?? '-';
    final eyeAngleDesc = faceData['eye_angle_desc']?.toString() ?? '';
    final faceShape = faceData['face_shape']?.toString() ?? '-';
    final eyeGapDesc = faceData['eye_gap_desc']?.toString() ?? '-';
    final selectedTarget = animalType;
    final isSameAsTarget = currentType == selectedTarget;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141200),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2200), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: 선택 vs 실제
          Row(
            children: [
              if (!isSameAsTarget) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A00),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF333300), width: 0.5),
                  ),
                  child: Text('추구미 $selectedTarget',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF888855))),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.arrow_forward, size: 11, color: Color(0xFF444433)),
                ),
              ],
              Text(info.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text('실제 분류: $currentType',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFE8D5B7))),
              const Spacer(),
              const Text('AI 수치 판정',
                  style: TextStyle(fontSize: 9, color: Color(0xFF555544))),
            ],
          ),
          const SizedBox(height: 8),

          // 분류 근거 수치 (왜 이 동물상인지)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0D0C00),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF222200), width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('분류 근거',
                    style: TextStyle(fontSize: 9, color: Color(0xFF555544), letterSpacing: 0.5)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _evidenceChip('눈꼬리', '$eyeAngle° $eyeAngleDesc'),
                    const SizedBox(width: 6),
                    _evidenceChip('얼굴형', faceShape),
                    const SizedBox(width: 6),
                    _evidenceChip('눈간격', eyeGapDesc),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 5종 점수 바
          _buildFaceTypeScoreBars(),
          const SizedBox(height: 8),

          // 인상 설명
          Text(info.impression,
              style: const TextStyle(fontSize: 11, color: Color(0xFF999988), height: 1.5)),

          // 추구미와 다를 경우 갭 설명
          if (!isSameAsTarget) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1500),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF2A2200), width: 0.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 12, color: Color(0xFFE8A030)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '현재 $currentType → 목표 $selectedTarget. 아래 분석에서 갭과 달성 방법을 확인하세요.',
                      style: const TextStyle(fontSize: 11, color: Color(0xFFA08040), height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFaceTypeScoreBars() {
    final rawScores = faceData['face_type_scores'];
    if (rawScores == null) return const SizedBox.shrink();

    final scores = <String, int>{};
    (rawScores as Map).forEach((k, v) {
      scores[k.toString()] = (v as num).toInt();
    });
    if (scores.isEmpty) return const SizedBox.shrink();

    final currentType = faceData['current_face_type']?.toString() ?? '';
    final secondType = faceData['face_type_second']?.toString();
    final isBorderline = faceData['face_type_is_borderline'] == true;

    final order = ['강아지상', '고양이상', '곰상', '늑대상', '여우상'];
    final emojis = {'강아지상': '🐶', '고양이상': '🐱', '곰상': '🐻', '늑대상': '🐺', '여우상': '🦊'};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('동물상 분포',
                style: TextStyle(fontSize: 9, color: Color(0xFF555544), letterSpacing: 0.5)),
            if (isBorderline && secondType != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8A030).withAlpha(30),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFE8A030).withAlpha(60), width: 0.5),
                ),
                child: Text('$currentType / $secondType 경계',
                    style: const TextStyle(fontSize: 8, color: Color(0xFFE8A030))),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        ...order.map((type) {
          final score = scores[type] ?? 0;
          final isMain = type == currentType;
          final isSecond = type == secondType && isBorderline;
          final barColor = isMain
              ? const Color(0xFFE8D5B7)
              : isSecond
                  ? const Color(0xFFE8A030).withAlpha(160)
                  : const Color(0xFF2A2A2A);
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(emojis[type] ?? '',
                      style: const TextStyle(fontSize: 11)),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: score / 100.0,
                      backgroundColor: const Color(0xFF1A1A1A),
                      valueColor: AlwaysStoppedAnimation<Color>(barColor),
                      minHeight: 5,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 28,
                  child: Text('$score%',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 9,
                          color: isMain ? const Color(0xFFE8D5B7) : const Color(0xFF444444))),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _evidenceChip(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1900),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF2A2200), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 8, color: Color(0xFF666644))),
            Text(value,
                style: const TextStyle(fontSize: 10, color: Color(0xFFBBAA77),
                    fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentFaceTypeCardOLD() {
    final currentType = faceData['current_face_type']?.toString();
    final info = currentType != null ? _faceTypeInfo[currentType] : null;
    if (info == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(info.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('현재 $currentType',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFE8D5B7))),
                  ],
                ),
                const SizedBox(height: 4),
                Text(info.impression, style: const TextStyle(fontSize: 11, color: Color(0xFF999988), height: 1.5)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 5,
                  runSpacing: 4,
                  children: info.features.split(' · ').map((f) =>
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFF1E1900), borderRadius: BorderRadius.circular(5)),
                      child: Text(f, style: const TextStyle(fontSize: 9, color: Color(0xFF777755))),
                    )
                  ).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareCard() {
    final s = _abilityScores;
    final currentType = faceData['current_face_type']?.toString() ?? '';
    final info = _faceTypeInfo[currentType];
    final impression = analysisResult['current_impression']?.toString() ?? '';
    final tier = s.tier;
    final tierColor = s.tierColor;
    final tierBg = s.tagline;
    final tagline = s.topPercent;
    final totalScore = s.total;
    final stats = s.stats;

    return Container(
      width: 380,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border.all(color: const Color(0xFF1A1A1A), width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더 배너
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
            decoration: const BoxDecoration(
              color: Color(0xFF111100),
              border: Border(bottom: BorderSide(color: Color(0xFF222200), width: 0.5)),
            ),
            child: Row(
              children: [
                const Text('APEX AURA',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w800,
                        color: Color(0xFFE8D5B7), letterSpacing: 3)),
                const Spacer(),
                const Text('얼굴 균형 분석',
                    style: TextStyle(fontSize: 10, color: Color(0xFF666644), letterSpacing: 1)),
              ],
            ),
          ),

          // 사진 + 동물상 오버레이
          Stack(
            children: [
              SizedBox(
                height: 220,
                width: double.infinity,
                child: Image.file(imageFile, fit: BoxFit.cover),
              ),
              // 그라디언트 오버레이
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withAlpha(180),
                      ],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),
              ),
              // 동물상 + 인상
              Positioned(
                bottom: 14, left: 16, right: 16,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 동물상 이미지 썸네일
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/images/${_animalImgKey(currentType)}_${widget.gender}.png',
                            width: 44, height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Text(info?.emoji ?? '', style: const TextStyle(fontSize: 28)),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(currentType,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w900,
                                color: Colors.white, height: 1.1)),
                        Text(impression,
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFFCCCCCC))),
                      ],
                    ),
                    const Spacer(),
                    // 등급 뱃지
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(180),
                        shape: BoxShape.circle,
                        border: Border.all(color: tierColor, width: 2),
                      ),
                      child: Center(
                        child: Text(tier,
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.w900,
                                color: tierColor)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 총점 + 태그라인
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
            decoration: BoxDecoration(
              color: tierColor.withAlpha(15),
              border: Border(
                bottom: BorderSide(color: tierColor.withAlpha(30), width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('$totalScore',
                            style: TextStyle(
                                fontSize: 32, fontWeight: FontWeight.w900,
                                color: tierColor, height: 1.0)),
                        const Text(' / 100',
                            style: TextStyle(
                                fontSize: 14, color: Color(0xFF555555))),
                      ],
                    ),
                    Text(tagline,
                        style: TextStyle(fontSize: 11, color: tierColor.withAlpha(180))),
                  ],
                ),
                const Spacer(),
                Expanded(
                  child: Text(tierBg,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF999988), height: 1.4)),
                ),
              ],
            ),
          ),

          // 능력치 바
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
            child: Column(
              children: stats.map((s) {
                final pct = s.$2 / 100.0;
                final barColor = s.$2 >= 80
                    ? const Color(0xFF27AE60)
                    : s.$2 >= 65
                        ? const Color(0xFF4A90D9)
                        : const Color(0xFFE8A030);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 46,
                        child: Text(s.$1,
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF888888))),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: pct,
                            backgroundColor: const Color(0xFF1E1E1E),
                            valueColor: AlwaysStoppedAnimation<Color>(barColor),
                            minHeight: 7,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 28,
                        child: Text('${s.$2}',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700,
                                color: barColor)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // ML Kit 정밀 수치 섹션 (분석 전문성 표시)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
            decoration: const BoxDecoration(
              color: Color(0xFF0D0D00),
              border: Border(
                top: BorderSide(color: Color(0xFF1A1A00), width: 0.5),
                bottom: BorderSide(color: Color(0xFF1A1A00), width: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.biotech, size: 11, color: Color(0xFF888855)),
                    SizedBox(width: 5),
                    Text('AI 정밀 측정 수치',
                        style: TextStyle(fontSize: 9, color: Color(0xFF888855),
                            letterSpacing: 1, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _shareMeasure('눈꼬리', '${faceData['eye_angle']}°', faceData['eye_angle_desc']?.toString() ?? ''),
                    _shareMeasure('황금비율', faceData['golden_ratio']?.toString() ?? '-', faceData['golden_desc']?.toString()?.replaceAll('황금비율에 ', '') ?? ''),
                    _shareMeasure('얼굴형', faceData['face_shape']?.toString() ?? '-', '비율 ${faceData['face_ratio']}'),
                    _shareMeasure('눈간격', faceData['eye_gap_desc']?.toString() ?? '-', '${faceData['eye_gap_ratio']}'),
                  ],
                ),
              ],
            ),
          ),

          // 푸터 CTA
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            decoration: const BoxDecoration(
              color: Color(0xFF111111),
              border: Border(top: BorderSide(color: Color(0xFF1A1A1A), width: 0.5)),
            ),
            child: Row(
              children: [
                const Text('나도 해보기 → APEX AURA',
                    style: TextStyle(
                        fontSize: 10, color: Color(0xFF555544), letterSpacing: 0.5)),
                const Spacer(),
                Text(DateTime.now().toString().substring(0, 10),
                    style: const TextStyle(fontSize: 10, color: Color(0xFF333333))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _shareDivider() {
    return Container(width: 0.5, height: 36, color: const Color(0xFF1E1E1E));
  }

  Widget _shareMeasure(String label, String value, String sub) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF888866), letterSpacing: 0.3)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFFE8D5B7))),
          if (sub.isNotEmpty)
            Text(sub, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 9, color: Color(0xFF666644)),
                maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildYoutubeRecommendations() {
    final videos = analysisResult['youtube_recommendations'] as List?;
    if (videos == null || videos.isEmpty) return const SizedBox.shrink();

    final categoryColors = {
      '헤어': const Color(0xFF4A90D9),
      '피부': const Color(0xFF27AE60),
      '그루밍': const Color(0xFFE8A030),
      '추구미': const Color(0xFFC0392B),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text("유튜브 추천",
            style: TextStyle(
                fontSize: 15,
                color: Color(0xFFE8D5B7),
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        ...videos.map((v) {
          final title = v['title']?.toString() ?? '';
          final query = v['query']?.toString() ?? '';
          final category = v['category']?.toString() ?? '';
          final categoryColor =
              categoryColors[category] ?? const Color(0xFF555555);

          return GestureDetector(
            onTap: () => launchUrl(
              Uri.parse(
                  'https://www.youtube.com/results?search_query=${Uri.encodeComponent(query)}'),
              mode: LaunchMode.externalApplication,
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1C),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2A2A2A), width: 0.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.play_circle_outline,
                      color: Color(0xFFE8A030), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFFCCCCCC))),
                        const SizedBox(height: 2),
                        Text(query,
                            style: const TextStyle(
                                fontSize: 10, color: Color(0xFF555555))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: categoryColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(category,
                        style: TextStyle(
                            fontSize: 10, color: categoryColor)),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildProductRecommendations() {
    final products = analysisResult['product_recommendations'] as List?;
    if (products == null || products.isEmpty) return const SizedBox.shrink();

    final categoryIcons = {
      '스킨케어': Icons.spa_outlined,
      '헤어': Icons.content_cut,
      '그루밍': Icons.face_retouching_natural,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text("추천 제품",
            style: TextStyle(
                fontSize: 15,
                color: Color(0xFFE8D5B7),
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        ...products.map((cat) {
          final category = cat['category']?.toString() ?? '';
          final reason = cat['reason']?.toString() ?? '';
          final items = cat['items'] as List? ?? [];
          final icon = categoryIcons[category] ?? Icons.shopping_bag_outlined;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1C),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2A2A2A), width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                          color: const Color(0xFF2A2000),
                          borderRadius: BorderRadius.circular(8)),
                      child: Icon(icon, size: 15, color: const Color(0xFFE8D5B7)),
                    ),
                    const SizedBox(width: 8),
                    Text(category,
                        style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFFE8D5B7),
                            fontWeight: FontWeight.w500)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(reason,
                          style: const TextStyle(
                              fontSize: 10, color: Color(0xFF555555))),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...items.map((item) {
                  final priority = item['priority']?.toString() ?? 'mid';
                  final priorityColor = priority == 'high'
                      ? const Color(0xFFE8A030)
                      : const Color(0xFF555555);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 3),
                          width: 6, height: 6,
                          decoration: BoxDecoration(
                              color: priorityColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                        item['name']?.toString() ?? '',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFFCCCCCC))),
                                  ),
                                  Text(
                                      item['price_range']?.toString() ?? '',
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF666666))),
                                ],
                              ),
                              if (item['key_ingredient'] != null)
                                Text(
                                    item['key_ingredient'].toString(),
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF555555))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        }),
      ],
    );
  }

  // 커리큘럼 항목 아이콘/색상 설정
  ({IconData icon, Color color, Color bg}) _curriculumItemConfig(String label) {
    return switch (label) {
      '현재 문제' || '문제점' => (
          icon: Icons.warning_amber_outlined,
          color: const Color(0xFFC0392B),
          bg: const Color(0xFF2A0A0A)),
      '추천 컷' => (
          icon: Icons.content_cut,
          color: const Color(0xFF4A90D9),
          bg: const Color(0xFF0A1520)),
      '스타일링' => (
          icon: Icons.auto_awesome,
          color: const Color(0xFF9B59B6),
          bg: const Color(0xFF1A0A2A)),
      '추천 성분' || '핵심 성분' => (
          icon: Icons.science_outlined,
          color: const Color(0xFF27AE60),
          bg: const Color(0xFF0A1F0A)),
      '피부과 시술' => (
          icon: Icons.medical_services_outlined,
          color: const Color(0xFFE8A030),
          bg: const Color(0xFF2A1A00)),
      '눈썹' => (
          icon: Icons.face,
          color: const Color(0xFF888888),
          bg: const Color(0xFF1A1A1A)),
      '수염' => (
          icon: Icons.face_retouching_natural,
          color: const Color(0xFF888888),
          bg: const Color(0xFF1A1A1A)),
      '비침습' => (
          icon: Icons.bubble_chart_outlined,
          color: const Color(0xFF27AE60),
          bg: const Color(0xFF0A1F0A)),
      '최소침습' => (
          icon: Icons.healing_outlined,
          color: const Color(0xFFE8A030),
          bg: const Color(0xFF2A1A00)),
      '수술적' => (
          icon: Icons.local_hospital_outlined,
          color: const Color(0xFFC0392B),
          bg: const Color(0xFF2A0A0A)),
      '우선순위' => (
          icon: Icons.sort,
          color: const Color(0xFFE8D5B7),
          bg: const Color(0xFF2A2000)),
      _ => (
          icon: Icons.chevron_right,
          color: const Color(0xFF666666),
          bg: const Color(0xFF1A1A1A)),
    };
  }

  Widget _buildSymmetryCard() {
    final score = (faceData['symmetry_score'] as num?)?.toInt() ?? 80;
    final Color scoreColor;
    final String scoreLabel;
    if (score >= 90) { scoreColor = const Color(0xFF27AE60); scoreLabel = '매우 대칭적'; }
    else if (score >= 80) { scoreColor = const Color(0xFF4A90D9); scoreLabel = '균형 잡힌 편'; }
    else if (score >= 70) { scoreColor = const Color(0xFFE8A030); scoreLabel = '약간 비대칭'; }
    else { scoreColor = const Color(0xFFCC5555); scoreLabel = '비대칭 있음'; }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E1E1E), width: 0.5),
      ),
      child: Row(
        children: [
          // 대칭 점수 원형 표시
          SizedBox(
            width: 60, height: 60,
            child: Stack(
              children: [
                SizedBox(
                  width: 60, height: 60,
                  child: CircularProgressIndicator(
                    value: score / 100.0,
                    backgroundColor: const Color(0xFF222222),
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                    strokeWidth: 5,
                  ),
                ),
                Center(
                  child: Text('$score',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: scoreColor)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('좌우 대칭도',
                        style: TextStyle(fontSize: 12, color: Color(0xFF888888))),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: scoreColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: scoreColor.withAlpha(60), width: 0.5),
                      ),
                      child: Text(scoreLabel,
                          style: TextStyle(fontSize: 10, color: scoreColor, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  score >= 90
                      ? '눈·코·입 좌우 배치가 매우 균형적이에요. 대칭적인 얼굴은 더 매력적으로 인식됩니다.'
                      : score >= 80
                          ? '전체적으로 균형 잡힌 얼굴이에요. 약간의 비대칭은 자연스러운 개성이에요.'
                          : score >= 70
                              ? '눈 또는 입꼬리에 약간의 비대칭이 있어요. 눈썹 정리로 시각적 보완이 가능해요.'
                              : '비대칭이 다소 두드러져요. 그루밍과 헤어스타일로 시각적 균형을 맞출 수 있어요.',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF777777), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkinAnalysisCard() {
    final skin = analysisResult['skinAnalysis'] as Map<String, dynamic>?;
    if (skin == null) return const SizedBox.shrink();

    final overall = skin['overall']?.toString() ?? '';
    final overallColor = overall == '좋음'
        ? const Color(0xFF27AE60)
        : overall == '관리필요'
            ? const Color(0xFFC0392B)
            : const Color(0xFFE8A030);

    final items = [
      ('피부 톤', skin['tone']),
      ('피부 결', skin['texture']),
      ('다크서클', skin['dark_circles']),
      ('모공', skin['pores']),
      ('잡티', skin['spots']),
      ('유수분', skin['oiliness']),
      ('붉은기', skin['redness']),
      ('전반', skin['overall']),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                    color: const Color(0xFF1A1A00),
                    borderRadius: BorderRadius.circular(7)),
                child: const Icon(Icons.face_retouching_natural,
                    size: 14, color: Color(0xFFE8D5B7)),
              ),
              const SizedBox(width: 8),
              const Text("피부 진단",
                  style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFFE8D5B7),
                      fontWeight: FontWeight.w500)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: overallColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(6)),
                child: Text(overall,
                    style: TextStyle(fontSize: 11, color: overallColor)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((e) {
              final label = e.$1;
              final value = e.$2?.toString() ?? '-';
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1C),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2A2A2A), width: 0.5),
                ),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                          text: '$label  ',
                          style: const TextStyle(
                              fontSize: 10, color: Color(0xFF555555))),
                      TextSpan(
                          text: value,
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFFCCCCCC))),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          if (skin['main_concern'] != null) ...[
            const SizedBox(height: 10),
            Container(height: 0.5, color: const Color(0xFF2A2A2A)),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text("주요 고민  ",
                    style: TextStyle(fontSize: 10, color: Color(0xFF555555))),
                Expanded(
                  child: Text(skin['main_concern'].toString(),
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFFE8A030))),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFaceMetricsCard() {
    final eyeAngle = faceData['eye_angle']?.toString() ?? '-';
    final eyeAngleDesc = faceData['eye_angle_desc']?.toString() ?? '';
    final goldenRatio = faceData['golden_ratio']?.toString() ?? '-';
    final goldenDesc = faceData['golden_desc']?.toString() ?? '';
    final faceShape = faceData['face_shape']?.toString() ?? '-';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A), width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(child: _buildMetric("눈꼬리 각도", "${eyeAngle}°", eyeAngleDesc)),
          Container(width: 0.5, height: 40, color: const Color(0xFF2A2A2A)),
          Expanded(child: _buildMetric("황금비율", goldenRatio, goldenDesc)),
          Container(width: 0.5, height: 40, color: const Color(0xFF2A2A2A)),
          Expanded(child: _buildMetric("얼굴형", faceShape, '')),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(fontSize: 10, color: Color(0xFF555555))),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFFE8D5B7),
                  fontWeight: FontWeight.w600)),
          if (desc.isNotEmpty)
            Text(desc,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 9, color: Color(0xFF666666))),
        ],
      ),
    );
  }

  Widget _buildLockedPlanCard({
    required IconData icon,
    required String label,
    required VoidCallback onUnlock,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1E1E1E), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 — 잠금 상태
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: const BoxDecoration(
              color: Color(0xFF131313),
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              border: Border(bottom: BorderSide(color: Color(0xFF1E1E1E), width: 0.5)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 17, color: const Color(0xFF3A3A3A)),
                ),
                const SizedBox(width: 10),
                Text(label,
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF3A3A3A), fontWeight: FontWeight.w700)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1200),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE8A030), width: 0.5),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock, size: 9, color: Color(0xFFE8A030)),
                      SizedBox(width: 3),
                      Text('PRO',
                          style: TextStyle(
                              fontSize: 9,
                              color: Color(0xFFE8A030),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 흐린 미리보기 바 — 현재 상태 섹션 모방
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF1E1E1E), width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          width: 56,
                          height: 7,
                          decoration: BoxDecoration(
                              color: const Color(0xFF222222),
                              borderRadius: BorderRadius.circular(4))),
                      const SizedBox(height: 8),
                      Container(
                          width: double.infinity,
                          height: 7,
                          decoration: BoxDecoration(
                              color: const Color(0xFF1C1C1C),
                              borderRadius: BorderRadius.circular(4))),
                      const SizedBox(height: 5),
                      Container(
                          width: 180,
                          height: 7,
                          decoration: BoxDecoration(
                              color: const Color(0xFF1C1C1C),
                              borderRadius: BorderRadius.circular(4))),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // 흐린 미리보기 바 — 선택지 섹션 모방
                ...List.generate(
                  2,
                  (_) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121612),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF192219), width: 0.5),
                      ),
                      child: Container(
                          width: 120,
                          height: 7,
                          decoration: BoxDecoration(
                              color: const Color(0xFF1C2A1C),
                              borderRadius: BorderRadius.circular(4))),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Before/After 잠금 해제 CTA
                GestureDetector(
                  onTap: onUnlock,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF3A2800), Color(0xFF251A00)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE8A030), width: 0.8),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_open_rounded, size: 14, color: Color(0xFFE8D5B7)),
                        SizedBox(width: 7),
                        Text('Before/After 플랜 잠금 해제',
                            style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFFE8D5B7),
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeforeAfterCard({
    required IconData icon,
    required Map<String, dynamic> data,
  }) {
    final title = data['title']?.toString() ?? '';
    final before = data['before']?.toString();
    final options = data['options'] as List?;
    final tip = data['tip']?.toString();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1E1E1E), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: const BoxDecoration(
              color: Color(0xFF161200),
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              border: Border(bottom: BorderSide(color: Color(0xFF2A2000), width: 0.5)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2000),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 17, color: const Color(0xFFE8D5B7)),
                ),
                const SizedBox(width: 10),
                Text(title, style: const TextStyle(
                    fontSize: 14, color: Color(0xFFE8D5B7), fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Before
                if (before != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141414),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF2A2A2A), width: 0.5),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.search, size: 13, color: Color(0xFF888888)),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('현재 상태',
                                  style: TextStyle(fontSize: 9, color: Color(0xFF666666),
                                      fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                              const SizedBox(height: 3),
                              Text(before,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA), height: 1.5)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Expanded(child: Divider(color: Color(0xFF1E1E1E), height: 1)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text('선택지', style: TextStyle(fontSize: 9, color: Color(0xFF444444))),
                      ),
                      Expanded(child: Divider(color: Color(0xFF1E1E1E), height: 1)),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                // After Options
                if (options != null)
                  ...options.asMap().entries.map((entry) {
                    final opt = entry.value as Map<String, dynamic>?;
                    if (opt == null) return const SizedBox.shrink();
                    final label = opt['label']?.toString() ?? '';
                    final effect = opt['effect']?.toString() ?? '';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1A10),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF1A3020), width: 0.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label, style: const TextStyle(
                              fontSize: 12, color: Color(0xFF88CCAA),
                              fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(effect, style: const TextStyle(
                              fontSize: 11, color: Color(0xFFAAAAAA), height: 1.5)),
                        ],
                      ),
                    );
                  }),
                // Tip
                if (tip != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline, size: 12, color: Color(0xFFE8A030)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(tip, style: const TextStyle(
                              fontSize: 11, color: Color(0xFF998855), height: 1.4)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurriculumCard({
    required IconData icon,
    required String title,
    required List<Widget> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1E1E1E), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: const BoxDecoration(
              color: Color(0xFF161200),
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              border: Border(bottom: BorderSide(color: Color(0xFF2A2000), width: 0.5)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2000),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 17, color: const Color(0xFFE8D5B7)),
                ),
                const SizedBox(width: 10),
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFE8D5B7),
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          // 아이템 목록
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(children: items),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(String label, String content) {
    // 항목 유형별 아이콘 매핑
    final itemConfig = _curriculumItemConfig(label);

    // 미용실 요청은 말풍선 스타일
    if (label == '미용실 요청') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.chat_bubble_outline, size: 13, color: Color(0xFF4A90D9)),
                const SizedBox(width: 6),
                const Text('미용실에서 이렇게 말하세요',
                    style: TextStyle(fontSize: 10, color: Color(0xFF4A90D9),
                        fontWeight: FontWeight.w600, letterSpacing: 0.3)),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1520),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1A3050), width: 0.5),
              ),
              child: Text('"$content"',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF88BBDD),
                      height: 1.5, fontStyle: FontStyle.italic)),
            ),
          ],
        ),
      );
    }

    // 주차 타임라인
    if (label.contains('주차')) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2000),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(label.replaceAll('주차', ''),
                        style: const TextStyle(fontSize: 10, color: Color(0xFFE8A030),
                            fontWeight: FontWeight.w700)),
                  ),
                ),
                Container(width: 1, height: 20, color: const Color(0xFF2A2000)),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(content,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFFAAAAAA), height: 1.5)),
              ),
            ),
          ],
        ),
      );
    }

    // 기본 아이템
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 26, height: 26,
            decoration: BoxDecoration(
              color: itemConfig.bg,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(itemConfig.icon, size: 13, color: itemConfig.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 10, color: itemConfig.color,
                        fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                const SizedBox(height: 3),
                Text(content,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFFAAAAAA), height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FaceOverlayPainter extends CustomPainter {
  final Map<String, dynamic> faceData;
  FaceOverlayPainter(this.faceData);

  @override
  void paint(Canvas canvas, Size size) {
    final imgW = (faceData['image_width'] as num?)?.toDouble() ?? 1;
    final imgH = (faceData['image_height'] as num?)?.toDouble() ?? 1;

    final scale = max(size.width / imgW, size.height / imgH);
    final ox = (size.width - imgW * scale) / 2;
    final oy = (size.height - imgH * scale) / 2;
    Offset t(double x, double y) => Offset(x * scale + ox, y * scale + oy);

    final bbLeft  = (faceData['bb_left']   as num?)?.toDouble();
    final bbTop   = (faceData['bb_top']    as num?)?.toDouble();
    final bbRight = (faceData['bb_right']  as num?)?.toDouble();
    final bbBottom= (faceData['bb_bottom'] as num?)?.toDouble();
    if (bbLeft == null || bbTop == null || bbRight == null || bbBottom == null) return;

    final leX  = (faceData['lm_left_eye_x']   as num?)?.toDouble();
    final leY  = (faceData['lm_left_eye_y']   as num?)?.toDouble();
    final reX  = (faceData['lm_right_eye_x']  as num?)?.toDouble();
    final reY  = (faceData['lm_right_eye_y']  as num?)?.toDouble();
    final noseX= (faceData['lm_nose_x']       as num?)?.toDouble();
    final noseY= (faceData['lm_nose_y']       as num?)?.toDouble();
    final lmX  = (faceData['lm_left_mouth_x'] as num?)?.toDouble();
    final lmY  = (faceData['lm_left_mouth_y'] as num?)?.toDouble();
    final rmX  = (faceData['lm_right_mouth_x'] as num?)?.toDouble();
    final rmY  = (faceData['lm_right_mouth_y'] as num?)?.toDouble();

    final faceW = bbRight - bbLeft;
    final faceH = bbBottom - bbTop;
    final cx = (bbLeft + bbRight) / 2;

    // ── 페인트 정의 ──────────────────────────────────
    Paint gridPaint(double alpha, double width) => Paint()
      ..color = const Color(0xFFE8D5B7).withAlpha(alpha.toInt())
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;

    final goldenPaint = Paint()
      ..color = const Color(0xFFE8A030).withAlpha(200)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    final dotGold = Paint()..color = const Color(0xFFE8A030)..style = PaintingStyle.fill;
    final dotWhite = Paint()..color = const Color(0xFFE8D5B7)..style = PaintingStyle.fill;

    // ── 1. 얼굴 타원 윤곽 ────────────────────────────
    final faceRect = Rect.fromLTRB(
      t(bbLeft, bbTop).dx, t(bbLeft, bbTop).dy,
      t(bbRight, bbBottom).dx, t(bbRight, bbBottom).dy,
    );
    canvas.drawOval(faceRect, gridPaint(90, 1.5));

    // ── 2. 황금비율 외곽 직사각형 ────────────────────
    canvas.drawRect(faceRect, gridPaint(40, 0.8));

    // ── 3. 수직 대칭선 ───────────────────────────────
    canvas.drawLine(
      t(cx, bbTop - faceH * 0.05),
      t(cx, bbBottom + faceH * 0.05),
      gridPaint(55, 0.9),
    );

    // ── 4. 황금비율 가로 3등분선 ─────────────────────
    // 이마~눈, 눈~코, 코~입턱 3분할
    final y1 = bbTop + faceH / 3;
    final y2 = bbTop + faceH * 2 / 3;
    for (final y in [y1, y2]) {
      canvas.drawLine(t(bbLeft, y), t(bbRight, y), gridPaint(45, 0.8));
    }

    // ── 5. 눈 레벨 황금선 (주황) ─────────────────────
    if (leY != null && reY != null) {
      final eyeY = (leY + reY) / 2;
      canvas.drawLine(
        t(bbLeft - faceW * 0.05, eyeY),
        t(bbRight + faceW * 0.05, eyeY),
        goldenPaint,
      );
      // 눈 연결선
      canvas.drawLine(t(leX!, eyeY), t(reX!, eyeY), goldenPaint);
      // 눈 폭 표시 브래킷
      _drawBracket(canvas, t(leX, eyeY), t(reX, eyeY), goldenPaint);
    }

    // ── 6. 코 레벨선 ─────────────────────────────────
    if (noseY != null) {
      canvas.drawLine(t(bbLeft, noseY), t(bbRight, noseY), gridPaint(120, 1.0));
    }

    // ── 7. 입 레벨선 ─────────────────────────────────
    if (lmY != null && rmY != null) {
      final mouthY = (lmY + rmY) / 2;
      canvas.drawLine(t(bbLeft, mouthY), t(bbRight, mouthY), gridPaint(100, 1.0));
    }

    // ── 8. 얼굴 황금비율 원 (눈 간격 기준) ──────────
    if (leX != null && reX != null && leY != null && reY != null) {
      final eyeGap = (reX - leX).abs() * scale;
      final faceCenter = t(cx, (bbTop + bbBottom) / 2);
      canvas.drawCircle(faceCenter, eyeGap * 0.9,
          Paint()
            ..color = const Color(0xFFE8D5B7).withAlpha(25)
            ..strokeWidth = 0.8
            ..style = PaintingStyle.stroke);
    }

    // ── 9. 랜드마크 점 + 작은 레이블 ────────────────
    void dot(double? x, double? y, double r, Paint p) {
      if (x != null && y != null) {
        canvas.drawCircle(t(x, y), r, p);
        canvas.drawCircle(t(x, y), r + 1.5,
            Paint()..color = Colors.black.withAlpha(80)..style = PaintingStyle.stroke..strokeWidth = 0.8);
      }
    }

    dot(leX, leY, 4.5, dotGold);
    dot(reX, reY, 4.5, dotGold);
    dot(noseX, noseY, 3.5, dotWhite);
    dot(lmX, lmY, 3.0, dotWhite);
    dot(rmX, rmY, 3.0, dotWhite);

    // ── 10. 코너 마커 (정밀 측정 느낌) ──────────────
    _drawCornerMarkers(canvas, faceRect, gridPaint(140, 2.0));

    // ── 11. 수치 텍스트 레이블 ───────────────────────
    final eyeAngle = faceData['eye_angle']?.toString() ?? '';
    final eyeAngleDesc = faceData['eye_angle_desc']?.toString() ?? '';
    final goldenRatio = faceData['golden_ratio']?.toString() ?? '';

    if (leX != null && leY != null && eyeAngle.isNotEmpty) {
      _drawLabel(canvas, t(bbLeft - faceW * 0.02, (leY! + reY!) / 2 - 12),
          '$eyeAngle° $eyeAngleDesc', const Color(0xFFE8A030), 9.0, TextAlign.right);
    }
    if (noseY != null && goldenRatio.isNotEmpty) {
      _drawLabel(canvas, t(bbRight + faceW * 0.02, noseY! - 8),
          '비율 $goldenRatio', const Color(0xFFE8D5B7), 8.0, TextAlign.left);
    }
  }

  void _drawBracket(Canvas canvas, Offset a, Offset b, Paint paint) {
    const h = 6.0;
    canvas.drawLine(Offset(a.dx, a.dy - h), Offset(a.dx, a.dy + h), paint);
    canvas.drawLine(Offset(b.dx, b.dy - h), Offset(b.dx, b.dy + h), paint);
  }

  void _drawCornerMarkers(Canvas canvas, Rect rect, Paint paint) {
    const len = 12.0;
    final corners = [
      [rect.topLeft, Offset(rect.left + len, rect.top), Offset(rect.left, rect.top + len)],
      [rect.topRight, Offset(rect.right - len, rect.top), Offset(rect.right, rect.top + len)],
      [rect.bottomLeft, Offset(rect.left + len, rect.bottom), Offset(rect.left, rect.bottom - len)],
      [rect.bottomRight, Offset(rect.right - len, rect.bottom), Offset(rect.right, rect.bottom - len)],
    ];
    for (final c in corners) {
      canvas.drawLine(c[0], c[1], paint);
      canvas.drawLine(c[0], c[2], paint);
    }
  }

  void _drawLabel(Canvas canvas, Offset pos, String text, Color color, double fontSize, TextAlign align) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(
        color: color, fontSize: fontSize, fontWeight: FontWeight.w600,
        shadows: [Shadow(color: Colors.black.withAlpha(200), blurRadius: 4)],
      )),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout(maxWidth: 80);
    tp.paint(canvas, align == TextAlign.right
        ? Offset(pos.dx - tp.width, pos.dy)
        : pos);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}