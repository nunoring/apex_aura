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
                style:
                    const TextStyle(color: Colors.white70, fontSize: 13)),
            if (_expanded) ...[
              const SizedBox(height: 12),
              const Divider(color: Colors.white12),
              const SizedBox(height: 8),
              const Text('적용 방법',
                  style: TextStyle(
                      color: Color(0xFFE8D5B7),
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(widget.application,
                  style: const TextStyle(color: Colors.white, fontSize: 13)),
              if (widget.references.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('레퍼런스',
                    style: TextStyle(
                        color: Color(0xFFE8D5B7),
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                ...widget.references.map((ref) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.person_outline,
                              color: Colors.white38, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${ref['name']} — ${ref['description']}',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12),
                            ),
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
