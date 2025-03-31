import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WeatherAqiWidget extends StatefulWidget {
const WeatherAqiWidget({super.key});
  @override
  _WeatherAqiWidgetState createState() => _WeatherAqiWidgetState();
}

class _WeatherAqiWidgetState extends State<WeatherAqiWidget> {
  final String apiKey = "bc37a8c779f09599ac7f5d53566fdae4";
  final String lat = "28.4986";
  final String lon = "77.0469";

  Map<String, dynamic> weather = {};
  Map<String, dynamic> aqi = {};
  bool loading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchWeatherAndAQI();
  }

  Future<void> fetchWeatherAndAQI() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      // Fetch Weather Data
      final weatherResponse = await http.get(
        Uri.parse(
            'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&units=metric&appid=$apiKey'),
      );
      if (weatherResponse.statusCode == 200) {
        weather = json.decode(weatherResponse.body);
      } else {
        throw Exception('Failed to load weather data');
      }

      // Fetch AQI Data
      final aqiResponse = await http.get(
        Uri.parse(
            'https://api.openweathermap.org/data/2.5/air_pollution?lat=$lat&lon=$lon&appid=$apiKey'),
      );
      if (aqiResponse.statusCode == 200) {
        aqi = json.decode(aqiResponse.body);
      } else {
        throw Exception('Failed to load AQI data');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching weather or AQI data: $e';
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return loading
        ? Center(child: CircularProgressIndicator())
        : errorMessage != null
            ? Center(child: Text(errorMessage!))
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Environment Status',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 16),
                        weather.isNotEmpty
                            ? Column(
                                children: [
                                  Text(
                                      'Temperature: ${weather['main']['temp']}°C'),
                                  Text(
                                      'Humidity: ${weather['main']['humidity']}%'),
                                  Text(
                                      'Condition: ${weather['weather'][0]['description']}'),
                                  const SizedBox(height: 16),
                                  aqi.isNotEmpty
                                      ? Column(
                                          children: [
                                            Text(
                                              'AQI: ${aqi['list'][0]['main']['aqi']}',
                                              style: TextStyle(
                                                color: aqi['list'][0]
                                                            ['main']['aqi'] ==
                                                        1
                                                    ? Colors.green
                                                    : aqi['list'][0]
                                                                ['main']['aqi'] ==
                                                            2
                                                        ? Colors.yellow
                                                        : aqi['list'][0]
                                                                    ['main']
                                                                ['aqi'] ==
                                                            3
                                                        ? Colors.orange
                                                        : aqi['list'][0]
                                                                    ['main']
                                                                ['aqi'] ==
                                                            4
                                                        ? Colors.red
                                                        : Colors.purple,
                                              ),
                                            ),
                                            Text(
                                              'Status: ${mapAqi(aqi['list'][0]['main']['aqi'])['text']}',
                                            ),
                                          ],
                                        )
                                      : Container(),
                                ],
                              )
                            : Center(child: CircularProgressIndicator()),
                      ],
                    ),
                  ),
                ),
              );
  }

  // Map AQI to a human-readable description
  Map<String, dynamic> mapAqi(int aqi) {
    const aqiRanges = {
      1: {'value': '0-50', 'text': 'Good', 'color': Colors.green},
      2: {'value': '51-100', 'text': 'Moderate', 'color': Colors.yellow},
      3: {'value': '101-150', 'text': 'Unhealthy for Sensitive Groups', 'color': Colors.orange},
      4: {'value': '151-200', 'text': 'Unhealthy', 'color': Colors.red},
      5: {'value': '201-300+', 'text': 'Very Unhealthy', 'color': Colors.purple},
    };
    return aqiRanges[aqi] ?? aqiRanges[1]!;
  }
}
