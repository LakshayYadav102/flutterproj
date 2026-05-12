import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import '../api/api_service.dart';

class CorporateDashboard extends StatefulWidget {
  const CorporateDashboard({super.key});

  @override
  _CorporateDashboardState createState() => _CorporateDashboardState();
}

class _CorporateDashboardState extends State<CorporateDashboard> {
  String companyName = 'Partner Company';
  Map<String, dynamic>? stats;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCorporateData();
  }

  Future<void> _fetchCorporateData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedCompany = prefs.getString('companyName');

    if (storedCompany != null && storedCompany.isNotEmpty) {
      companyName = storedCompany[0].toUpperCase() + storedCompany.substring(1);
      try {
        final response = await http.get(
          Uri.parse('${ApiService.baseUrl}/api/corporate/stats/$storedCompany'),
        );
        if (response.statusCode == 200) {
          setState(() {
            stats = jsonDecode(response.body);
          });
        }
      } catch (e) {
        debugPrint("Failed to fetch corporate stats: $e");
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F1E14),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(color: Colors.greenAccent),
              SizedBox(height: 20),
              Text(
                "Loading Enterprise Analytics...",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // 1. High-Quality Dark Forest Background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // 2. Dark Overlay for Contrast
          Container(color: const Color(0xFF0A190F).withOpacity(0.85)),
          // 3. Main Scrollable Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 20.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // HEADER
                  Center(
                    child: Text(
                      "🏢 $companyName\nESG Command Center",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      width: 100,
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.greenAccent, Colors.amber],
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "Verified Enterprise Partner",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // ROW 1: CORE ESG KPIs
                  _buildGlassCard(
                    borderColor: Colors.greenAccent,
                    child: _buildMetricRow(
                      icon: Icons.trending_down,
                      iconColor: Colors.greenAccent,
                      title: "Total CO2 Reduced",
                      value: "${stats?['greenTrail']?['totalCO2'] ?? 0} kg",
                      subtitle: "Certified YTD Offset",
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _buildGlassCard(
                          borderColor: Colors.lightBlueAccent,
                          child: _buildMetricRow(
                            icon: Icons.people,
                            iconColor: Colors.lightBlueAccent,
                            title: "Active Users",
                            value: "${stats?['activeEmployees'] ?? 0}",
                            subtitle: "Workforce",
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildGlassCard(
                          borderColor: Colors.amber,
                          child: _buildMetricRow(
                            icon: Icons.park,
                            iconColor: Colors.amber,
                            title: "Trees",
                            value:
                                "${stats?['greenTrail']?['totalTrees'] ?? 0}",
                            subtitle: "Sponsored",
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // ROW 2: MODULE INTEGRATIONS
                  const Text(
                    "MODULE INTEGRATIONS",
                    style: TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),

                  _buildGlassCard(
                    borderColor: Colors.blueAccent,
                    child: _buildModuleRow(
                      icon: Icons.directions_car,
                      color: Colors.blueAccent,
                      title: "Carpooling",
                      value:
                          "${stats?['carpooling']?['totalRides'] ?? 0} Rides",
                      subtitle:
                          "≈ ${stats?['carpooling']?['co2Saved'] ?? 0} kg CO2 saved",
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildGlassCard(
                    borderColor: Colors.orangeAccent,
                    child: _buildModuleRow(
                      icon: Icons.favorite,
                      color: Colors.orangeAccent,
                      title: "Food Rescue",
                      value: "${stats?['foodWaste']?['mealsSaved'] ?? 0} Meals",
                      subtitle:
                          "${stats?['foodWaste']?['totalDonations'] ?? 0} Active Donors",
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildGlassCard(
                    borderColor: Colors.purpleAccent,
                    child: _buildModuleRow(
                      icon: Icons.play_circle_fill,
                      color: Colors.purpleAccent,
                      title: "GreenStream",
                      value:
                          "${stats?['ecoLearn']?['totalVideos'] ?? 0} Videos",
                      subtitle:
                          "${stats?['ecoLearn']?['totalViews'] ?? 0} Total Views",
                    ),
                  ),
                  const SizedBox(height: 30),

                  // ROW 3: DEEP ANALYTICS (Charts)
                  const Text(
                    "YEARLY EMISSIONS VS TARGET (TONS)",
                    style: TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildGlassCard(
                    child: SizedBox(
                      height: 250,
                      child: _buildEmissionsLineChart(),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // DEPARTMENT BREAKDOWN
                  const Text(
                    "OFFSET BY DEPARTMENT",
                    style: TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildGlassCard(child: _buildDepartmentBreakdown()),
                  const SizedBox(height: 30),

                  // HISTORICAL TREND CHART
                  const Text(
                    "CROSS-MODULE IMPACT GROWTH",
                    style: TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildGlassCard(
                    child: SizedBox(height: 250, child: _buildImpactBarChart()),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildGlassCard({
    required Widget child,
    Color borderColor = Colors.white12,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1E14).withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor.withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildMetricRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 32),
        const SizedBox(height: 10),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildModuleRow({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 40),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- CHARTS ---

  Widget _buildEmissionsLineChart() {
    List<dynamic> targets = stats?['emissionTargets'] ?? [];
    if (targets.isEmpty)
      return const Center(
        child: Text("No Data", style: TextStyle(color: Colors.white)),
      );

    List<FlSpot> targetSpots = [];
    List<FlSpot> actualSpots = [];

    for (int i = 0; i < targets.length; i++) {
      targetSpots.add(
        FlSpot(i.toDouble(), (targets[i]['target'] as num).toDouble()),
      );
      actualSpots.add(
        FlSpot(i.toDouble(), (targets[i]['actual'] as num).toDouble()),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine:
              (value) => FlLine(color: Colors.white10, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < targets.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      targets[value.toInt()]['month'],
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
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
              reservedSize: 40,
              getTitlesWidget:
                  (value, meta) => Text(
                    "${value.toInt()}",
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: targetSpots,
            isCurved: true,
            color: Colors.redAccent,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            dashArray: [5, 5], // Dashed line for target
          ),
          LineChartBarData(
            spots: actualSpots,
            isCurved: true,
            color: Colors.greenAccent,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.greenAccent.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentBreakdown() {
    List<dynamic> depts = stats?['departmentData'] ?? [];
    if (depts.isEmpty)
      return const Center(
        child: Text("No Data", style: TextStyle(color: Colors.white)),
      );

    // On mobile, horizontal bar charts are hard to read. A progress-bar list looks much cleaner.
    double maxOffset = 1;
    for (var d in depts) {
      if ((d['offsetTons'] as num).toDouble() > maxOffset) {
        maxOffset = (d['offsetTons'] as num).toDouble();
      }
    }

    return Column(
      children:
          depts.map((d) {
            double offset = (d['offsetTons'] as num).toDouble();
            double percentage = offset / maxOffset;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        d['department'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        "${offset.toInt()} Tons",
                        style: const TextStyle(
                          color: Colors.lightBlueAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: Colors.white10,
                    color: Colors.lightBlueAccent,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildImpactBarChart() {
    List<dynamic> trends = stats?['trendData'] ?? [];
    if (trends.isEmpty)
      return const Center(
        child: Text("No Data", style: TextStyle(color: Colors.white)),
      );

    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < trends.length; i++) {
      double rides = (trends[i]['rides'] as num).toDouble();
      double food = (trends[i]['food'] as num).toDouble();
      double trees = (trends[i]['trees'] as num).toDouble();

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: rides + food + trees, // Stacked total
              rodStackItems: [
                BarChartRodStackItem(0, rides, Colors.blueAccent),
                BarChartRodStackItem(rides, rides + food, Colors.amber),
                BarChartRodStackItem(
                  rides + food,
                  rides + food + trees,
                  Colors.greenAccent,
                ),
              ],
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine:
              (value) => FlLine(color: Colors.white10, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < trends.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      trends[value.toInt()]['month'],
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
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
              reservedSize: 30,
              getTitlesWidget:
                  (value, meta) => Text(
                    "${value.toInt()}",
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
      ),
    );
  }
}
