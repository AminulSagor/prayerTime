import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/graph_data.dart';

class ResponseGraph extends StatelessWidget {
  final List<GraphData> graphData;

  const ResponseGraph({super.key, required this.graphData});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        titlesData: const FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true),
          ),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: graphData
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble(), e.value.yesCount.toDouble()))
                .toList(),
            isCurved: true,
            color: Colors.blue, // Changed to a single Color
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: false),
          ),
          LineChartBarData(
            spots: graphData
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble(), e.value.noCount.toDouble()))
                .toList(),
            isCurved: true,
            color: Colors.red, // Changed to a single Color
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(show: false),
          ),
          LineChartBarData(
            spots: graphData
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble(), e.value.missedCount.toDouble()))
                .toList(),
            isCurved: true,
            color: Colors.yellow, // Changed to a single Color
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }
}
