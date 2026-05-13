import 'package:flutter/material.dart';

class ActionCard extends StatefulWidget {
  final String category;
  final String observation;
  final String application;
  final List<Map> references;

  const ActionCard({
    super.key,
    required this.category,
    required this.observation,
    required this.application,
    required this.references,
  });

  @override
  State<ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<ActionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.category,
                    style: const TextStyle(
                        color: Color(0xFFE8D5B7),
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white54),
              ],
            ),
            const SizedBox(height: 8),
            Text(widget.observation,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            if (_expanded) ...[
              const SizedBox(height: 12),
              const Divider(color: Colors.white12),
              const SizedBox(height: 8),

              // application — 메인 설명 (4요소 통합)
              Text(
                widget.application,
                style: const TextStyle(
                    color: Colors.white, fontSize: 13, height: 1.6),
              ),

              if (widget.references.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text('레퍼런스',
                    style: TextStyle(
                        color: Color(0xFFE8D5B7),
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                ...widget.references.map((ref) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.person_outline,
                                color: Color(0xFFE8D5B7), size: 13),
                            const SizedBox(width: 5),
                            Text(ref['name']?.toString() ?? '',
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ]),
                          if ((ref['context']?.toString() ?? '').isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 18, top: 2),
                              child: Text(ref['context'].toString(),
                                  style: const TextStyle(
                                      color: Colors.white38, fontSize: 11)),
                            ),
                          if ((ref['description']?.toString() ?? '').isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 18, top: 2),
                              child: Text(ref['description'].toString(),
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 11,
                                      fontStyle: FontStyle.italic)),
                            ),
                        ],
                      ),
                    )),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
