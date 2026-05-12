import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'loading_screen.dart';
import 'camera_guide_screen.dart';
import 'history_service.dart';
import 'result_screen.dart';
import 'subscription_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<File> _selectedImages = [];
  int _selectedAnimal = -1;
  String _gender = ''; // 'male' | 'female'
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> _history = [];
  bool _isSubscribed = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final h = await HistoryService.load();
    final sub = await SubscriptionService.isSubscribed();
    if (mounted) setState(() { _history = h; _isSubscribed = sub; });
  }

  void _openHistory(Map<String, dynamic> record) {
    final imageFile = File(record['imagePath'] as String);
    if (!imageFile.existsSync()) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          animalType: record['targetType'] as String,
          sliderValue: 0.5,
          analysisResult: Map<String, dynamic>.from(record['analysisResult'] as Map),
          imageFile: imageFile,
          faceData: Map<String, dynamic>.from(record['faceData'] as Map),
          gender: record['gender'] as String? ?? 'male',
        ),
      ),
    ).then((_) => _loadHistory());
  }

  static const _accuracyLabels = ['', '기본 분석', '보통', '권장', '정확', '최고 정확도'];
  static const _accuracyColors = [
    Color(0xFF333333),
    Color(0xFF555555),
    Color(0xFF888855),
    Color(0xFFE8A030),
    Color(0xFF27AE60),
    Color(0xFF27AE60),
  ];

  final List<Map<String, String>> _animals = [
    {
      "emoji": "🐶",
      "label": "강아지상",
      "imgKey": "dog",
      "desc": "내려간 눈꼬리·넓은 눈 간격",
      "impression": "친근하고 온화한 인상. 보는 사람을 편안하게 만드는 부드러운 눈매가 특징이에요.",
      "features": "내려간 눈꼬리 · 넓은 눈 간격 · 둥근 얼굴형",
    },
    {
      "emoji": "🐱",
      "label": "고양이상",
      "imgKey": "cat",
      "desc": "올라간 눈꼬리·날카로운 눈매",
      "impression": "신비롭고 도도한 인상. 올라간 눈꼬리와 좁은 눈 간격이 세련된 분위기를 만들어요.",
      "features": "올라간 눈꼬리 · 좁은 눈 간격 · 선명한 눈매",
    },
    {
      "emoji": "🐻",
      "label": "곰상",
      "imgKey": "bear",
      "desc": "둥글고 포근한 얼굴",
      "impression": "귀엽고 포근한 인상. 둥근 얼굴형과 부드러운 눈매로 호감도가 높아요.",
      "features": "둥근 얼굴형 · 부드러운 눈매 · 작은 눈",
    },
    {
      "emoji": "🐺",
      "label": "늑대상",
      "imgKey": "wolf",
      "desc": "갸름한 얼굴·강렬한 눈빛",
      "impression": "강렬하고 카리스마 있는 인상. 갸름한 얼굴과 수평 눈꼬리가 냉철한 분위기를 줘요.",
      "features": "갸름한 얼굴 · 수평 눈꼬리 · 강렬한 눈빛",
    },
    {
      "emoji": "🦊",
      "label": "여우상",
      "imgKey": "fox",
      "desc": "많이 올라간 눈꼬리·예리함",
      "impression": "섹시하고 영리해 보이는 인상. 강하게 올라간 눈꼬리와 예리한 눈매가 시선을 사로잡아요.",
      "features": "많이 올라간 눈꼬리 · 갸름한 얼굴 · 예리한 눈매",
    },
  ];

  Color _tierColor(String tier) => switch (tier) {
    'S' => const Color(0xFFFFD700),
    'A' => const Color(0xFF27AE60),
    'B' => const Color(0xFF4A90D9),
    'C' => const Color(0xFFE8A030),
    _ => const Color(0xFFC0392B),
  };

  Future<void> _addImage() async {
    if (_selectedImages.length >= 5) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFF333333), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.face_retouching_natural, color: Color(0xFFE8A030)),
              title: const Text('가이드 촬영 (추천)', style: TextStyle(color: Colors.white)),
              subtitle: const Text('얼굴 타원에 맞춰 찍어요 — 더 정확한 분석',
                  style: TextStyle(color: Color(0xFF888888), fontSize: 11)),
              onTap: () async {
                Navigator.pop(context);
                final file = await CameraGuideScreen.capture(context);
                if (file != null) setState(() => _selectedImages.add(file));
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFFE8D5B7)),
              title: const Text('일반 카메라', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(source: ImageSource.camera);
                if (image != null) setState(() => _selectedImages.add(File(image.path)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFFE8D5B7)),
              title: const Text('갤러리에서 선택 (다중)', style: TextStyle(color: Colors.white)),
              subtitle: Text('최대 ${5 - _selectedImages.length}장 더 선택 가능',
                  style: const TextStyle(color: Color(0xFF555555), fontSize: 11)),
              onTap: () async {
                Navigator.pop(context);
                final remaining = 5 - _selectedImages.length;
                final List<XFile> images = await _picker.pickMultiImage();
                if (images.isEmpty) return;
                final added = <File>[];
                for (final img in images) {
                  if (_selectedImages.length + added.length < 5) {
                    added.add(File(img.path));
                  }
                }
                setState(() => _selectedImages.addAll(added));
                if (images.length > remaining && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('최대 5장까지 가능해요. $remaining장만 추가됐어요.'),
                    backgroundColor: const Color(0xFF2A1A00),
                    duration: const Duration(seconds: 2),
                  ));
                }
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  void _resetInputForm() {
    setState(() {
      _selectedImages.clear();
      _selectedAnimal = -1;
      _gender = '';
    });
  }

  Widget _buildPhotoSection() {
    final count = _selectedImages.length;
    final accuracyColor = count == 0 ? const Color(0xFF333333) : _accuracyColors[count];
    final accuracyLabel = count == 0 ? '' : _accuracyLabels[count];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 정확도 표시
        Row(
          children: [
            const Text('사진 업로드',
                style: TextStyle(fontSize: 11, color: Color(0xFF555555), letterSpacing: 0.5)),
            const SizedBox(width: 8),
            Text('$count / 5',
                style: const TextStyle(fontSize: 11, color: Color(0xFF444444))),
            if (count > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: accuracyColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: accuracyColor.withAlpha(80), width: 0.5),
                ),
                child: Text(accuracyLabel,
                    style: TextStyle(fontSize: 10, color: accuracyColor, fontWeight: FontWeight.w600)),
              ),
            ],
            const Spacer(),
            // 정확도 바
            Row(
              children: List.generate(5, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(left: 3),
                width: 14, height: 5,
                decoration: BoxDecoration(
                  color: i < count ? accuracyColor : const Color(0xFF222222),
                  borderRadius: BorderRadius.circular(2),
                ),
              )),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 사진 그리드 (가로 스크롤)
        SizedBox(
          height: 110,
          child: _selectedImages.isEmpty
              ? _buildAddTile()
              : ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ...List.generate(_selectedImages.length, (i) => _buildPhotoTile(i)),
                    if (_selectedImages.length < 5) _buildAddTile(),
                  ],
                ),
        ),

        // 안내 문구
        const SizedBox(height: 8),
        const Text(
          '여러 장일수록 얼굴 수치가 안정적으로 측정돼요  ·  정면 · 밝은 환경 권장',
          style: TextStyle(fontSize: 10, color: Color(0xFF444444)),
        ),
      ],
    );
  }

  Widget _buildPhotoTile(int index) {
    return Container(
      width: 100,
      height: 110,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              _selectedImages[index],
              width: 100, height: 110,
              fit: BoxFit.cover,
            ),
          ),
          // 첫 번째 사진 표시
          if (index == 0)
            Positioned(
              bottom: 6, left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('대표', style: TextStyle(fontSize: 9, color: Color(0xFFE8D5B7))),
              ),
            ),
          // 삭제 버튼
          Positioned(
            top: 4, right: 4,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                width: 20, height: 20,
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddTile() {
    final isEmpty = _selectedImages.isEmpty;
    return GestureDetector(
      onTap: _addImage,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 100,
        height: 110,
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEmpty ? const Color(0xFF333333) : const Color(0xFF2A2A2A),
            width: 0.5,
          ),
        ),
        child: isEmpty
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_outlined, color: Color(0xFF666666), size: 32),
                  SizedBox(height: 8),
                  Text('사진 추가', style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 13, fontWeight: FontWeight.w500)),
                  SizedBox(height: 2),
                  Text('최대 5장', style: TextStyle(color: Color(0xFF444444), fontSize: 10)),
                ],
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: Color(0xFF555555), size: 24),
                  SizedBox(height: 4),
                  Text('추가', style: TextStyle(color: Color(0xFF555555), fontSize: 10)),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 로고
              const Center(
                child: Text(
                  "APEX AURA",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFE8D5B7),
                    letterSpacing: 4,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 이전 분석 히스토리
              if (_history.isNotEmpty) ...[
                Row(
                  children: [
                    const Text('이전 분석',
                        style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF555555),
                            letterSpacing: 0.5)),
                    const Spacer(),
                    if (!_isSubscribed)
                      const Text('구독 시 전체 기록 열람',
                          style: TextStyle(fontSize: 10, color: Color(0xFF444444))),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 106,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _isSubscribed
                        ? _history.length
                        : (_history.length > 1 ? 2 : 1),
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      // 비구독자: 두 번째 카드는 잠금 표시
                      if (!_isSubscribed && i == 1) {
                        return GestureDetector(
                          onTap: () {},
                          child: Container(
                            width: 72,
                            decoration: BoxDecoration(
                              color: const Color(0xFF111111),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFF1E1E1E), width: 0.5),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.lock, size: 20,
                                    color: Color(0xFF444444)),
                                SizedBox(height: 6),
                                Text('구독\n전용',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 9,
                                        color: Color(0xFF444444),
                                        height: 1.4)),
                              ],
                            ),
                          ),
                        );
                      }
                      final r = _history[i];
                      final score = r['score'] as int? ?? 0;
                      final tier = r['tier'] as String? ?? 'B';
                      final tierColor = _tierColor(tier);
                      final dateStr = HistoryService.dateLabel(
                          r['date'] as String? ?? '');
                      final currentType =
                          (r['currentType'] as String? ?? '').replaceAll('상', '');
                      final targetType =
                          (r['targetType'] as String? ?? '').replaceAll('상', '');
                      return GestureDetector(
                        onTap: () => _openHistory(r),
                        child: Container(
                          width: 72,
                          decoration: BoxDecoration(
                            color: const Color(0xFF111111),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFF1E1E1E), width: 0.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12)),
                                child: Image.file(
                                  File(r['imagePath'] as String),
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 56,
                                    color: const Color(0xFF1A1A1A),
                                    child: const Icon(Icons.person,
                                        color: Color(0xFF333333)),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(5, 5, 5, 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text('$score점',
                                            style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: tierColor)),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: tierColor.withAlpha(25),
                                            borderRadius:
                                                BorderRadius.circular(3),
                                          ),
                                          child: Text(tier,
                                              style: TextStyle(
                                                  fontSize: 8,
                                                  color: tierColor,
                                                  fontWeight: FontWeight.w700)),
                                        ),
                                      ],
                                    ),
                                    Text('$currentType→$targetType',
                                        style: const TextStyle(
                                            fontSize: 8,
                                            color: Color(0xFF555555)),
                                        overflow: TextOverflow.ellipsis),
                                    Text(dateStr,
                                        style: const TextStyle(
                                            fontSize: 8,
                                            color: Color(0xFF444444))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 멀티사진 업로드 존
              _buildPhotoSection(),
              const SizedBox(height: 24),

              // 성별 선택
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _gender = 'male'),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _gender == 'male' ? const Color(0xFF1A1900) : const Color(0xFF161616),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _gender == 'male' ? const Color(0xFFE8D5B7) : const Color(0xFF2A2A2A),
                            width: _gender == 'male' ? 1.5 : 0.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text('♂', style: TextStyle(fontSize: 20)),
                            const SizedBox(height: 2),
                            Text('남성',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _gender == 'male' ? const Color(0xFFE8D5B7) : const Color(0xFF555555),
                                  fontWeight: _gender == 'male' ? FontWeight.w600 : FontWeight.normal,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _gender = 'female'),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _gender == 'female' ? const Color(0xFF1A1900) : const Color(0xFF161616),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _gender == 'female' ? const Color(0xFFE8D5B7) : const Color(0xFF2A2A2A),
                            width: _gender == 'female' ? 1.5 : 0.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text('♀', style: TextStyle(fontSize: 20)),
                            const SizedBox(height: 2),
                            Text('여성',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _gender == 'female' ? const Color(0xFFE8D5B7) : const Color(0xFF555555),
                                  fontWeight: _gender == 'female' ? FontWeight.w600 : FontWeight.normal,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 구분선
              Row(
                children: [
                  Expanded(child: Container(height: 0.5, color: const Color(0xFF222222))),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text("추구미 설정", style: TextStyle(color: Color(0xFF444444), fontSize: 11)),
                  ),
                  Expanded(child: Container(height: 0.5, color: const Color(0xFF222222))),
                ],
              ),
              const SizedBox(height: 16),

              // 동물상 선택 — 5개 전체 표시 (가로 스크롤 없음)
              const Text("동물상 선택", style: TextStyle(color: Color(0xFF555555), fontSize: 11, letterSpacing: 0.5)),
              const SizedBox(height: 10),
              Row(
                children: _animals.asMap().entries.map((e) {
                  final index = e.key;
                  final isSelected = _selectedAnimal == index;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedAnimal = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 80,
                        margin: EdgeInsets.only(
                            right: index < _animals.length - 1 ? 6 : 0),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF1E1900)
                              : const Color(0xFF1C1C1C),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFE8D5B7)
                                : const Color(0xFF2A2A2A),
                            width: isSelected ? 1.5 : 0.5,
                          ),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                'assets/images/${_animals[index]["imgKey"]!}_${_gender.isEmpty ? "male" : _gender}.png',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const SizedBox(),
                              ),
                            ),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withAlpha(
                                          isSelected ? 130 : 170),
                                    ],
                                    stops: const [0.3, 1.0],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 6, left: 0, right: 0,
                              child: Text(
                                _animals[index]["label"]!.replaceAll("상", ""),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? const Color(0xFFE8D5B7)
                                      : const Color(0xFFAAAAAA),
                                ),
                              ),
                            ),
                            if (isSelected)
                              Positioned(
                                top: 4, right: 4,
                                child: Container(
                                  width: 14, height: 14,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE8D5B7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check,
                                      size: 9, color: Color(0xFF1A0F00)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // 분석 시작 버튼
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: (_selectedImages.isNotEmpty && _selectedAnimal != -1 && _gender.isNotEmpty)
                      ? () async {
                          final shouldRefresh = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LoadingScreen(
                                animalType: _animals[_selectedAnimal]["label"]!,
                                sliderValue: 0.5,
                                imageFiles: _selectedImages,
                                gender: _gender,
                              ),
                            ),
                          );
                          if (shouldRefresh == true && mounted) {
                            _resetInputForm();
                            _loadHistory();
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8D5B7),
                    disabledBackgroundColor: const Color(0xFF2A2A2A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text(
                    (_selectedImages.isEmpty || _selectedAnimal == -1 || _gender.isEmpty)
                        ? '사진 · 성별 · 추구미를 선택해주세요'
                        : '분석 시작하기',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: (_selectedImages.isEmpty || _selectedAnimal == -1)
                          ? const Color(0xFF444444)
                          : const Color(0xFF1A0F00),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}