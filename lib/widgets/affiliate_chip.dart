import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../services/affiliate_service.dart';

class AffiliateChip extends StatefulWidget {
  final String name;
  final String platform;
  final String? staticUrl;
  // 구버전 호환 — url 파라미터를 staticUrl로 전달
  final String? url;

  const AffiliateChip({
    super.key,
    required this.name,
    this.platform = 'coupang',
    this.staticUrl,
    this.url,
  });

  @override
  State<AffiliateChip> createState() => _AffiliateChipState();
}

class _AffiliateChipState extends State<AffiliateChip> {
  String _url = '';

  @override
  void initState() {
    super.initState();
    _loadUrl();
  }

  Future<void> _loadUrl() async {
    // 직접 전달된 URL 우선
    final direct = widget.staticUrl ?? widget.url ?? '';
    if (direct.isNotEmpty) {
      setState(() => _url = direct);
      return;
    }
    // Firestore에서 조회
    final url = await AffiliateService.getUrl(
      widget.name,
      platform: widget.platform,
    );
    if (mounted) setState(() => _url = url);
  }

  Future<void> _open() async {
    if (_url.isEmpty) return;

    try {
      await FirebaseAnalytics.instance.logEvent(
        name: 'affiliate_click',
        parameters: {'platform': widget.platform, 'product_name': widget.name},
      );
    } catch (_) {}

    final uri = Uri.parse(_url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _url.isNotEmpty ? _open : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _url.isNotEmpty ? Colors.white24 : Colors.white12,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.shopping_bag_outlined,
                color: Color(0xFFE8D5B7), size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(widget.name,
                  style: TextStyle(
                    color: _url.isNotEmpty ? Colors.white : Colors.white38,
                    fontSize: 13,
                  )),
            ),
            if (_url.isNotEmpty) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8D5B7).withAlpha(38),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(widget.platform,
                    style: const TextStyle(
                        color: Color(0xFFE8D5B7), fontSize: 11)),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.open_in_new,
                  color: Colors.white38, size: 14),
            ] else
              const Text('준비중',
                  style: TextStyle(color: Colors.white24, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
