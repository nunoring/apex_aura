import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

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
          // 헤더
          Row(
            children: const [
              Icon(Icons.star_outline, size: 14, color: Color(0xFFE8A030)),
              SizedBox(width: 6),
              Text('닮은꼴 셀럽',
                  style: TextStyle(fontSize: 12, color: Color(0xFFE8A030), fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 14),

          // 비교 카드 (사용자 | 셀럽)
          Row(
            children: [
              // 사용자 사진
              Expanded(
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        userImage,
                        height: 110,
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

              // 가운데 VS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1500),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('≈',
                          style: TextStyle(fontSize: 18, color: Color(0xFFE8A030), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              // 셀럽 영역 (사진 없이 이름+검색)
              Expanded(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => _searchCeleb(main['name'] as String),
                      child: Container(
                        height: 110,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFFE8D5B7).withAlpha(60), width: 0.5),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search,
                                size: 24, color: Color(0xFFE8D5B7)),
                            const SizedBox(height: 6),
                            Text(
                              main['name'] as String,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFFE8D5B7),
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 3),
                            const Text('탭해서 보기',
                                style: TextStyle(fontSize: 9, color: Color(0xFF666666))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(main['name'] as String,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 유사 포인트
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
                Text(
                  '${main['trait']} 유사 · ${main['work']}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
                ),
              ],
            ),
          ),

          // 다른 셀럽들
          if (celebs.length > 1) ...[
            const SizedBox(height: 12),
            const Text('같은 동물상 셀럽',
                style: TextStyle(fontSize: 10, color: Color(0xFF555555))),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: celebs.skip(1).map((c) => GestureDetector(
                onTap: () => _searchCeleb(c['name'] as String),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF2A2A2A), width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(c['name'] as String,
                          style: const TextStyle(fontSize: 11, color: Color(0xFFCCCCCC))),
                      const SizedBox(width: 4),
                      const Icon(Icons.open_in_new, size: 10, color: Color(0xFF666666)),
                    ],
                  ),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  void _searchCeleb(String name) {
    final query = Uri.encodeComponent('$name 얼굴');
    launchUrl(
      Uri.parse('https://search.naver.com/search.naver?where=image&query=$query'),
      mode: LaunchMode.externalApplication,
    );
  }
}
