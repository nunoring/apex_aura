import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'config.dart';
import 'result_screen.dart';
import 'face_detector_service.dart';
import 'face_selection_screen.dart';
import 'history_service.dart';

class LoadingScreen extends StatefulWidget {
  final String animalType;
  final double sliderValue;
  final List<File> imageFiles;
  final int faceIndex;
  final String gender; // 'male' | 'female'

  const LoadingScreen({
    super.key,
    required this.animalType,
    required this.sliderValue,
    required this.imageFiles,
    this.faceIndex = -1,
    this.gender = 'male',
  });

  File get primaryImage => imageFiles[0];

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _timerController;
  int _currentStep = 0;
  int _gptMessageIndex = 0;
  bool _isGptPhase = false;

  // GPT 분석 중 사이클 메시지
  final List<String> _gptMessages = [
    "얼굴 윤곽 분석 중...",
    "눈매 특징 측정 중...",
    "피부 상태 판독 중...",
    "동물상 데이터 매칭 중...",
    "헤어 플랜 작성 중...",
    "피부 루틴 설계 중...",
    "그루밍 포인트 도출 중...",
    "시술 로드맵 생성 중...",
    "결과 종합 정리 중...",
  ];

  final List<String> _steps = [
    "얼굴 랜드마크 추출",
    "황금비율 수치 계산",
    "AI 심층 분석",
    "결과 생성",
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
    // GPT 단계용 타이머 (30초 기준 가짜 진행바)
    _timerController = AnimationController(
        vsync: this, duration: const Duration(seconds: 45));
    _start();
  }

