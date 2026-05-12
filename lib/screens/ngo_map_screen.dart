import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class NgoMapScreen extends StatefulWidget {
  const NgoMapScreen({super.key});

  @override
  _NgoMapScreenState createState() => _NgoMapScreenState();
}

class _NgoMapScreenState extends State<NgoMapScreen> {
  LatLng? _userLocation;
  List<Marker> _ngoMarkers = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _fallbackToLocation("Location services disabled.");
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _fallbackToLocation("Location permission denied.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _fallbackToLocation("Location permissions permanently denied.");
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });
      _fetchNGOs(_userLocation!.latitude, _userLocation!.longitude);
    } catch (e) {
      _fallbackToLocation("Failed to get current location.");
    }
  }

  void _fallbackToLocation(String message) {
    setState(() {
      _error = "$message Using Delhi as fallback.";
      _userLocation = const LatLng(28.6139, 77.209);
    });
    _fetchNGOs(_userLocation!.latitude, _userLocation!.longitude);
  }

  Future<void> _fetchNGOs(double lat, double lon) async {
    setState(() => _isLoading = true);
    int radius = 20000; // 20km

    try {
      String query = """
        [out:json];
        (
          node["office"="ngo"]["description"~"tree|plant|environment|conservation",i](around:$radius,$lat,$lon);
          node["environment"="conservation"](around:$radius,$lat,$lon);
          node["name"~"Tree|Plant|Environment|Green|Conservation|Eco|Nature",i](around:$radius,$lat,$lon);
        );
        out center;
      """;

      final response = await http.get(
        Uri.parse(
          "https://overpass-api.de/api/interpreter?data=${Uri.encodeComponent(query)}",
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final elements = data['elements'] as List;

        List<Marker> markers = [];

        // Add User Marker
        markers.add(
          Marker(
            point: LatLng(lat, lon),
            width: 60,
            height: 60,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        );

        for (var e in elements) {
          if (e['lat'] != null && e['lon'] != null) {
            String name =
                e['tags']?['name'] ??
                e['tags']?['description'] ??
                'Environmental NGO';
            markers.add(
              Marker(
                point: LatLng(e['lat'], e['lon']),
                width: 60,
                height: 60,
                child: GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.green[800],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.green[600],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.nature,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        }

        setState(() {
          _ngoMarkers = markers;
          if (markers.length == 1) {
            _error = "No environmental NGOs found within 20km.";
          } else {
            _error = ''; // Clear error if NGOs found
          }
        });
      }
    } catch (e) {
      setState(() => _error = "Failed to load NGOs.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Return Stack directly so it embeds perfectly inside the TabBarView
    return Stack(
      children: [
        _userLocation == null
            ? const Center(
              child: Text(
                "Getting location...",
                style: TextStyle(color: Colors.grey),
              ),
            )
            : FlutterMap(
              options: MapOptions(
                initialCenter: _userLocation!,
                initialZoom: 13.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.greenverse.app',
                ),
                MarkerLayer(markers: _ngoMarkers),
              ],
            ),

        // Floating Loading Indicator
        if (_isLoading)
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Scanning for NGOs...",
                      style: TextStyle(
                        color: Colors.green[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Floating Error/Info Pill
        if (_error.isNotEmpty && !_isLoading)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.orange.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _error,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
