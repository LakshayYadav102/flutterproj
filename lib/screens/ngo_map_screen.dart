import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NgoMapScreen extends StatefulWidget {
  const NgoMapScreen({Key? key}) : super(key: key);

  @override
  _NgoMapScreenState createState() => _NgoMapScreenState();
}

class _NgoMapScreenState extends State<NgoMapScreen> {
  LatLng? userLocation;
  List<Map<String, dynamic>> ngos = [];
  String error = '';
  bool isLoading = false;
  double searchRadius = 20000; // 20 km

  @override
  void initState() {
    super.initState();
    // Clear cache on init to force fresh location fetch
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('userLocation');
      prefs.remove('userLocationTimestamp');
      print('Cleared cached location');
      loadCachedLocation();
    });
  }

  Future<void> loadCachedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedLocation = prefs.getString('userLocation');
    final cachedTimestamp = prefs.getInt('userLocationTimestamp') ?? 0;

    // Use cached location only if less than 10 minutes old
    if (cachedLocation != null &&
        DateTime.now().millisecondsSinceEpoch - cachedTimestamp < 600000) {
      final loc = jsonDecode(cachedLocation);
      print('Using cached location: ${loc['lat']}, ${loc['lon']}');
      setState(() {
        userLocation = LatLng(loc['lat'], loc['lon']);
        error = 'Using cached location. Refresh for current location.';
      });
      fetchNGOs(loc['lat'], loc['lon'], searchRadius);
    } else {
      print('No valid cached location or cache is stale');
      getUserLocation();
    }
  }

  Future<void> getUserLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          error = 'Location services are disabled. Please enable GPS.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enable location services')),
        );
        await Geolocator.openLocationSettings();
        setFallbackLocation();
        return;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            error = 'Location permissions denied.';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are required')),
          );
          setFallbackLocation();
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          error =
              'Location permissions are permanently denied. Please enable them in settings.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enable location permissions in settings'),
          ),
        );
        await Geolocator.openAppSettings();
        setFallbackLocation();
        return;
      }

      // Get position with extended timeout
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 30), // Extended timeout
      );
      final location = LatLng(position.latitude, position.longitude);
      print('Current location: ${location.latitude}, ${location.longitude}');

      setState(() {
        userLocation = location;
        error = ''; // Clear any previous errors
      });

      // Cache the location
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'userLocation',
        jsonEncode({'lat': location.latitude, 'lon': location.longitude}),
      );
      await prefs.setInt(
        'userLocationTimestamp',
        DateTime.now().millisecondsSinceEpoch,
      );

      fetchNGOs(location.latitude, location.longitude, searchRadius);
    } catch (e) {
      print('Error getting location: $e');
      setState(() {
        error = 'Failed to get location: $e';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to get location: $e')));
      setFallbackLocation();
    }
  }

  Future<void> setFallbackLocation() async {
    const fallbackLocation = LatLng(28.6139, 77.209); // Delhi
    print(
      'Using fallback location: Delhi (${fallbackLocation.latitude}, ${fallbackLocation.longitude})',
    );
    setState(() {
      userLocation = fallbackLocation;
      error =
          error.isEmpty
              ? 'Unable to get location. Using Delhi as fallback.'
              : error;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'userLocation',
      jsonEncode({
        'lat': fallbackLocation.latitude,
        'lon': fallbackLocation.longitude,
      }),
    );
    await prefs.setInt(
      'userLocationTimestamp',
      DateTime.now().millisecondsSinceEpoch,
    );
    fetchNGOs(
      fallbackLocation.latitude,
      fallbackLocation.longitude,
      searchRadius,
    );
  }

  Future<void> fetchNGOs(double lat, double lon, double radius) async {
    setState(() {
      isLoading = true;
      error = error.isEmpty ? '' : error; // Preserve existing error
    });
    try {
      final query = '''
        [out:json];
        (
          node["office"="ngo"](around:$radius,$lat,$lon);
          node["amenity"="ngo"](around:$radius,$lat,$lon);
          node["name"~"Tree|Plant|Environment|Green|Conservation|Eco|Nature",i](around:$radius,$lat,$lon);
          node["description"~"tree|plant|environment|conservation",i](around:$radius,$lat,$lon);
        );
        out center;
      ''';
      final response = await http.get(
        Uri.parse(
          'https://overpass-api.de/api/interpreter?data=${Uri.encodeQueryComponent(query)}',
        ),
      );
      print('Overpass API Response: ${response.statusCode} ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Overpass API failed: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      final ngoList =
          (data['elements'] as List)
              .where((e) => e['lat'] != null && e['lon'] != null)
              .where(
                (e) =>
                    (e['tags']['office'] == 'ngo' ||
                        e['tags']['amenity'] == 'ngo') ||
                    RegExp(
                      r'tree|plant|environment|green|conservation|eco|nature',
                      caseSensitive: false,
                    ).hasMatch(
                      e['tags']['name'] ?? e['tags']['description'] ?? '',
                    ),
              )
              .map(
                (e) => {
                  'id': e['id'],
                  'name':
                      e['tags']['name'] ?? e['tags']['description'] ?? 'NGO',
                  'lat': e['lat'],
                  'lon': e['lon'],
                },
              )
              .toList();

      setState(() {
        if (ngoList.isEmpty) {
          if (radius < 50000) {
            searchRadius = 50000;
            error =
                error.isEmpty
                    ? 'No NGOs found within 20 km. Expanding search to 50 km...'
                    : error;
            fetchNGOs(lat, lon, searchRadius);
          } else {
            error = error.isEmpty ? 'No NGOs found within 50 km.' : error;
            ngos = [];
          }
        } else {
          ngos = ngoList;
          error = error.isEmpty ? '' : error; // Preserve location error
        }
        isLoading = false;
      });
    } catch (e) {
      print('FetchNGOs Error: $e');
      setState(() {
        error = error.isEmpty ? 'Failed to load NGOs: $e' : error;
        ngos = [];
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load NGOs: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('NGO Map'),
        backgroundColor:
            isDarkMode ? Colors.deepPurple[800] : Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              print('Refresh triggered');
              getUserLocation(); // Always fetch fresh location on refresh
            },
            tooltip: 'Refresh Map',
          ),
        ],
      ),
      body:
          userLocation == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  if (error.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        error,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  if (isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    Expanded(
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: userLocation!,
                          initialZoom: 13,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                            subdomains: const ['a', 'b', 'c'],
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: userLocation!,
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.person_pin_circle,
                                  color: Colors.blue,
                                  size: 40,
                                ),
                              ),
                              ...ngos.map(
                                (ngo) => Marker(
                                  point: LatLng(ngo['lat'], ngo['lon']),
                                  width: 40,
                                  height: 40,
                                  child: GestureDetector(
                                    onTap:
                                        () => showDialog(
                                          context: context,
                                          builder:
                                              (ctx) => AlertDialog(
                                                title: Text(ngo['name']),
                                                content: const Text(
                                                  'Environmental Organization',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed:
                                                        () =>
                                                            Navigator.pop(ctx),
                                                    child: const Text('Close'),
                                                  ),
                                                ],
                                              ),
                                        ),
                                    child: const Icon(
                                      Icons.location_pin,
                                      color: Colors.green,
                                      size: 40,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text(
                          'Explore Our NGO Partners',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'The map showcases our network of NGOs dedicated to tree planting and reforestation.',
                        ),
                        ListTile(
                          leading: const Icon(Icons.location_on),
                          title: const Text('NGO Locations'),
                          subtitle: const Text('Global and local partners.'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.park),
                          title: const Text('Project Sites'),
                          subtitle: const Text('Active planting areas.'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.eco),
                          title: const Text('Impact Areas'),
                          subtitle: const Text(
                            'Regions benefiting from your donations.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}