  Future<void> _start() async {
    // faceIndex == -1 이면 먼저 얼굴 수 확인
    if (widget.faceIndex < 0) {
      final detection = await FaceDetectorService.detectFaces(widget.primaryImage);

      if (detection == null || detection.boxes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('얼굴을 찾을 수 없어요. 정면 셀카로 다시 시도해주세요.'),
              backgroundColor: Color(0xFF2A1A00),
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.pop(context);
        }
        return;
      }

      // 얼굴 너무 작으면 경고 (비차단)
      final faceW = detection.boxes[0].width;
      if (faceW / detection.imageW < 0.08 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('얼굴이 너무 작게 찍혔어요. 더 가까이서 찍으면 정확도가 높아져요.'),
            backgroundColor: Color(0xFF2A1A00),
            duration: Duration(seconds: 4),
          ),
        );
      }

      // 얼굴 2개 이상 → 선택 화면으로
      if (detection.boxes.length > 1) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => FaceSelectionScreen(
                imageFile: widget.primaryImage,
                animalType: widget.animalType,
                sliderValue: widget.sliderValue,
                faceBoxes: detection.boxes,
                imageSize: Size(detection.imageW, detection.imageH),
                allImageFiles: widget.imageFiles,
                gender: widget.gender,
              ),
            ),
          );
        }
        return;
      }
    }

    _analyzeImage();
  }

  Future<void> _analyzeImage() async {
    try {
      final selectedIndex = widget.faceIndex < 0 ? 0 : widget.faceIndex;

      // 진행바 즉시 시작 — ML Kit 구간부터 보이도록
      _timerController.forward();

      // Step 0 → 1: ML Kit 준비 (실제로 짧음)
      if (mounted) setState(() => _currentStep = 0);
      await Future.delayed(const Duration(milliseconds: 200));

      // Step 1: 얼굴 랜드마크 추출 (ML Kit 실행)
      if (mounted) setState(() => _currentStep = 1);
      Map<String, dynamic>? faceData;
      if (widget.imageFiles.length > 1) {
        faceData = await FaceDetectorService.analyzeMultiplePhotos(
          widget.imageFiles,
          primaryFaceIndex: selectedIndex,
        );
      } else {
        faceData = await FaceDetectorService.analyzeFace(
          widget.primaryImage,
          faceIndex: selectedIndex,
        );
      }

      if (faceData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('얼굴 분석에 실패했어요. 다시 시도해주세요.'),
              backgroundColor: Color(0xFF2A1A00),
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.pop(context);
        }
        return;
      }

      // 측면 얼굴 차단
      if (faceData['error'] == 'angle_detected') {
        if (mounted) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('📸 사진을 다시 선택해주세요'),
              content: Text(faceData!['message'] ?? '정면 얼굴 사진을 사용해주세요'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('다시 선택'),
                ),
              ],
            ),
          );
          if (mounted) Navigator.pop(context);
        }
        return;
      }

      // Step 2: 황금비율 수치 계산 완료 (ML Kit 끝)
      if (mounted) setState(() => _currentStep = 2);
      await Future.delayed(const Duration(milliseconds: 300));

      // Step 3: AI 심층 분석 시작 (Firebase — 실제로 오래 걸리는 구간)
      if (mounted) setState(() {
        _currentStep = 3;
        _isGptPhase = true;
      });
      _startGptMessages();

      final result = await _getAnalysisWithRetry(faceData);

      // Step 4: 결과 생성 완료
      _timerController.stop();
      if (mounted) setState(() {
        _isGptPhase = false;
        _currentStep = _steps.length;
      });

      // 히스토리 저장 (백그라운드, 실패해도 무시)
      final currentType =
          faceData!['current_face_type']?.toString() ?? widget.animalType;
      HistoryService.save(
        currentType: currentType,
        targetType: widget.animalType,
        gender: widget.gender,
        imageFile: widget.primaryImage,
        analysisResult: result,
        faceData: faceData,
      );

      await Future.delayed(const Duration(milliseconds: 400));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResultScreen(
              animalType: widget.animalType,
              sliderValue: widget.sliderValue,
              analysisResult: result,
              imageFile: widget.primaryImage,
              faceData: faceData!,
              gender: widget.gender,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('분석 실패: $e'), backgroundColor: Colors.red),
        );
        Navigator.pop(context);
      }
    }
  }

  void _startGptMessages() {
    Future.doWhile(() async {
      if (!mounted || !_isGptPhase) return false;
      await Future.delayed(const Duration(milliseconds: 2800));
      if (mounted && _isGptPhase) {
        setState(() {
          _gptMessageIndex = (_gptMessageIndex + 1) % _gptMessages.length;
        });
      }
      return mounted && _isGptPhase;
    });
  }

  static const List<String> _bannedWords = [
    '필러', '보톡스', '성형', '수술', '리프팅', '레이저', '시술', '이식', '윤곽술',
    '처방', '치료', '진료', '임상', '의학적', '의사',
    '약물', '호르몬',
    '못생긴', '결함', '흠', '단점', '못난', '추한',
  ];

  bool _isValidResponse(Map<String, dynamic> data) {
    try {
      if (!data.containsKey('comparison') ||
          !data.containsKey('radar') ||
          !data.containsKey('consultant_report') ||
          !data.containsKey('action_cards') ||
          !data.containsKey('milestones')) return false;
      final cards = data['action_cards'] as List;
      if (cards.length < 3) return false;
      final report = data['consultant_report'];
      if ((report['observation'] as String).length < 30) return false;
      for (final card in cards) {
        if ((card['principle'] as String).length < 50) return false;
        if ((card['observation'] as String).length < 30) return false;
        if ((card['application'] as String).length < 30) return false;
        if ((card['references'] as List).length < 2) return false;
      }
      if ((data['milestones'] as List).length < 3) return false;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> _getAnalysisWithRetry(
    Map<String, dynamic> faceData, {
    int retryCount = 0,
    String? extraInstruction,
  }) async {
    final response = await _callFirebase(faceData, extraInstruction: extraInstruction);
    final responseText = jsonEncode(response);
    final hasBanned = _bannedWords.any((w) => responseText.contains(w));
    if (!hasBanned && _isValidResponse(response)) return response;
    if (retryCount >= 2) return _buildFallbackResponse();
    return _getAnalysisWithRetry(
      faceData,
      retryCount: retryCount + 1,
      extraInstruction: hasBanned
          ? '이전 응답에 금지 단어가 포함됐어요. 시술/의료 관련 표현을 헤어, 메이크업, 패션 관련 표현으로 대체해서 다시 응답해줘.'
          : '이전 응답이 필수 형식을 충족하지 않았어요. JSON 구조와 최소 글자 수를 지켜서 다시 응답해줘.',
    );
  }

  Map<String, dynamic> _buildFallbackResponse() {
    return {
      "comparison": {
        "current_animal": "분석 중",
        "target_animal": widget.animalType,
        "current_keywords": ["자연스러움", "친근함", "부드러움"],
        "target_keywords": ["세련됨", "정돈됨", "또렷함"],
        "gap_percent": 50
      },
      "radar": {
        "current": {"눈매": 0.5, "코": 0.5, "얼굴윤곽": 0.5, "스타일": 0.4},
        "target": {"눈매": 0.8, "코": 0.7, "얼굴윤곽": 0.8, "스타일": 0.85}
      },
      "consultant_report": {
        "quote": "더 세련된 스타일로 변화할 수 있는 포인트들이 있어요.",
        "observation": "전반적으로 자연스럽고 친근한 인상이에요. 눈매와 헤어 스타일링에서 변화 포인트를 찾을 수 있어요.",
        "impact": "부드럽고 편안한 느낌을 줘요.",
        "gap": "눈매와 스타일링 완성도에서 차이가 있어요.",
        "direction": "눈 연출과 헤어 스타일링이 핵심이에요."
      },
      "action_cards": [
        {
          "category": "헤어스타일",
          "icon": "scissors",
          "observation": "현재 헤어스타일이 얼굴 윤곽을 가리고 있어 인상이 다소 묻히고 있어요.",
          "principle": "레이어드컷은 얼굴 옆선을 자연스럽게 드러내 윤곽을 강조하는 효과가 있어요. 볼륨과 라인을 동시에 잡을 수 있어서 인상 변화에 효율적인 방법이에요.",
          "application": "미디엄 레이어드 또는 가르마형 앞머리로 변화를 주는 게 좋아요.",
          "references": [
            {"name": "고준희", "context": "2022 SNS 화보", "description": "쇄골 위 단발로 목선을 드러낸 자연스러운 스타일"},
            {"name": "한지민", "context": "드라마 미스티", "description": "어깨 길이 레이어드, 옆선을 자연스럽게 강조한 스타일"}
          ],
          "caution": null
        },
        {
          "category": "패션/스타일링",
          "icon": "shirt",
          "observation": "전체적인 스타일링 완성도를 높이면 인상이 한층 달라질 수 있어요.",
          "principle": "핏이 맞는 상의와 세로 라인을 강조하는 아이템이 세련된 인상을 만들어요. 색상 통일감도 전체적인 완성도에 크게 영향을 줘요.",
          "application": "슬림핏 상의와 단색 위주의 조합으로 정돈된 느낌을 주세요.",
          "references": [
            {"name": "정해인", "context": "2023 화보", "description": "심플한 화이트 셔츠로 깔끔한 인상 연출"},
            {"name": "박서준", "context": "드라마 이태원클라쓰", "description": "블랙 핏 자켓으로 세련된 라인 강조"}
          ],
          "caution": null
        },
        {
          "category": widget.gender == 'female' ? '메이크업' : '그루밍',
          "icon": widget.gender == 'female' ? 'makeup' : 'grooming',
          "observation": "눈매 연출과 눈썹 정리가 전체 인상 변화의 핵심 포인트예요.",
          "principle": "아이라인과 마스카라로 눈매를 또렷하게 만들면 전체 인상이 달라져요. 눈썹 형태를 잡아주는 것만으로도 얼굴 정돈 효과가 크게 나타나요.",
          "application": "눈 꼬리 라인 강조와 볼륨 마스카라로 눈매를 선명하게 만들어보세요.",
          "references": [
            {"name": "맥 플루이드라인", "context": "#blacktrack", "description": "지속력 좋은 리퀴드 라이너로 선명한 라인 완성"},
            {"name": "랑콤 모노시크라", "context": "01 Cils Noirs", "description": "컬링과 볼륨을 동시에, 자연스러운 눈매 완성"}
          ],
          "caution": null
        }
      ],
      "milestones": [
        {"days": 30, "description": "눈매 연출 변화 체감 시작"},
        {"days": 60, "description": "헤어 스타일 전환 완성"},
        {"days": 90, "description": "전체 스타일링 완성 및 인상 변화 체감"}
      ]
    };
  }

  Future<Map<String, dynamic>> _callFirebase(Map<String, dynamic> faceData, {String? extraInstruction}) async {
    final impression = widget.sliderValue < 0.4
        ? "초식계"
        : widget.sliderValue > 0.6
            ? "육식계"
            : "중간계";

    final imageBytes = await widget.primaryImage.readAsBytes();
    final base64Image = base64Encode(imageBytes);

    final response = await http.post(
      Uri.parse(kAnalyzeImageUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'base64Image': base64Image,
        'animalType': widget.animalType,
        'impression': impression,
        'faceData': faceData,
        'gender': widget.gender,
        'isPro': false,
        if (extraInstruction != null) 'extraInstruction': extraInstruction,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('서버 오류: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    // 새 API는 { success, data } 구조, 구버전은 flat 구조
    return decoded.containsKey('data') ? decoded['data'] as Map<String, dynamic> : decoded;
  }

  @override
  void dispose() {
    _controller.dispose();
    _timerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                          color: const Color(0xFF2A2A2A), width: 0.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Image.file(widget.primaryImage, fit: BoxFit.cover),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (_, __) => Positioned(
                      top: 120 * _controller.value,
                      left: 0, right: 0,
                      child: Container(
                        height: 2,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Color(0xFFE8D5B7),
                              Colors.transparent
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0, right: 0,
                    child: Container(
                      width: 24, height: 24,
                      decoration: const BoxDecoration(
                          color: Color(0xFFE8A030),
                          shape: BoxShape.circle),
                      child: const Center(
                          child: Text("AI",
                              style: TextStyle(
                                  fontSize: 8,
                                  color: Color(0xFF1A0F00),
                                  fontWeight: FontWeight.bold))),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Text(
                  _isGptPhase
                      ? _gptMessages[_gptMessageIndex]
                      : "얼굴 분석 중...",
                  key: ValueKey(_gptMessageIndex),
                  style: const TextStyle(
                      fontSize: 17, color: Color(0xFFF0F0F0),
                      fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _isGptPhase
                    ? "약 20~30초 소요됩니다  ·  종료하지 마세요"
                    : "${widget.animalType} 기준으로 갭을 계산하고 있어요",
                style: const TextStyle(fontSize: 11, color: Color(0xFF555555)),
              ),
              // 전체 구간 진행바 (ML Kit 시작부터 Firebase 완료까지)
              const SizedBox(height: 12),
              AnimatedBuilder(
                animation: _timerController,
                builder: (_, __) => ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: _timerController.value,
                    backgroundColor: const Color(0xFF1A1A1A),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFE8A030)),
                    minHeight: 3,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Column(
                children: List.generate(_steps.length, (index) {
                  final isDone = _currentStep > index;
                  final isDoing = _currentStep == index;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161616),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: isDone
                                ? const Color(0xFF0A1F0A)
                                : isDoing
                                    ? const Color(0xFF2A1A00)
                                    : const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isDone ? Icons.check : Icons.circle,
                            size: 14,
                            color: isDone
                                ? const Color(0xFF27AE60)
                                : isDoing
                                    ? const Color(0xFFE8A030)
                                    : const Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(_steps[index],
                              style: TextStyle(
                                fontSize: 12,
                                color: isDone
                                    ? const Color(0xFF27AE60)
                                    : isDoing
                                        ? const Color(0xFFE8A030)
                                        : const Color(0xFF333333),
                              )),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDone
                                ? const Color(0xFF0A1F0A)
                                : isDoing
                                    ? const Color(0xFF2A1A00)
                                    : const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isDone ? "완료" : isDoing ? "진행 중" : "대기",
                            style: TextStyle(
                              fontSize: 10,
                              color: isDone
                                  ? const Color(0xFF27AE60)
                                  : isDoing
                                      ? const Color(0xFFE8A030)
                                      : const Color(0xFF333333),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: _currentStep / _steps.length,
                  backgroundColor: const Color(0xFF1A1A1A),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFE8D5B7)),
                  minHeight: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}