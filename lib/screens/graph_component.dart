import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';

class GraphComponent extends StatefulWidget {
  final String userId;

  const GraphComponent({super.key, required this.userId});

  @override
  _GraphComponentState createState() => _GraphComponentState();
}

class _GraphComponentState extends State<GraphComponent> {
  bool _isLoading = true;
  String _error = '';
  List<FlSpot> _spots = [];
  List<String> _labels = [];
  double _maxY = 10.0; // Default max Y

  @override
  void initState() {
    super.initState();
    _fetchGraphData();
  }

  Future<void> _fetchGraphData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // ✅ FIX: Added authentication token to the request
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse(
          '${ApiService.baseUrl}/api/activities/footprint/${widget.userId}',
        ),
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> rawLabels = data['labels'] ?? [];
        final List<dynamic> rawValues = data['values'] ?? [];

        List<FlSpot> spots = [];
        List<String> labels = [];
        double calculatedMaxY = 0.0;

        for (int i = 0; i < rawValues.length; i++) {
          double val =
              (rawValues[i] is num) ? (rawValues[i] as num).toDouble() : 0.0;
          spots.add(FlSpot(i.toDouble(), val));
          labels.add(rawLabels[i].toString());
          if (val > calculatedMaxY) {
            calculatedMaxY = val;
          }
        }

        setState(() {
          _spots = spots;
          _labels = labels;
          // Add a 20% buffer to the top of the chart so the highest point doesn't touch the edge
          _maxY = calculatedMaxY > 0 ? calculatedMaxY * 1.2 : 10.0;
          _error = '';
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load graph data';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error loading graph';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 250,
        child: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }

    if (_error.isNotEmpty) {
      return SizedBox(
        height: 250,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 10),
              // ✅ FIX: Added a retry button so the user isn't stuck
              ElevatedButton.icon(
                onPressed: _fetchGraphData,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text("Retry"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black87,
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_spots.isEmpty) {
      return const SizedBox(
        height: 250,
        child: Center(
          child: Text(
            "No data available to graph.",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // ✅ FIX: Calculate dynamic intervals to prevent UI clutter
    double yInterval = (_maxY / 5).ceilToDouble();
    if (yInterval == 0) yInterval = 1;

    // Prevent X-axis label overlapping if there are many data points
    int xInterval = max(1, (_spots.length / 6).ceil());

    return Padding(
      padding: const EdgeInsets.only(right: 20, top: 20, left: 10),
      child: SizedBox(
        height: 250,
        child: LineChart(
          LineChartData(
            // ✅ FIX: Custom interactive tooltips
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (touchedSpot) => Colors.blueGrey[900]!,
                tooltipRoundedRadius: 8,
                getTooltipItems: (List<LineBarSpot> touchedSpots) {
                  return touchedSpots.map((spot) {
                    final dateLabel = _labels[spot.x.toInt()];
                    return LineTooltipItem(
                      '$dateLabel\n',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      children: [
                        TextSpan(
                          text: '${spot.y.toStringAsFixed(1)} kg CO₂',
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    );
                  }).toList();
                },
              ),
              handleBuiltInTouches: true,
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false, // Cleaner modern look
              horizontalInterval: yInterval,
              getDrawingHorizontalLine:
                  (value) => FlLine(
                    color: Colors.grey[300],
                    strokeWidth: 1,
                    dashArray: [5, 5], // Dotted lines look softer
                  ),
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: xInterval.toDouble(),
                  getTitlesWidget: (value, meta) {
                    int index = value.toInt();
                    if (index >= 0 && index < _labels.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _labels[index],
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: yInterval,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(
              show: false,
            ), // Removed hard border for cleaner look
            minX: 0,
            // ✅ FIX: Prevent crash when there is only 1 data point
            maxX: _spots.length > 1 ? (_spots.length - 1).toDouble() : 1.0,
            minY: 0,
            maxY: _maxY,
            lineBarsData: [
              LineChartBarData(
                spots:
                    _spots.length == 1
                        ? [..._spots, FlSpot(1.0, _spots[0].y)]
                        : _spots, // Draw straight line if only 1 point
                isCurved: true,
                color: Colors.green[600],
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter:
                      (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 4,
                        color: Colors.white,
                        strokeWidth: 2,
                        strokeColor: Colors.green[600]!,
                      ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.withOpacity(0.3),
                      Colors.green.withOpacity(0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
