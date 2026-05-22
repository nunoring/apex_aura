import 'package:flutter/material.dart';
import 'dart:io';
import '../services/tmdb_service.dart';

class CelebMatchCard extends StatelessWidget {
  final File userImage;
  final String animalName;
  final String gender;
  final List<Map<String, dynamic>> celebs;

  const CelebMatchCard({
    super.key,
    required this.userImage,
    required this.animalName,
    required this.gender,
    required this.celebs,
  });

  @override
  Widget build(BuildContext context) {
    if (celebs.isEmpty) return const SizedBox.shrink();
    final main = celebs[0];
    final extras = celebs.length > 1 ? celebs.sublist(1) : <Map<String, dynamic>>[];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8D5B7).withAlpha(40), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.star_outline, size: 14, color: Color(0xFFE8A030)),
              SizedBox(width: 6),
              Text('닮은꼴 셀럽',
                  style: TextStyle(fontSize: 12, color: Color(0xFFE8A030), fontWeight: FontWeight.w600)),
              SizedBox(width: 8),
              Text('AI 얼굴 분석 기반',
                  style: TextStyle(fontSize: 9, color: Color(0xFF555555))),
            ],
          ),
          const SizedBox(height: 14),

          // 메인 비교 카드 (나 vs 셀럽 1순위)
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        userImage,
                        height: 130,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text('나',
                        style: TextStyle(fontSize: 11, color: Color(0xFF888888))),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1500),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('≈',
                      style: TextStyle(fontSize: 18, color: Color(0xFFE8A030), fontWeight: FontWeight.bold)),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    _CelebPhoto(name: main['name'] as String, height: 130),
                    const SizedBox(height: 6),
                    Text(main['name'] as String,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFFE8D5B7), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 닮은 점 설명
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F0F),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.link, size: 12, color: Color(0xFFE8A030)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _formatTrait(main),
                    style: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA), height: 1.4),
                  ),
                ),
              ],
            ),
          ),

          // 위키미디어 attribution (CC BY-SA 요구사항)
          const SizedBox(height: 8),
          const Text('셀럽 사진 © 위키미디어 커먼즈 (CC BY-SA)',
              style: TextStyle(fontSize: 8, color: Color(0xFF444444))),

          // 보조 셀럽 (2~3순위) — 세로형 박스로 얼굴 잘림 최소화
          if (extras.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text('또 다른 닮은꼴',
                style: TextStyle(fontSize: 10, color: Color(0xFF666666))),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: extras
                  .take(2)
                  .map((c) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                              right: extras.indexOf(c) == 0 ? 6 : 0,
                              left: extras.indexOf(c) == 1 ? 6 : 0),
                          child: Column(
                            children: [
                              _CelebPhoto(name: c['name'] as String, height: 150),
                              const SizedBox(height: 4),
                              Text(c['name'] as String,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 11, color: Color(0xFFCCCCCC))),
                              if (c['work'] != null)
                                Text(c['work'].toString(),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 9, color: Color(0xFF555555))),
                            ],
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTrait(Map<String, dynamic> celeb) {
    final trait = celeb['trait']?.toString() ?? '';
    final work = celeb['work']?.toString() ?? '';
    if (trait.isEmpty && work.isEmpty) return '';
    if (trait.isEmpty) return work;
    if (work.isEmpty) return trait;
    return '$trait · $work';
  }
}

class _CelebPhoto extends StatelessWidget {
  final String name;
  final double height;

  const _CelebPhoto({required this.name, required this.height});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: FutureBuilder<String?>(
        future: TmdbService.fetchPhotoUrl(name),
        builder: (context, snapshot) {
          final url = snapshot.data;
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _placeholder(name, loading: true);
          }
          if (url == null || url.isEmpty) {
            return _placeholder(name);
          }
          // 얼굴 잘림 최소화: 위쪽 정렬 강화 (인물 사진은 보통 얼굴이 위쪽 1/3)
          const align = Alignment(0, -0.85);
          final image = url.startsWith('assets/')
              ? Image.asset(url,
                  height: height, width: double.infinity, fit: BoxFit.cover,
                  alignment: align,
                  errorBuilder: (_, __, ___) => _placeholder(name))
              : Image.network(url,
                  height: height, width: double.infinity, fit: BoxFit.cover,
                  alignment: align,
                  errorBuilder: (_, __, ___) => _placeholder(name));
          return GestureDetector(
            onTap: () => _showFullscreen(context, url),
            child: image,
          );
        },
      ),
    );
  }

  void _showFullscreen(BuildContext context, String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(230),
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.pop(ctx),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: url.startsWith('assets/')
                    ? Image.asset(url, fit: BoxFit.contain)
                    : Image.network(url, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 40, right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            Positioned(
              bottom: 40, left: 0, right: 0,
              child: Text(name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(String label, {bool loading = false}) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border.all(color: const Color(0xFF2A2A2A), width: 0.5),
      ),
      child: Center(
        child: loading
            ? const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 1.5, color: Color(0xFF555555)))
            : Padding(
                padding: const EdgeInsets.all(8),
                child: Text(label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
              ),
      ),
    );
  }
}
