import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'config.dart';
import 'services/claude_service.dart';
import 'result_screen.dart';
import 'face_detector_service.dart';
import 'face_selection_screen.dart';
import 'history_service.dart';
import 'subscription_service.dart';

class _AnalysisException implements Exception {
  final String code;
  final String message;
  _AnalysisException({required this.code, required this.message});
}

class LoadingScreen extends StatefulWidget {
  final String animalType;
  final double sliderValue;
  final List<File> imageFiles;
  final int faceIndex;
  final String gender; // 'male' | 'female'
  final bool isPro;

  const LoadingScreen({
    super.key,
    required this.animalType,
    required this.sliderValue,
    required this.imageFiles,
    this.faceIndex = -1,
    this.gender = 'male',
    this.isPro = false,
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
  bool _effectiveIsPro = false;

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
      // styling/메인 Pro 판정 — widget.isPro가 타이밍상 false로 들어올 수 있어 SubscriptionService로 재확인 (ResultScreen과 일관)
      _effectiveIsPro = widget.isPro || await SubscriptionService.isSubscribed();

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

      // 메인 호출과 동시에 styling 호출도 백그라운드로 시작 (Pro인 경우)
      // 메인 응답 도착하면 즉시 ResultScreen 진입, styling은 사용자가 페이지 swipe할 때까지 계속 진행
      Future<Map<String, dynamic>>? stylingFuture;
      if (_effectiveIsPro) {
        try {
          final imageBytes = await widget.primaryImage.readAsBytes();
          stylingFuture = ClaudeService.analyzeStyling(
            imageBytes: imageBytes,
            mimeType: 'image/jpeg',
            gender: widget.gender,
            faceData: faceData,
          ).catchError((e) {
            debugPrint('🟡 Styling 호출 실패 (메인은 OK): $e');
            return <String, dynamic>{};
          });
        } catch (e) {
          debugPrint('🟡 Styling 호출 시작 실패: $e');
        }
      }

      Map<String, dynamic> result;
      try {
        result = await _getAnalysisWithRetry(faceData);
        // ===== 디버그: Gemini 응답에서 핵심 필드 확인 =====
        final fi = result['first_impression'] as Map<String, dynamic>?;
        debugPrint('🟢 ML Kit current_face_type: ${faceData['current_face_type']}');
        debugPrint('🟢 ML Kit face_type_scores: ${faceData['face_type_scores']}');
        debugPrint('🟢 Gemini main_animal: ${fi?['main_animal']?['name']}');
        debugPrint('🟢 Gemini sub_animal: ${fi?['sub_animal']?['name']}');
        debugPrint('🟢 Gemini target_animal: ${fi?['target_animal']?['name']}');
        debugPrint('🟢 Gemini animal_match.percentage: ${fi?['animal_match']?['percentage']}');
        debugPrint('🟢 Gemini animal_distribution: ${fi?['animal_distribution']}');
        debugPrint('🟢 Gemini lookalike_celebs: ${fi?['lookalike_celebs']}');
        debugPrint('🔵 Gemini appearance_tier: ${fi?['appearance_tier']}');
        debugPrint('🔵 Gemini weaknesses count: ${(fi?['weaknesses'] as List?)?.length ?? "null"}');
        debugPrint('🔵 Gemini weaknesses sample: ${(fi?['weaknesses'] as List?)?.firstOrNull}');
        // =================================================
      } on _AnalysisException catch (e) {
        _timerController.stop();
        if (mounted) {
          final isMinor = e.code == 'minor_detected' || e.code == 'age_restriction';
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              title: Text(
                isMinor ? '이용 제한' : '사진 재업로드 필요',
                style: const TextStyle(color: Color(0xFFE8D5B7)),
              ),
              content: Text(e.message,
                  style: const TextStyle(color: Color(0xFFAAAAAA))),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // 다이얼로그
                    Navigator.pop(context, false); // 로딩화면
                  },
                  child: const Text('확인', style: TextStyle(color: Color(0xFFE8D5B7))),
                ),
              ],
            ),
          );
        }
        return;
      }

      // Step 4: 결과 생성 완료
      _timerController.stop();
      if (mounted) setState(() {
        _isGptPhase = false;
        _currentStep = _steps.length;
      });

      // 히스토리 저장 (백그라운드, 실패해도 무시)
      final currentType =
          faceData!['current_face_type']?.toString() ?? '강아지상';
      // animalType이 빈 경우(사용자 선택 제거됨) → Gemini 응답의 target_animal 사용,
      // 그것도 없으면 currentType과 동일 (변신 개념 약화 = 현재 매력 강화)
      final resolvedAnimalType = widget.animalType.isNotEmpty
          ? widget.animalType
          : ((result['first_impression']?['target_animal']?['name']
                      ?.toString() ??
                  '')
              .isNotEmpty
              ? result['first_impression']!['target_animal']!['name']!.toString()
              : currentType);
      final histId = await HistoryService.save(
        currentType: currentType,
        targetType: resolvedAnimalType,
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
              animalType: resolvedAnimalType,
              sliderValue: widget.sliderValue,
              analysisResult: result,
              imageFile: widget.primaryImage,
              faceData: faceData!,
              gender: widget.gender,
              stylingFuture: stylingFuture,
              historyId: histId,
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
    try {
      final imageBytes = await widget.primaryImage.readAsBytes();
      // animalType이 빈 경우(사용자 선택 제거됨) → ML Kit 자동 판정한 currentType 사용.
      // Gemini가 그 동물상의 매력 강화 + 자유로운 변신 방향 추천하도록.
      final currentType =
          faceData['current_face_type']?.toString() ?? '강아지상';
      final effectiveAnimalType =
          widget.animalType.isNotEmpty ? widget.animalType : currentType;
      final result = await ClaudeService.analyzeMain(
        imageBytes: imageBytes,
        mimeType: 'image/jpeg',
        animalType: effectiveAnimalType,
        gender: widget.gender,
        faceData: faceData,
        isPro: _effectiveIsPro,
      );
      debugPrint('🟢 Claude main response OK (${jsonEncode(result).length} chars)');
      return result;
    } on _AnalysisException {
      rethrow;
    } catch (e, st) {
      debugPrint('🔴 ClaudeService 에러: $e\n$st');
      // 쿼터 초과/네트워크 에러 등 — 가짜 fallback 반환 X, 사용자에게 알림
      final msg = e.toString().toLowerCase();
      if (msg.contains('quota') || msg.contains('rate limit')) {
        throw _AnalysisException(
          code: 'quota_exceeded',
          message: '오늘의 AI 분석 쿼터가 초과됐어요. 잠시 후 다시 시도해주세요.\n(개발자: Google Cloud 결제 활성화 필요)',
        );
      }
      throw _AnalysisException(
        code: 'api_error',
        message: '분석 중 오류가 발생했어요. 잠시 후 다시 시도해주세요.\n\n[디버그] ${e.toString().substring(0, e.toString().length.clamp(0, 300))}',
      );
    }
  }

  static String _animalEmoji(String name) {
    const map = {
      '강아지상': '🐶', '고양이상': '🐱', '여우상': '🦊',
      '사슴상': '🦌', '늑대상': '🐺', '토끼상': '🐰', '곰상': '🐻',
    };
    return map[name] ?? '✨';
  }

  Map<String, dynamic> _buildFallbackResponse() {
    final targetAnimal = widget.animalType;
    final targetEmoji = _animalEmoji(targetAnimal);
    const currentAnimal = '강아지상';
    const currentEmoji = '🐶';
    final genderLabel = widget.gender == 'female' ? '메이크업' : '그루밍';
    return {
      "first_impression": {
        "summary": "자연스럽고 친근한 인상이에요. 스타일링으로 충분히 달라질 수 있어요.",
        "face_shape": "계란형",
        "main_animal": {
          "name": currentAnimal,
          "emoji": currentEmoji,
          "keywords": ["부드러움", "친근함", "자연스러움"],
          "strengths": [
            {"title": "부드러운 인상", "description": "처음 본 사람도 편안하게 느끼는 매력이 있어요."},
            {"title": "친근한 분위기", "description": "쉽게 다가갈 수 있는 따뜻한 매력을 가지고 있어요."},
            {"title": "자연스러운 표정", "description": "꾸미지 않아도 매력적인 표정을 가지고 있어요."},
          ],
          "tip": "이 매력은 그대로 살리고 헤어와 스타일링을 더하는 방향이 효율적이에요.",
        },
        "sub_animal": {
          "name": "고양이상",
          "emoji": "🐱",
          "keywords": ["도도함", "신비로움"],
          "comment": "이 매력도 함께 가지고 있어요. 활용하면 입체적 인상이 나와요.",
        },
        "target_animal": {
          "name": targetAnimal,
          "emoji": targetEmoji,
          "keywords": ["세련됨", "정돈됨"],
          "comment": "스타일링으로 충분히 도달 가능한 목표예요.",
        },
        "animal_match": {
          "main": currentAnimal,
          "percentage": 82,
          "similarity_points": [
            "부드러운 눈매 라인이 친근하고 따뜻한 첫인상을 자연스럽게 만들어줘요.",
            "얼굴 전체 윤곽의 곡선감이 무해하고 편안한 느낌과 맞닿아 있어요.",
            "처음 보는 사람에게도 경계심 없이 다가갈 수 있는 인상 구조예요.",
          ],
        },
      },
      "comparison": {
        "current_animal": currentAnimal,
        "target_animal": widget.animalType,
        "current_keywords": ["부드러움", "친근함", "자연스러움"],
        "target_keywords": ["세련됨", "정돈됨", "또렷함"],
        "gap_percent": 45,
      },
      "radar": {
        "current": {"눈매": 0.5, "코": 0.5, "얼굴윤곽": 0.55, "스타일": 0.4},
        "target": {"눈매": 0.85, "코": 0.7, "얼굴윤곽": 0.75, "스타일": 0.85},
      },
      "consultant_report_simple": {
        "quote": "핵심은 눈매와 헤어에 있어요. 여기서 바뀌는 게 인상 전체를 바꿔줘요.",
        "gap": "눈매 샤프니스, 헤어 스타일링",
        "direction": "스타일링 중심 변화",
      },
      "consultant_report_full": {
        "quote": "핵심은 눈매와 스타일에 있어요. 여기서 바뀌는 게 인상 전체를 바꿔줘요.",
        "observation": "전반적으로 균형 잡힌 얼굴형에 부드러운 인상이 강점이에요.",
        "impact": "현재 스타일이 눈매의 날카로움을 가리고 있어요.",
        "gap": "눈매 샤프니스, 헤어 볼륨, 스타일링 완성도",
        "direction": "눈매 강조 + 헤어 스타일링 + 베이직 패션 정립",
      },
      "action_cards": [
        {
          "category": "헤어스타일",
          "principle": "레이어드로 옆선을 드러내는 게 핵심이에요. 현재 헤어가 얼굴 윤곽을 덮고 있어 인상이 묻히고 있어요.",
          "observation": "현재 헤어스타일이 얼굴 윤곽을 가리고 있어 인상이 다소 묻히고 있어요.",
          "impact": "볼륨감 없는 헤어가 얼굴을 더 둥글어 보이게 해요.",
          "change": "레이어드컷으로 옆선을 드러내고 앞머리를 정리하면 달라져요.",
          "result": "얼굴 윤곽이 살아나고 목선이 드러나 훨씬 또렷한 인상이 나와요.",
          "application": "핵심은 옆선이에요. 현재 헤어가 광대 라인을 덮고 있어서 인상이 묻히는 거거든요. 레이어드로 옆선을 드러내면 이 사람 얼굴형의 선이 살아나요.",
          "references": [
            {"name": "정해인", "context": "2021 달이 뜨는 강 촬영 현장 — 자연스럽게 흘러내린 앞머리로 이마를 살짝 드러낸 스타일. 이 사람과 비슷한 부드러운 인상에서 가르마를 활용한 레퍼런스", "description": "자연스러운 가르마와 레이어드로 얼굴 윤곽을 살린 스타일"},
          ],
        },
        {
          "category": "패션",
          "principle": "상하의 컬러 통일감이 스타일링 완성도를 가장 빠르게 올려줘요. 베이직 4색(검정·흰색·회색·네이비)으로 팔레트를 정립하세요.",
          "observation": "전체적인 스타일링 완성도를 높이면 인상이 한층 달라질 수 있어요.",
          "impact": "현재 스타일에서 체형의 장점이 잘 드러나지 않고 있어요.",
          "change": "세미와이드 팬츠와 원단감 있는 상의 조합이 효율적이에요.",
          "result": "하체 라인이 정돈되고 전체적인 실루엣이 세련되게 바뀌어요.",
          "application": "사실 이게 가장 중요한데요 — 색상 통일감이에요. 지금 상하의 컬러가 따로 노는데, 같은 톤 계열로 맞추면 전체적인 완성도가 확 올라가요.",
          "references": [
            {"name": "박보검", "context": "2022 유퀴즈 출연 — 네이비 셔츠에 그레이 슬렉스 조합. 이 사람과 비슷한 친근한 인상에서 포멀함을 더한 레퍼런스", "description": "베이직 컬러 조합으로 깔끔한 인상 연출"},
          ],
        },
        {
          "category": genderLabel,
          "observation": "눈썹 정리와 기초 그루밍이 전체 인상 변화의 핵심 포인트예요.",
          "principle": "눈썹 하나만 잡아도 인상이 완전히 달라져요. 나머지 스타일링보다 먼저 해야 할 가장 빠른 변화예요.",
          "impact": "정리되지 않은 눈썹이 인상을 흐리게 만들고 있어요.",
          "change": "눈썹 결을 따라 정리하고 아치를 살짝 잡아주면 달라져요.",
          "result": "눈매가 또렷해지고 전체 인상이 한층 정돈돼 보여요.",
          "application": "근데 이게 제일 빠른 변화예요 — 눈썹 하나만 잡아도 인상이 완전히 달라지거든요. 나머지 스타일링 다 안 해도 눈썹 먼저 잡으세요.",
          "references": [
            {"name": "위아이", "context": "2023 활동 당시 직캠 — 자연스러운 일자 눈썹으로 부드럽지만 또렷한 인상 연출", "description": "자연스러운 눈썹 정리로 또렷한 인상 완성"},
          ],
        },
      ],
      "three_factor": {
        "physical": "상체 라인을 살리는 핏감 있는 상의가 전체 실루엣을 정돈해줘요. 키높이 깔창으로 전체 비율도 보완할 수 있어요.",
        "face": "눈썹 정리가 첫 번째 우선순위예요. 그다음 앞머리 정리로 이마를 드러내면 눈매가 더 또렷해 보여요.",
        "fashion": "회색·검정·네이비·흰색 4가지 컬러로 기본 팔레트를 정립하세요. 상하의 컬러 통일감이 스타일링 완성도를 가장 빠르게 올려줘요.",
      },
      "makeup_steps": [
        {
          "step_number": 1,
          "step_name": "기초",
          "description": "묽은 제형부터 무거운 제형 순서로, 피부 결 따라 세로로 흡수시켜줘요.",
          "products": [
            {"name": "한율 부들밤 모공수축패드", "shade": null, "category": "토너패드", "usage": "세안 후 결 따라 닦아내기"},
            {"name": "라운드랩 1025 독도 토너", "shade": null, "category": "토너", "usage": "가볍게 두드려 흡수"},
          ],
          "tip": "기초는 레이어링이 핵심이에요. 각 단계 30초 간격으로 흡수시켜줘요.",
        },
        {
          "step_number": 2,
          "step_name": "베이스",
          "description": "피부 톤을 균일하게 잡아주는 단계예요.",
          "products": [
            {"name": "비레디 블루 파운데이션 03호", "shade": "03호", "category": "파운데이션", "usage": "소량을 전체적으로 가볍게 펴바르기"},
            {"name": "스킨푸드 피치뽀송 멀티 피니시 파우더", "shade": null, "category": "파우더", "usage": "T존 중심으로 살짝 눌러 마무리"},
          ],
          "tip": "포인트는 소량이에요. 티 안 나게 자연스럽게 얹어주는 게 핵심이에요.",
        },
        {
          "step_number": 3,
          "step_name": "눈썹 + 음영",
          "description": "눈썹 먼저, 그다음 쉐딩 순서로 진행해요.",
          "products": [
            {"name": "클리오 킬브로우 오토하드펜슬 05호", "shade": "05호 그레이브라운", "category": "눈썹", "usage": "눈썹 결 따라 그린 후 스크류로 빗어주기"},
            {"name": "투쿨포스쿨 뉴트럴 쉐딩", "shade": null, "category": "쉐딩", "usage": "얼굴 윤곽 바깥쪽에만 살짝 블렌딩"},
          ],
          "tip": "쉐딩은 얼굴 윤곽 바깥쪽에만 살짝. 과하면 어색해 보여요.",
        },
        {
          "step_number": 4,
          "step_name": "마무리",
          "description": "파우더와 픽서로 지속력을 확보해줘요.",
          "products": [
            {"name": "스킨푸드 피치뽀송 멀티 피니시 파우더", "shade": null, "category": "세팅파우더", "usage": "전체적으로 가볍게 눌러 세팅"},
            {"name": "어반디케이 메이크업 픽서", "shade": null, "category": "픽서", "usage": "20cm 거리에서 가볍게 두 번 분사"},
          ],
          "tip": "픽서는 20cm 거리에서 가볍게 두 번. 하루 종일 지속돼요.",
        },
      ],
      "fashion_looks": [
        {
          "name": "데일리 베이직",
          "items": [
            {"category": "Outer", "description": "화이트 린넨 오버핏 셔츠", "rationale": "청량감 + 레이어드"},
            {"category": "Top", "description": "화이트 반팔 코튼 이너", "rationale": "정돈된 레이어드"},
            {"category": "Bottom", "description": "와이드 연청 데님 팬츠", "rationale": "하체 라인 정돈"},
            {"category": "Shoes", "description": "화이트 로우 스니커즈", "rationale": "색감 통일"},
            {"category": "Acc", "description": "검정 가죽 벨트 (슬림)", "rationale": "포인트 + 허리 라인"},
          ],
          "rationale": "셔츠는 빼서 입고, 이너는 넣어서 입어요. 화이트+연청 조합으로 청량감 있어요.",
          "styling_tip": "셔츠는 빼서, 이너는 넣어서",
          "color_palette": ["#FFFFFF", "#A8C5DA", "#000000"],
        },
        {
          "name": "세미 포멀",
          "items": [
            {"category": "Outer", "description": "검정 반팔 셔츠 (레귤러 핏)", "rationale": "깔끔하고 정돈된 인상"},
            {"category": "Top", "description": "검정 이너 (넣어 입기용)", "rationale": "셔츠 넣입 깔끔하게"},
            {"category": "Bottom", "description": "회색 세미와이드 슬랙스", "rationale": "정돈된 라인"},
            {"category": "Shoes", "description": "앵클부츠 (키높이 깔창)", "rationale": "키 보정 + 포멀한 인상"},
            {"category": "Acc", "description": "검정 가죽 벨트", "rationale": "상하의 통일감"},
          ],
          "rationale": "검정 셔츠 넣어 입기로 깔끔하게. 회색 와이드로 하체 비율 보완이 효율적이에요.",
          "styling_tip": "검정 셔츠는 꼭 넣어서",
          "color_palette": ["#000000", "#808080", "#1A1A1A"],
        },
      ],
      "color_palette": {
        "main": ["#000000", "#1A2238", "#FFFFFF"],
        "accent": ["#722F37", "#C19A6B"],
        "avoid": ["#FF00FF", "#FFFF00"],
      },
    };
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