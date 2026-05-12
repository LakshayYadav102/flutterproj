import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';

class EVMapWidget extends StatefulWidget {
  const EVMapWidget({super.key});

  @override
  _EVMapWidgetState createState() => _EVMapWidgetState();
}

class _EVMapWidgetState extends State<EVMapWidget> {
  LatLng? _position;
  List<Marker> _stationMarkers = [];
  bool _isLoading = true;
  String _error = '';
  int _searchRadius = 20;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception("Location disabled");

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception("Permission denied");
        }
      }

      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _position = LatLng(pos.latitude, pos.longitude);
      });
      _fetchStations();
    } catch (e) {
      setState(() {
        _error = "Location unavailable. Using fallback (Delhi).";
        _position = const LatLng(28.6139, 77.2090);
      });
      _fetchStations();
    }
  }

  Future<void> _fetchStations() async {
    if (_position == null) return;
    setState(() => _isLoading = true);

    try {
      // ✅ FIX: Added SharedPreferences to get the Auth Token
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse(
          '${ApiService.baseUrl}/api/ev/nearby?lat=${_position!.latitude}&lon=${_position!.longitude}&radius=$_searchRadius',
        ),
        // ✅ FIX: Added missing Authorization headers
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        var decodedData = jsonDecode(response.body);
        List<dynamic> data = [];

        // Safely extract data whether it's a direct list or wrapped in an object
        if (decodedData is List) {
          data = decodedData;
        } else if (decodedData is Map && decodedData.containsKey('data')) {
          data = decodedData['data'];
        } else if (decodedData is Map && decodedData.containsKey('stations')) {
          data = decodedData['stations'];
        }

        List<Marker> markers = [
          // User Location Marker
          Marker(
            point: _position!,
            width: 50,
            height: 50,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                ),
                const Icon(
                  Icons.my_location,
                  color: Colors.blueAccent,
                  size: 28,
                ),
              ],
            ),
          ),
        ];

        for (var s in data) {
          final addressInfo =
              s['AddressInfo'] ?? s; // Handle different API schemas
          if (addressInfo['Latitude'] != null &&
              addressInfo['Longitude'] != null) {
            markers.add(
              Marker(
                point: LatLng(
                  addressInfo['Latitude'],
                  addressInfo['Longitude'],
                ),
                width: 45,
                height: 45,
                child: GestureDetector(
                  onTap:
                      () => _showStationInfo(
                        addressInfo['Title'],
                        addressInfo['AddressLine1'],
                      ),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.ev_station,
                      color: Colors.green,
                      size: 26,
                    ),
                  ),
                ),
              ),
            );
          }
        }

        setState(() {
          _stationMarkers = markers;
          _isLoading = false;
        });

        // Auto-expand search if nothing is found locally
        if (data.isEmpty && _searchRadius < 50) {
          setState(() {
            _searchRadius = 50;
            _error = "Expanding search to 50km...";
          });
          _fetchStations();
        } else if (data.isEmpty) {
          setState(() => _error = "No EV stations found within 50km.");
        } else {
          setState(() => _error = ''); // Clear errors on success
        }
      } else {
        setState(() {
          _isLoading = false;
          _error = "Failed to fetch stations. (Error ${response.statusCode})";
        });
        print(
          "API Error: ${response.body}",
        ); // Helps for debugging backend issues
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = "Network error fetching stations.";
      });
      print("Catch Error: $e");
    }
  }

  void _showStationInfo(String? title, String? address) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder:
          (context) => Padding(
            padding: const EdgeInsets.only(
              left: 24.0,
              right: 24.0,
              bottom: 40.0,
              top: 10.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.ev_station,
                        color: Colors.green[700],
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        title ?? "EV Charging Station",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, color: Colors.grey, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        address ?? "Location address not provided.",
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 0,
                    ),
                    onPressed:
                        () => Navigator.pop(
                          context,
                        ), // Could hook this up to Google Maps intent later
                    icon: const Icon(Icons.directions, color: Colors.white),
                    label: const Text(
                      "Done",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (_position != null)
          FlutterMap(
            options: MapOptions(
              initialCenter: _position!,
              initialZoom: 13.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.greenverse.app',
              ),
              MarkerLayer(markers: _stationMarkers),
            ],
          ),

        // Floating Search Controls
        Positioned(
          top: 20,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.radar, color: Colors.teal[800], size: 20),
                const SizedBox(width: 10),
                Text(
                  "Search Radius:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _searchRadius,
                      isExpanded: true,
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.teal,
                      ),
                      items: const [
                        DropdownMenuItem(value: 10, child: Text("10 km")),
                        DropdownMenuItem(value: 20, child: Text("20 km")),
                        DropdownMenuItem(value: 50, child: Text("50 km")),
                      ],
                      onChanged: (val) {
                        if (val != null && val != _searchRadius) {
                          setState(() => _searchRadius = val);
                          _fetchStations();
                        }
                      },
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.grey[300],
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.my_location, color: Colors.blueAccent),
                  onPressed: _getUserLocation,
                  tooltip: "My Location",
                ),
              ],
            ),
          ),
        ),

        // Status / Loading Indicator
        if (_isLoading || _error.isNotEmpty)
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: _error.isNotEmpty ? Colors.red[50] : Colors.blue[50],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color:
                      _error.isNotEmpty ? Colors.red[200]! : Colors.blue[200]!,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_isLoading) ...[
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                    const SizedBox(width: 15),
                  ] else if (_error.isNotEmpty) ...[
                    Icon(Icons.error_outline, color: Colors.red[700]),
                    const SizedBox(width: 15),
                  ],
                  Expanded(
                    child: Text(
                      _error.isNotEmpty
                          ? _error
                          : "Scanning area for stations...",
                      style: TextStyle(
                        color:
                            _error.isNotEmpty
                                ? Colors.red[900]
                                : Colors.blue[900],
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
