import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class GapRadarChart extends StatelessWidget {
  final Map<String, double> current;
  final Map<String, double> target;

  const GapRadarChart({super.key, required this.current, required this.target});

  @override
  Widget build(BuildContext context) {
    final labels = current.keys.toList();
    return Container(
      height: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('갭 분석',
              style: TextStyle(
                  color: Color(0xFFE8D5B7), fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            child: RadarChart(
              RadarChartData(
                radarShape: RadarShape.polygon,
                tickCount: 4,
                ticksTextStyle: const TextStyle(
                    color: Colors.transparent, fontSize: 0),
                gridBorderData: const BorderSide(color: Colors.white12),
                radarBorderData: const BorderSide(color: Colors.white24),
                titleTextStyle:
                    const TextStyle(color: Colors.white70, fontSize: 12),
                getTitle: (index, angle) =>
                    RadarChartTitle(text: labels[index]),
                dataSets: [
                  RadarDataSet(
                    fillColor:
                        const Color(0xFFE8D5B7).withAlpha(38),
                    borderColor: const Color(0xFFE8D5B7),
                    borderWidth: 2,
                    dataEntries: labels
                        .map((l) => RadarEntry(value: target[l] ?? 0))
                        .toList(),
                  ),
                  RadarDataSet(
                    fillColor: Colors.white.withAlpha(13),
                    borderColor: Colors.white38,
                    borderWidth: 1.5,
                    dataEntries: labels
                        .map((l) => RadarEntry(value: current[l] ?? 0))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legend(const Color(0xFFE8D5B7), '목표'),
              const SizedBox(width: 16),
              _legend(Colors.white38, '현재'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(children: [
      Container(width: 12, height: 2, color: color),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(color: color, fontSize: 11)),
    ]);
  }
}
