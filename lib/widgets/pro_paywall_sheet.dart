import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'price_comparison_widget.dart';

class ProPaywallSheet extends StatefulWidget {
  final VoidCallback onPurchased;
  const ProPaywallSheet({super.key, required this.onPurchased});

  @override
  State<ProPaywallSheet> createState() => _ProPaywallSheetState();
}

class _ProPaywallSheetState extends State<ProPaywallSheet> {
  bool _loading = false;

  Future<void> _purchase() async {
    setState(() => _loading = true);
    try {
      final offerings = await Purchases.getOfferings();
      final pkg = offerings.current?.monthly;
      if (pkg != null) {
        await Purchases.purchasePackage(pkg);
        widget.onPurchased();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('구매 중 오류가 발생했어요: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).padding.bottom + 24),
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Text('Pro로 업그레이드',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const PriceComparisonWidget(),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _purchase,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE8D5B7),
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: _loading
                ? const CircularProgressIndicator(color: Colors.black)
                : const Text('Pro 시작하기 — 첫 달 4,900원',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('나중에',
                style: TextStyle(color: Colors.white38)),
          ),
        ],
      ),
    );
  }
}
