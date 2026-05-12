// flutter run -d windows tool/generate_icon.dart
// → assets/icon/app_icon.png 생성
import 'dart:ui' as ui;
import 'dart:io';

Future<void> main() async {
  const size = 1024.0;
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);

  // 배경 (다크)
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, size, size),
    ui.Paint()..color = const ui.Color(0xFF0D0D0D),
  );

  // 배경 원형 그라디언트
  final bgPaint = ui.Paint()
    ..shader = ui.Gradient.radial(
      ui.Offset(size / 2, size / 2),
      size * 0.55,
      [const ui.Color(0xFF1A1500), const ui.Color(0xFF0D0D0D)],
    );
  canvas.drawCircle(ui.Offset(size / 2, size / 2), size * 0.5, bgPaint);

  // 얼굴 윤곽 타원
  final facePaint = ui.Paint()
    ..color = const ui.Color(0xFFE8D5B7).withOpacity(0.9)
    ..strokeWidth = size * 0.018
    ..style = ui.PaintingStyle.stroke;
  canvas.drawOval(
    ui.Rect.fromCenter(
      center: ui.Offset(size / 2, size * 0.52),
      width: size * 0.36,
      height: size * 0.48,
    ),
    facePaint,
  );

  // 스캔 라인 (가로 3개)
  final scanPaint = ui.Paint()
    ..color = const ui.Color(0xFFE8A030).withOpacity(0.6)
    ..strokeWidth = size * 0.008;
  final faceLeft = size * 0.25;
  final faceRight = size * 0.75;
  for (final y in [size * 0.38, size * 0.52, size * 0.66]) {
    canvas.drawLine(
      ui.Offset(faceLeft, y), ui.Offset(faceRight, y), scanPaint);
  }

  // 스캔 세로선 (중앙)
  final scanVPaint = ui.Paint()
    ..color = const ui.Color(0xFFE8A030).withOpacity(0.3)
    ..strokeWidth = size * 0.006;
  canvas.drawLine(
    ui.Offset(size / 2, size * 0.26),
    ui.Offset(size / 2, size * 0.78),
    scanVPaint,
  );

  // 눈 점 (좌우)
  final dotPaint = ui.Paint()
    ..color = const ui.Color(0xFFE8A030);
  canvas.drawCircle(ui.Offset(size * 0.42, size * 0.46), size * 0.022, dotPaint);
  canvas.drawCircle(ui.Offset(size * 0.58, size * 0.46), size * 0.022, dotPaint);

  // 코 점
  canvas.drawCircle(ui.Offset(size / 2, size * 0.56), size * 0.016,
    ui.Paint()..color = const ui.Color(0xFFE8D5B7).withOpacity(0.7));

  // 코너 마커 (4개)
  final cornerPaint = ui.Paint()
    ..color = const ui.Color(0xFFE8D5B7)
    ..strokeWidth = size * 0.02
    ..style = ui.PaintingStyle.stroke
    ..strokeCap = ui.StrokeCap.square;
  const m = 180.0; // margin
  const l = 80.0;  // line length
  // TL
  canvas.drawLine(ui.Offset(m, m + l), ui.Offset(m, m), cornerPaint);
  canvas.drawLine(ui.Offset(m, m), ui.Offset(m + l, m), cornerPaint);
  // TR
  canvas.drawLine(ui.Offset(size - m - l, m), ui.Offset(size - m, m), cornerPaint);
  canvas.drawLine(ui.Offset(size - m, m), ui.Offset(size - m, m + l), cornerPaint);
  // BL
  canvas.drawLine(ui.Offset(m, size - m - l), ui.Offset(m, size - m), cornerPaint);
  canvas.drawLine(ui.Offset(m, size - m), ui.Offset(m + l, size - m), cornerPaint);
  // BR
  canvas.drawLine(ui.Offset(size - m - l, size - m), ui.Offset(size - m, size - m), cornerPaint);
  canvas.drawLine(ui.Offset(size - m, size - m), ui.Offset(size - m, size - m - l), cornerPaint);

  final picture = recorder.endRecording();
  final img = await picture.toImage(size.toInt(), size.toInt());
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  final bytes = byteData!.buffer.asUint8List();

  final file = File('assets/icon/app_icon.png');
  await file.writeAsBytes(bytes);
  print('아이콘 생성 완료: ${file.path}');
}
