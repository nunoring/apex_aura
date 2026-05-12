import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'dart:math';

class CameraGuideScreen extends StatefulWidget {
  const CameraGuideScreen({super.key});

  // 촬영 완료 후 File 반환
  static Future<File?> capture(BuildContext context) async {
    return await Navigator.push<File>(
      context,
      MaterialPageRoute(builder: (_) => const CameraGuideScreen()),
    );
  }

  @override
  State<CameraGuideScreen> createState() => _CameraGuideScreenState();
}

class _CameraGuideScreenState extends State<CameraGuideScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isReady = false;
  bool _isFaceAligned = false;
  bool _isCapturing = false;
  String _hint = '카메라를 얼굴에 맞춰주세요';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      // 전면 카메라 우선 선택
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _controller = CameraController(
        front,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await _controller!.initialize();
      if (mounted) setState(() => _isReady = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('카메라를 열 수 없어요: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller!.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  // 간단한 얼굴 정렬 체크 (실제 ML Kit 없이 화면 중앙 터치 기반)
  void _checkAlignment(bool aligned) {
    if (_isFaceAligned == aligned) return;
    setState(() {
      _isFaceAligned = aligned;
      _hint = aligned ? '완벽해요! 버튼을 눌러 촬영하세요 ✓' : '타원 안에 얼굴을 맞춰주세요';
    });
  }

  Future<void> _capture() async {
    if (_isCapturing || _controller == null) return;
    setState(() => _isCapturing = true);
    try {
      final xFile = await _controller!.takePicture();
      if (mounted) Navigator.pop(context, File(xFile.path));
    } catch (e) {
      if (mounted) {
        setState(() => _isCapturing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('촬영에 실패했어요. 다시 시도해주세요.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: !_isReady
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE8D5B7)))
          : Stack(
              fit: StackFit.expand,
              children: [
                // 카메라 프리뷰
                CameraPreview(_controller!),

                // 가이드 오버레이
                CustomPaint(
                  painter: _FaceGuidePainter(aligned: _isFaceAligned),
                ),

                // 상단 힌트 + 뒤로
                Positioned(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: 0, right: 0,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black45,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.arrow_back_ios,
                                    color: Colors.white, size: 18),
                              ),
                            ),
                            const Spacer(),
                            const Text('APEX AURA',
                                style: TextStyle(
                                    color: Color(0xFFE8D5B7),
                                    fontSize: 12,
                                    letterSpacing: 2,
                                    fontWeight: FontWeight.w600)),
                            const Spacer(),
                            const SizedBox(width: 36),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _hint,
                          style: TextStyle(
                            color: _isFaceAligned
                                ? const Color(0xFF27AE60)
                                : const Color(0xFFE8D5B7),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 촬영 확인 감지 영역 (타원 중앙 터치 영역)
                Positioned.fill(
                  child: GestureDetector(
                    onTapDown: (_) => _checkAlignment(true),
                    onTapUp: (_) => _checkAlignment(false),
                    onTapCancel: () => _checkAlignment(false),
                    child: const ColoredBox(color: Colors.transparent),
                  ),
                ),

                // 하단 촬영 버튼 + 가이드
                Positioned(
                  bottom: MediaQuery.of(context).padding.bottom + 30,
                  left: 0, right: 0,
                  child: Column(
                    children: [
                      // 촬영 팁
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 40),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.info_outline,
                                size: 12, color: Color(0xFF888888)),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                '정면 · 밝은 조명 · 무표정 권장',
                                style: TextStyle(
                                    fontSize: 11, color: Color(0xFF888888)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // 촬영 버튼
                      GestureDetector(
                        onTap: _isCapturing ? null : _capture,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isCapturing
                                ? Colors.grey
                                : const Color(0xFFE8D5B7),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE8D5B7).withAlpha(80),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: _isCapturing
                              ? const Padding(
                                  padding: EdgeInsets.all(20),
                                  child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: Colors.black54),
                                )
                              : const Icon(Icons.camera_alt,
                                  color: Color(0xFF1A0F00), size: 32),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _FaceGuidePainter extends CustomPainter {
  final bool aligned;
  _FaceGuidePainter({required this.aligned});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 - size.height * 0.05;
    final ow = size.width * 0.58;
    final oh = ow * 1.35;

    final ovalRect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: ow,
      height: oh,
    );

    // 어두운 오버레이 (타원 밖)
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(ovalRect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(
      path,
      Paint()..color = Colors.black.withAlpha(140),
    );

    // 타원 테두리
    final borderColor = aligned
        ? const Color(0xFF27AE60)
        : const Color(0xFFE8D5B7);
    canvas.drawOval(
      ovalRect,
      Paint()
        ..color = borderColor
        ..strokeWidth = aligned ? 3.5 : 2.0
        ..style = PaintingStyle.stroke,
    );

    // 코너 가이드 마커 (위/아래 중앙)
    final markerPaint = Paint()
      ..color = borderColor.withAlpha(200)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const ml = 18.0; // marker line length

    // 상단 중앙
    canvas.drawLine(
        Offset(cx - ml, ovalRect.top), Offset(cx + ml, ovalRect.top), markerPaint);
    // 하단 중앙
    canvas.drawLine(
        Offset(cx - ml, ovalRect.bottom), Offset(cx + ml, ovalRect.bottom), markerPaint);
    // 좌측 중앙
    canvas.drawLine(
        Offset(ovalRect.left, cy - ml), Offset(ovalRect.left, cy + ml), markerPaint);
    // 우측 중앙
    canvas.drawLine(
        Offset(ovalRect.right, cy - ml), Offset(ovalRect.right, cy + ml), markerPaint);

    // 정렬됐을 때 체크 표시
    if (aligned) {
      final checkPaint = Paint()
        ..color = const Color(0xFF27AE60)
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final checkPath = Path()
        ..moveTo(cx - 16, cy - size.height * 0.18)
        ..lineTo(cx - 4, cy - size.height * 0.18 + 14)
        ..lineTo(cx + 18, cy - size.height * 0.18 - 10);
      canvas.drawPath(checkPath, checkPaint);
    }

    // 눈/코 위치 가이드 점 (희미하게)
    final dotPaint = Paint()
      ..color = borderColor.withAlpha(50)
      ..style = PaintingStyle.fill;
    final eyeY = cy - oh * 0.12;
    final eyeX = ow * 0.18;
    canvas.drawCircle(Offset(cx - eyeX, eyeY), 4, dotPaint);
    canvas.drawCircle(Offset(cx + eyeX, eyeY), 4, dotPaint);
    canvas.drawCircle(Offset(cx, cy + oh * 0.06), 3, dotPaint);
  }

  @override
  bool shouldRepaint(_FaceGuidePainter old) => old.aligned != aligned;
}
