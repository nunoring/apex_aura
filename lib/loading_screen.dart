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

      // Step 2: 황금비율 수치 계산 완료 (ML Kit 끝)
      if (mounted) setState(() => _currentStep = 2);
      await Future.delayed(const Duration(milliseconds: 300));

      // Step 3: AI 심층 분석 시작 (Firebase — 실제로 오래 걸리는 구간)
      if (mounted) setState(() {
        _currentStep = 3;
        _isGptPhase = true;
      });
      _startGptMessages();

      final result = await _callFirebase(faceData);

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

  Future<Map<String, dynamic>> _callFirebase(Map<String, dynamic> faceData) async {
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
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('서버 오류: ${response.statusCode}');
    }

    return jsonDecode(response.body);
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