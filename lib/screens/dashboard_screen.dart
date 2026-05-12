import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/greentrail_drawer.dart';
import 'graph_component.dart';

class DashboardScreen extends StatefulWidget {
  final String userId;

  const DashboardScreen({super.key, required this.userId});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  String _error = '';

  Map<String, dynamic>? _weather;
  Map<String, dynamic>? _aqi;
  bool _showGraph = false;

  // Typing Animation State
  String _displayedText = '';
  int _quoteIndex = 0;
  bool _isDeleting = false;
  Timer? _typingTimer;

  final List<String> quotes = [
    "Step Lightly, Thrive Greenly",
    "Green Today, Thriving Tomorrow",
    "Sustain the Planet, Sustain Our Future",
    "Eco Living, Made Simple",
    "Plant the Seed for a Greener World",
  ];

  // API Config
  final String apiKey = "bc37a8c779f09599ac7f5d53566fdae4";
  final String lat = "28.4986";
  final String lon = "77.0469";

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
    _startTyping();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    super.dispose();
  }

  void _startTyping() {
    _typingTimer = Timer.periodic(
      Duration(milliseconds: _isDeleting ? 40 : 80),
      (timer) {
        if (!mounted) return;

        final fullQuote = quotes[_quoteIndex];

        setState(() {
          if (!_isDeleting) {
            if (_displayedText.length < fullQuote.length) {
              _displayedText = fullQuote.substring(
                0,
                _displayedText.length + 1,
              );
            } else {
              _isDeleting = true;
              timer.cancel();
              Future.delayed(const Duration(seconds: 2), _startTyping);
            }
          } else {
            if (_displayedText.isNotEmpty) {
              _displayedText = fullQuote.substring(
                0,
                _displayedText.length - 1,
              );
            } else {
              _isDeleting = false;
              _quoteIndex = (_quoteIndex + 1) % quotes.length;
              timer.cancel();
              Future.delayed(const Duration(milliseconds: 500), _startTyping);
            }
          }
        });
      },
    );
  }

  Future<void> _initializeDashboard() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    await _fetchWeatherAndAQI();
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchWeatherAndAQI() async {
    try {
      final weatherResponse = await http.get(
        Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&units=metric&appid=$apiKey',
        ),
      );

      if (weatherResponse.statusCode == 200) {
        if (mounted) {
          setState(() {
            _weather = jsonDecode(weatherResponse.body);
          });
        }
      }

      final aqiResponse = await http.get(
        Uri.parse(
          'https://api.openweathermap.org/data/2.5/air_pollution?lat=$lat&lon=$lon&appid=$apiKey',
        ),
      );

      if (aqiResponse.statusCode == 200) {
        final aqiData = jsonDecode(aqiResponse.body);
        int apiAqi = aqiData['list'][0]['main']['aqi'] ?? 1;
        if (mounted) {
          setState(() {
            _aqi = _mapAqi(apiAqi);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Error fetching weather or AQI data');
      }
    }
  }

  Map<String, dynamic> _mapAqi(int apiAqi) {
    switch (apiAqi) {
      case 1:
        return {"value": "0-50", "text": "Good", "color": Colors.green};
      case 2:
        return {
          "value": "51-100",
          "text": "Moderate",
          "color": Colors.yellow[700],
        };
      case 3:
        return {
          "value": "101-150",
          "text": "Unhealthy for Sensitive",
          "color": Colors.orange,
        };
      case 4:
        return {"value": "151-200", "text": "Unhealthy", "color": Colors.red};
      case 5:
        return {
          "value": "201-300+",
          "text": "Very Unhealthy",
          "color": Colors.purple,
        };
      default:
        return {"value": "0-50", "text": "Good", "color": Colors.green};
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            "GreenTrail",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green[800],
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Text(
            _error,
            style: const TextStyle(color: Colors.red, fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6), // Clean, light eco-grey
      appBar: AppBar(
        title: const Text(
          "GreenTrail Dashboard",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.green[800],
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      drawer: const GreentrailDrawer(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Animated Gradient Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[800]!, Colors.teal[600]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Welcome back,",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "$_displayedText|",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. Action Grid (Row 1)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.energy_savings_leaf,
                      iconColor: Colors.green[600]!,
                      title: "Track Footprint",
                      desc: "Analyze your emissions.",
                      btnText: "Start Tracking",
                      btnColor: Colors.green[700]!,
                      onTap: () => Navigator.pushNamed(context, '/track'),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(child: _buildWeatherCard()),
                ],
              ),
            ),
            const SizedBox(height: 15),

            // 3. Action Grid (Row 2)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.park,
                      iconColor: Colors.teal[600]!,
                      title: "Tree Offset",
                      desc: "Offset carbon via trees.",
                      btnText: "Plant a Tree",
                      btnColor: Colors.teal[700]!,
                      onTap: () => Navigator.pushNamed(context, '/donation'),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.history,
                      iconColor: Colors.blueGrey[600]!,
                      title: "Your Activities",
                      desc: "Review past progress.",
                      btnText: "View History",
                      btnColor: Colors.blueGrey[700]!,
                      onTap:
                          () => Navigator.pushNamed(context, '/user-activity'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // 4. Emission Analytics Toggle Card
            Card(
              elevation: 2,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.analytics,
                        color: Colors.blue[700],
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Emission Analytics",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Visualize your carbon trends.",
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[600],
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed:
                                  () =>
                                      setState(() => _showGraph = !_showGraph),
                              child: Text(
                                _showGraph
                                    ? "Hide Analytics"
                                    : "Show Analytics",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 5. Smooth Animated Graph Container
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child:
                  _showGraph
                      ? Container(
                        margin: const EdgeInsets.only(top: 15),
                        height: 350, // Fixed height prevents glitching
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: GraphComponent(userId: widget.userId),
                      )
                      : const SizedBox.shrink(),
            ),

            const SizedBox(height: 25),

            // 6. AI Object Scan CTA
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[700],
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () => Navigator.pushNamed(context, '/scan'),
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                label: const Text(
                  "Launch AI Object Scan",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- REUSABLE WIDGETS ---

  Widget _buildActionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
    required String btnText,
    required Color btnColor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                desc,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 36,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: btnColor,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: onTap,
                child: Text(
                  btnText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard() {
    return Card(
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.cloud_outlined,
                    color: Colors.blue[400],
                    size: 24,
                  ),
                ),
                InkWell(
                  onTap: _fetchWeatherAndAQI,
                  child: Icon(Icons.refresh, color: Colors.grey[400], size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              "Environment",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Expanded(
              child:
                  _weather != null
                      ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${_weather!['main']['temp']}°C | ${_weather!['weather'][0]['main']}",
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Humidity: ${_weather!['main']['humidity']}%",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      )
                      : const Text(
                        "Loading...",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
            ),
            if (_aqi != null)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: _aqi!['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _aqi!['color'].withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.air, color: _aqi!['color'], size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        "AQI: ${_aqi!['text']}",
                        style: TextStyle(
                          color: _aqi!['color'],
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
