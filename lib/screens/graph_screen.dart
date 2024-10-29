import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../advertisment/banner_ad.dart';
import '../advertisment/interstitial_ad_helper.dart';
import '../models/graph_data.dart';
import '../services/database_helper.dart';
import 'package:intl/intl.dart';

class GraphScreen extends StatefulWidget {
  const GraphScreen({super.key});

  @override
  _GraphScreenState createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<GraphData> _graphData = [];
  String _selectedTimeframe = 'Last 7 days';
  final List<String> _timeframeOptions = [
    'Last 7 days',
    'Last 28 days',
    'Last 90 days',
    'Last 365 days',
    'Lifetime'
  ];
  final interstitialAdHelper = InterstitialAdHelper();
  @override
  void initState() {
    super.initState();
    interstitialAdHelper.loadInterstitialAd();
    _fetchGraphData();
  }

  Future<void> _fetchGraphData() async {
    final responses = await _databaseHelper.getUserResponses();
    DateTime now = DateTime.now();
    DateTime startDate;

    switch (_selectedTimeframe) {
      case 'Last 7 days':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'Last 28 days':
        startDate = now.subtract(const Duration(days: 28));
        break;
      case 'Last 90 days':
        startDate = now.subtract(const Duration(days: 90));
        break;
      case 'Last 365 days':
        startDate = now.subtract(const Duration(days: 365));
        break;
      default: // Lifetime
        startDate = DateTime(1970); // Include all data
    }

    Map<String, int> yesCount = {};
    Map<String, int> noCount = {};
    Map<String, int> missedCount = {};

    for (var response in responses) {
      if (response.timestamp.isAfter(startDate)) {
        String dateKey = DateFormat('yyyy-MM-dd').format(response.timestamp);
        print("Date in Database: $dateKey");
        if (response.response == 'Yes') {
          yesCount[dateKey] = (yesCount[dateKey] ?? 0) + 1;
        } else if (response.response == 'No') {
          noCount[dateKey] = (noCount[dateKey] ?? 0) + 1;
        } else {
          missedCount[dateKey] = (missedCount[dateKey] ?? 0) + 1;
        }
      }
    }

    List<GraphData> graphDataList = [];
    yesCount.forEach((date, count) {
      graphDataList.add(GraphData(
        date,
        count,
        noCount[date] ?? 0,
        missedCount[date] ?? 0,
      ));
      print("Graph Data - Date: $date, Yes: $count, No: ${noCount[date] ?? 0}, Missed: ${missedCount[date] ?? 0}");
    });

    setState(() {
      _graphData = graphDataList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prayer Performance Graph')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Timeframe:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedTimeframe,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedTimeframe = newValue!;
                        _fetchGraphData();
                      });
                      interstitialAdHelper.showInterstitialAd();
                      interstitialAdHelper.loadInterstitialAd();
                    },
                    items: _timeframeOptions.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: const TextStyle(fontSize: 16)),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                '“The most beloved deeds to Allah are those that are done consistently, even if they are few.”\n(Sahih Bukhari 6464)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 16),
            _buildChart(),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(Icons.square, color: Colors.blue, size: 15),
                    SizedBox(width: 5),
                    Text('Yes', style: TextStyle(fontSize: 14)),
                  ],
                ),
                SizedBox(width: 20),
                Row(
                  children: [
                    Icon(Icons.square, color: Colors.red, size: 15),
                    SizedBox(width: 5),
                    Text('No', style: TextStyle(fontSize: 14)),
                  ],
                ),
                SizedBox(width: 20),
                Row(
                  children: [
                    Icon(Icons.square, color: Colors.yellow, size: 15),
                    SizedBox(width: 5),
                    Text('Missed', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BannerAdWidget(),
    );

  }

  Widget _buildChart() {
    return SizedBox(
      height: 400,
      child: _selectedTimeframe == 'Last 7 days'
          ? _buildBarChart()
          : _buildLineChart(),
    );

  }

  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            axisNameWidget: Text('Number of Prayers'),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 1,
            ),
          ),
          bottomTitles: AxisTitles(
            axisNameWidget: const Text('DaYs'),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                return Text(
                  _graphData[value.toInt()].date.split('-').last,
                  style: const TextStyle(fontSize: 16),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: true),
        gridData: const FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: false,
            horizontalInterval: 1
        ),
        barGroups: _graphData.map((data) {
          return BarChartGroupData(
            x: _graphData.indexOf(data),
            barRods: [
              BarChartRodData(
                toY: data.yesCount.toDouble(),
                color: Colors.blue,
              ),
              BarChartRodData(
                toY: data.noCount.toDouble(),
                color: Colors.red,
              ),
              BarChartRodData(
                toY: data.missedCount.toDouble(),
                color: Colors.yellow,
              ),
            ],
          );
        }).toList(),
        maxY: 5,
      ),

    );
  }

  Widget _buildLineChart() {
    return LineChart(
      LineChartData(
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            axisNameWidget: Text('Number of Prayers'),
            sideTitles: SideTitles(showTitles: true, reservedSize: 24, interval: 1,),
          ),
          bottomTitles: AxisTitles(
            axisNameWidget: const Text('Days'),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                print("Index: $index, Length: ${_graphData.length}");
                // Make sure the index is within bounds of the _graphData list
                if (index >= 0 && index < _graphData.length) {

                  return Text(
                    DateFormat('d').format(DateTime.parse(_graphData[index].date)),
                    style: const TextStyle(fontSize: 12),
                  );
                }
                return const Text('');
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false), // No titles on the top
          ),
          rightTitles: const AxisTitles( // Remove right titles
            sideTitles: SideTitles(showTitles: false),
          ),
        ),

        maxY: 5,
        gridData: const FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: false,
            horizontalInterval: 1
        ),
        lineBarsData: [
          LineChartBarData(
            spots: _graphData.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value.yesCount.toDouble());
            }).toList(),
            isCurved: true,
            color: Colors.blue,
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            spots: _graphData.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value.noCount.toDouble());
            }).toList(),
            isCurved: true,
            color: Colors.red,
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            spots: _graphData.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value.missedCount.toDouble());
            }).toList(),
            isCurved: true,
            color: Colors.yellow,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),

    );

  }
}
