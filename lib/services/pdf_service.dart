import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class PdfService {
  static Future<void> generateAndOpen(
      Map<String, dynamic> analysisResult) async {
    // 한글 폰트 로드 (NotoSansKR)
    final fontRegular = await PdfGoogleFonts.notoSansKRRegular();
    final fontBold = await PdfGoogleFonts.notoSansKRBold();

    final theme = pw.ThemeData.withFont(base: fontRegular, bold: fontBold);

    final pdf = pw.Document();

    final report = analysisResult['consultant_report_full'] as Map<String, dynamic>?
        ?? analysisResult['consultant_report_simple'] as Map<String, dynamic>?;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        theme: theme,
        build: (context) => [
          // 헤더
          pw.Text('Apex Aura 분석 리포트',
              style: pw.TextStyle(font: fontBold, fontSize: 24, color: PdfColors.grey800)),
          pw.SizedBox(height: 4),
          pw.Text('AI 기반 스타일링 컨설팅 리포트',
              style: pw.TextStyle(font: fontRegular, fontSize: 11, color: PdfColors.grey500)),
          pw.Divider(thickness: 1.5, color: PdfColors.grey300),
          pw.SizedBox(height: 16),

          // 첫인상
          _section('첫인상',
            analysisResult['first_impression']?['summary']?.toString()
              ?? analysisResult['current_impression']?.toString() ?? '',
            fontBold, fontRegular),
          pw.SizedBox(height: 12),

          // 컨설턴트 리포트
          if (report != null) ...[
            _section('컨설턴트 리포트', report['quote']?.toString() ?? '', fontBold, fontRegular),
            if (report['observation'] != null)
              _bulletRow('관찰', report['observation'].toString(), fontBold, fontRegular),
            if (report['gap'] != null)
              _bulletRow('갭', report['gap'].toString(), fontBold, fontRegular),
            if (report['direction'] != null)
              _bulletRow('방향', report['direction'].toString(), fontBold, fontRegular),
            pw.SizedBox(height: 12),
          ],

          // 외모 점수 (Pro)
          if (analysisResult['appearance_score'] != null) ...[
            _section('스타일 완성도',
              '현재: ${analysisResult['appearance_score']['score']} / 10  '
              '→ 최적화 시: ${analysisResult['appearance_score']['optimized_limit']}',
              fontBold, fontRegular),
            pw.SizedBox(height: 12),
          ],

          // 액션 카드
          _section('스타일링 가이드', '', fontBold, fontRegular),
          ...((analysisResult['action_cards'] as List? ?? []).map((card) {
            final c = card as Map<String, dynamic>;
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(c['category']?.toString() ?? '',
                    style: pw.TextStyle(font: fontBold, fontSize: 12)),
                pw.Text(c['application']?.toString() ?? '',
                    style: pw.TextStyle(font: fontRegular, fontSize: 11)),
                pw.SizedBox(height: 8),
              ],
            );
          })),

          // 메이크업 (Pro)
          if (analysisResult['makeup_steps'] != null) ...[
            pw.SizedBox(height: 8),
            _section('메이크업 4단계', '', fontBold, fontRegular),
            ...((analysisResult['makeup_steps'] as List).map((step) {
              final s = step as Map<String, dynamic>;
              final products = (s['products'] as List? ?? []);
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Step ${s['step_number']} — ${s['step_name']}',
                      style: pw.TextStyle(font: fontBold, fontSize: 12)),
                  pw.Text(s['description']?.toString() ?? '',
                      style: pw.TextStyle(font: fontRegular, fontSize: 11)),
                  ...products.map((p) {
                    final pm = p as Map<String, dynamic>;
                    return pw.Text(
                      '  • ${pm['name']}${pm['shade'] != null ? " (${pm['shade']})" : ""}',
                      style: pw.TextStyle(font: fontRegular, fontSize: 10, color: PdfColors.grey700),
                    );
                  }),
                  if (s['tip'] != null)
                    pw.Text('TIP: ${s['tip']}',
                        style: pw.TextStyle(font: fontRegular, fontSize: 10, color: PdfColors.orange700)),
                  pw.SizedBox(height: 8),
                ],
              );
            })),
          ],

          // 패션 룩 (Pro)
          if (analysisResult['fashion_looks'] != null) ...[
            pw.SizedBox(height: 8),
            _section('패션 룩', '', fontBold, fontRegular),
            ...((analysisResult['fashion_looks'] as List).map((look) {
              final l = look as Map<String, dynamic>;
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(l['name']?.toString() ?? '',
                      style: pw.TextStyle(font: fontBold, fontSize: 12)),
                  pw.Text(l['rationale']?.toString() ?? '',
                      style: pw.TextStyle(font: fontRegular, fontSize: 11)),
                  pw.SizedBox(height: 8),
                ],
              );
            })),
          ],

          // 푸터
          pw.SizedBox(height: 24),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 4),
          pw.Text(
            '이 리포트는 쿠팡 파트너스 활동의 일환으로 제품을 추천합니다.',
            style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.grey500),
          ),
          pw.Text(
            'Generated by Apex Aura  |  apex-aura-ae223',
            style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.grey400),
          ),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/apex_aura_report.pdf');
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }

  static pw.Widget _section(String title, String content,
      pw.Font fontBold, pw.Font fontRegular) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title,
            style: pw.TextStyle(font: fontBold, fontSize: 13, color: PdfColors.grey800)),
        pw.SizedBox(height: 3),
        if (content.isNotEmpty)
          pw.Text(content, style: pw.TextStyle(font: fontRegular, fontSize: 11)),
        pw.Divider(color: PdfColors.grey200),
      ],
    );
  }

  static pw.Widget _bulletRow(String label, String content,
      pw.Font fontBold, pw.Font fontRegular) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 48,
            child: pw.Text(label,
                style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.grey600)),
          ),
          pw.Expanded(
            child: pw.Text(content,
                style: pw.TextStyle(font: fontRegular, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
