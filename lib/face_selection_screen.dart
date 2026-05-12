import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math';
import 'loading_screen.dart';

class FaceSelectionScreen extends StatefulWidget {
  final File imageFile;
  final String animalType;
  final double sliderValue;
  final List<Rect> faceBoxes;
  final Size imageSize;
  final List<File> allImageFiles;
  final String gender;

  const FaceSelectionScreen({
    super.key,
    required this.imageFile,
    required this.animalType,
    required this.sliderValue,
    required this.faceBoxes,
    required this.imageSize,
    required this.allImageFiles,
    this.gender = 'male',
  });

  @override
  State<FaceSelectionScreen> createState() => _FaceSelectionScreenState();
}

class _FaceSelectionScreenState extends State<FaceSelectionScreen> {
  int? _selectedIndex;

  void _onTap(TapDownDetails details, Size displaySize) {
    final scale = max(displaySize.width / widget.imageSize.width,
        displaySize.height / widget.imageSize.height);
    final ox = (displaySize.width - widget.imageSize.width * scale) / 2;
    final oy = (displaySize.height - widget.imageSize.height * scale) / 2;

    // 탭 위치 → 이미지 좌표로 변환
    final imgX = (details.localPosition.dx - ox) / scale;
    final imgY = (details.localPosition.dy - oy) / scale;

    for (int i = 0; i < widget.faceBoxes.length; i++) {
      final box = widget.faceBoxes[i].inflate(20); // 터치 여유
      if (box.contains(Offset(imgX, imgY))) {
        setState(() => _selectedIndex = i);
        return;
      }
    }
  }

  void _confirm() {
    if (_selectedIndex == null) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LoadingScreen(
          animalType: widget.animalType,
          sliderValue: widget.sliderValue,
          imageFiles: widget.allImageFiles,
          faceIndex: _selectedIndex!,
          gender: widget.gender,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios, size: 18, color: Color(0xFF888888)),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('분석할 얼굴 선택',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFF0F0F0))),
                        SizedBox(height: 2),
                        Text('얼굴을 탭해서 선택하세요',
                            style: TextStyle(fontSize: 11, color: Color(0xFF555555))),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 이미지 + 얼굴 선택 영역
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final displaySize = Size(constraints.maxWidth, constraints.maxHeight);
                      return GestureDetector(
                        onTapDown: (d) => _onTap(d, displaySize),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(widget.imageFile, fit: BoxFit.cover),
                            CustomPaint(
                              painter: _FaceBoxPainter(
                                faceBoxes: widget.faceBoxes,
                                imageSize: widget.imageSize,
                                selectedIndex: _selectedIndex,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // 하단 안내 + 버튼
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (_selectedIndex == null)
                    const Text(
                      '👆 분석할 얼굴을 탭해주세요',
                      style: TextStyle(fontSize: 13, color: Color(0xFF666666)),
                    )
                  else
                    Text(
                      '${_selectedIndex! + 1}번 얼굴 선택됨',
                      style: const TextStyle(fontSize: 13, color: Color(0xFFE8D5B7)),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _selectedIndex != null ? _confirm : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE8D5B7),
                        disabledBackgroundColor: const Color(0xFF2A2A2A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text(
                        '이 얼굴 분석하기',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _selectedIndex != null ? const Color(0xFF1A0F00) : const Color(0xFF444444),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaceBoxPainter extends CustomPainter {
  final List<Rect> faceBoxes;
  final Size imageSize;
  final int? selectedIndex;

  _FaceBoxPainter({required this.faceBoxes, required this.imageSize, required this.selectedIndex});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = max(size.width / imageSize.width, size.height / imageSize.height);
    final ox = (size.width - imageSize.width * scale) / 2;
    final oy = (size.height - imageSize.height * scale) / 2;

    Rect toDisplay(Rect r) => Rect.fromLTRB(
      r.left * scale + ox,
      r.top * scale + oy,
      r.right * scale + ox,
      r.bottom * scale + oy,
    );

    for (int i = 0; i < faceBoxes.length; i++) {
      final isSelected = i == selectedIndex;
      final displayRect = toDisplay(faceBoxes[i]);

      // 반투명 오버레이 (선택 안된 경우)
      if (!isSelected) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(displayRect, const Radius.circular(8)),
          Paint()..color = Colors.black.withAlpha(80),
        );
      }

      // 바운딩박스
      canvas.drawRRect(
        RRect.fromRectAndRadius(displayRect, const Radius.circular(8)),
        Paint()
          ..color = isSelected ? const Color(0xFFE8D5B7) : const Color(0xFF888888)
          ..strokeWidth = isSelected ? 2.5 : 1.5
          ..style = PaintingStyle.stroke,
      );

      // 번호 레이블
      final labelRect = Rect.fromLTWH(
        displayRect.left, displayRect.top - 26, 28, 22,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(labelRect, const Radius.circular(6)),
        Paint()
          ..color = isSelected ? const Color(0xFFE8D5B7) : const Color(0xFF333333)
          ..style = PaintingStyle.fill,
      );

      final tp = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? const Color(0xFF1A0F00) : const Color(0xFFAAAAAA),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(
        labelRect.left + (labelRect.width - tp.width) / 2,
        labelRect.top + (labelRect.height - tp.height) / 2,
      ));
    }
  }

  @override
  bool shouldRepaint(_FaceBoxPainter old) => old.selectedIndex != selectedIndex;
}
