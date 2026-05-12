import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class FoodWasteNgoMapScreen extends StatefulWidget {
  const FoodWasteNgoMapScreen({super.key});

  @override
  _FoodWasteNgoMapScreenState createState() => _FoodWasteNgoMapScreenState();
}

class _FoodWasteNgoMapScreenState extends State<FoodWasteNgoMapScreen> {
  LatLng? _userLocation;
  List<Marker> _ngoMarkers = [];
  bool _isLoading = false;
  String _error = '';
  final double _searchRadius = 25000; // 25km

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    setState(() => _isLoading = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception("Location services disabled");

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
        _userLocation = LatLng(pos.latitude, pos.longitude);
      });
      _fetchNGOs(pos.latitude, pos.longitude);
    } catch (e) {
      // Fallback to Gurugram if location fails
      setState(() {
        _userLocation = const LatLng(28.4595, 77.0266);
        _error = "Using default location. Please enable GPS.";
      });
      _fetchNGOs(28.4595, 77.0266);
    }
  }

  List<Map<String, dynamic>> _getFallbackNGOs(double lat, double lon) {
    return [
      {
        "id": "mock1",
        "name": "Robin Hood Army - Local Chapter",
        "type": "Food Rescue",
        "phone": "+91 98765 43210",
        "lat": lat + 0.02,
        "lon": lon + 0.02,
      },
      {
        "id": "mock2",
        "name": "Seva Ashram (Accepts Food)",
        "type": "Ashram",
        "phone": "+91 99887 76655",
        "lat": lat - 0.015,
        "lon": lon + 0.03,
      },
      {
        "id": "mock3",
        "name": "City Orphanage & Relief",
        "type": "Orphanage",
        "phone": "Not provided",
        "lat": lat + 0.03,
        "lon": lon - 0.02,
      },
      {
        "id": "mock4",
        "name": "Annadanam Community Kitchen",
        "type": "Free Kitchen",
        "phone": "+91 91234 56789",
        "lat": lat - 0.02,
        "lon": lon - 0.01,
      },
      {
        "id": "mock5",
        "name": "Goonj Food Drop-off",
        "type": "NGO",
        "website": "https://goonj.org",
        "phone": "Not provided",
        "lat": lat + 0.005,
        "lon": lon - 0.035,
      },
    ];
  }

  Future<void> _fetchNGOs(double lat, double lon) async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final query = """
        [out:json][timeout:25];
        (
          nwr["social_facility"~"food_bank|soup_kitchen|orphanage"](around:$_searchRadius,$lat,$lon);
          nwr["amenity"="social_facility"](around:$_searchRadius,$lat,$lon);
        );
        out center;
      """;

      final response = await http.get(
        Uri.parse(
          "https://overpass-api.de/api/interpreter?data=${Uri.encodeComponent(query)}",
        ),
      );

      if (response.statusCode != 200) {
        throw Exception("API Error ${response.statusCode}");
      }

      final data = jsonDecode(response.body);
      final elements = data['elements'] as List;

      if (elements.isEmpty) {
        throw Exception("No NGOs found in the real database.");
      }

      _buildMarkers(
        elements
            .map(
              (e) => {
                "id": e['id'].toString(),
                "name": e['tags']?['name'] ?? "Community Donation Center",
                "type": (e['tags']?['social_facility'] ?? "Donation Center")
                    .replaceAll('_', ' '),
                "phone":
                    e['tags']?['phone'] ??
                    e['tags']?['contact:phone'] ??
                    "No phone listed",
                "website":
                    e['tags']?['website'] ?? e['tags']?['contact:website'],
                "lat": e['lat'] ?? e['center']?['lat'],
                "lon": e['lon'] ?? e['center']?['lon'],
              },
            )
            .toList(),
      );
    } catch (err) {
      // Load fallback data if Overpass fails
      setState(() {
        _error = "Live map busy. Showing sample community centers.";
      });
      _buildMarkers(_getFallbackNGOs(lat, lon));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _buildMarkers(List<Map<String, dynamic>> ngoDataList) {
    List<Marker> markers = [];

    // Premium User Marker
    if (_userLocation != null) {
      markers.add(
        Marker(
          point: _userLocation!,
          width: 50,
          height: 50,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue[600],
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 24),
          ),
        ),
      );
    }

    // Premium NGO Markers
    for (var ngo in ngoDataList) {
      if (ngo['lat'] != null && ngo['lon'] != null) {
        markers.add(
          Marker(
            point: LatLng(ngo['lat'], ngo['lon']),
            width: 45,
            height: 45,
            child: GestureDetector(
              onTap: () => _showNgoDetails(ngo),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.green[600],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.volunteer_activism,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        );
      }
    }

    setState(() {
      _ngoMarkers = markers;
    });
  }

  void _showNgoDetails(Map<String, dynamic> ngo) {
    showModalBottomSheet(
      context: context,
      backgroundColor:
          Colors.transparent, // Allows the rounded corners to show cleanly
      isScrollControlled: true,
      builder:
          (context) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modal Handle
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
                Text(
                  ngo['name'],
                  style: TextStyle(
                    color: Colors.green[900],
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Text(
                    ngo['type'].toString().toUpperCase(),
                    style: TextStyle(
                      color: Colors.green[800],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.phone,
                        color: Colors.black87,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Text(
                      ngo['phone'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (ngo['website'] != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.language,
                          color: Colors.blue[700],
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Text(
                          "Visit Website",
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[800],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Close",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text(
          "NGO Network Map",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green[800],
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // --- 1. THE MAP ---
          _userLocation == null && _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.green),
              )
              : FlutterMap(
                options: MapOptions(
                  initialCenter:
                      _userLocation ?? const LatLng(28.4595, 77.0266),
                  initialZoom: 12.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.greenverse.app',
                  ),
                  MarkerLayer(markers: _ngoMarkers),
                ],
              ),

          // --- 2. FLOATING LOADING PILL ---
          if (_isLoading)
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          color: Colors.green,
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Scanning 25km radius...",
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

          // --- 3. FLOATING ERROR/INFO PILL ---
          if (_error.isNotEmpty && !_isLoading)
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.amber[300]!, width: 1.5),
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
                    Icon(Icons.info_outline, color: Colors.amber[800]),
                    const SizedBox(width: 12),
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
      ),
    );
  }
}
