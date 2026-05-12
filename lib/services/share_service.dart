import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/material.dart';

class ShareService {
  // RepaintBoundary key로 위젯 캡처 후 갤러리 저장 + 공유
  static Future<void> shareCard(GlobalKey repaintKey) async {
    try {
      final boundary = repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();

      // 임시 파일로 저장
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/apex_aura_share.png');
      await file.writeAsBytes(bytes);

      // 갤러리 저장
      await Gal.putImage(file.path, album: 'Apex Aura');

      // 시스템 공유
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Apex Aura로 외모 분석했어요 🦊\n#ApexAura #이미지컨설팅',
      );
    } catch (e) {
      debugPrint('ShareService error: $e');
    }
  }
}
