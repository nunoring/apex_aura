import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AffiliateChip extends StatelessWidget {
  final String name;
  final String url;
  final String platform;

  const AffiliateChip({
    super.key,
    required this.name,
    required this.url,
    required this.platform,
  });

  Future<void> _open() async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _open,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            const Icon(Icons.shopping_bag_outlined,
                color: Color(0xFFE8D5B7), size: 16),
            const SizedBox(width: 8),
            Expanded(
                child: Text(name,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13))),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color:
                    const Color(0xFFE8D5B7).withAlpha(38),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(platform,
                  style: const TextStyle(
                      color: Color(0xFFE8D5B7), fontSize: 11)),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.open_in_new,
                color: Colors.white38, size: 14),
          ],
        ),
      ),
    );
  }
}
