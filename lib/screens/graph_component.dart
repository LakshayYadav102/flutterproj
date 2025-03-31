import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GraphComponent extends StatefulWidget {
  final String userId;

  const GraphComponent({Key? key, required this.userId}) : super(key: key);

  @override
  _GraphComponentState createState() => _GraphComponentState();
}

class _GraphComponentState extends State<GraphComponent> {
  List<FlSpot> _graphData = [];
  List<String> _dates = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    fetchGraphData();
  }

  Future<void> fetchGraphData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/activities/footprint/${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          _graphData = List.generate(data['labels'].length, (index) {
            return FlSpot(index.toDouble(), data['values'][index].toDouble());
          });
          _dates = List<String>.from(data['labels']);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      setState(() {
        _error = 'Error fetching data for graph: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.red)),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: fetchGraphData,
                        child: const Text("Retry"),
                      ),
                    ],
                  )
                : SizedBox(
                    height: 400,  // Adjust the size of the graph here
                    child: LineChart(
                      LineChartData(
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(value.toInt().toString());
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                int index = value.toInt();
                                // Display actual date from API
                                if (index >= 0 && index < _dates.length) {
                                  return Text(_dates[index]);
                                }
                                return const Text('');
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: true),
                        gridData: FlGridData(show: true),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _graphData,
                            isCurved: true,
                            gradient: LinearGradient(colors: [Colors.green, Colors.lightGreen]),
                            barWidth: 4,
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [Colors.green.withOpacity(0.4), Colors.lightGreen.withOpacity(0.1)],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}
