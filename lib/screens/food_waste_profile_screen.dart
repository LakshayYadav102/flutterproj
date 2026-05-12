import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';

class FoodWasteProfileScreen extends StatefulWidget {
  const FoodWasteProfileScreen({super.key});

  @override
  _FoodWasteProfileScreenState createState() => _FoodWasteProfileScreenState();
}

class _FoodWasteProfileScreenState extends State<FoodWasteProfileScreen> {
  bool _isLoading = true;
  String _error = '';

  Map<String, dynamic>? _user;
  Map<String, dynamic>? _donationSummary;
  Map<String, dynamic>? _receivedSummary;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      setState(() {
        _error = "Not authenticated.";
        _isLoading = false;
      });
      return;
    }

    try {
      // Fetch both endpoints concurrently, just like the React app
      final results = await Future.wait([
        http.get(
          Uri.parse('${ApiService.baseUrl}/api/food-donations/my'),
          headers: {'Authorization': 'Bearer $token'},
        ),
        http.get(
          Uri.parse('${ApiService.baseUrl}/api/food-donations/received'),
          headers: {'Authorization': 'Bearer $token'},
        ),
      ]);

      final donRes = results[0];
      final recRes = results[1];

      if (donRes.statusCode == 200 && recRes.statusCode == 200) {
        final donData = jsonDecode(donRes.body);
        final recData = jsonDecode(recRes.body);

        setState(() {
          _user = donData['user'];
          _donationSummary = donData['summary'];
          _receivedSummary = recData['summary'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = "Failed to load profile data.";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Network error fetching profile.";
        _isLoading = false;
      });
    }
  }

  String _getEcoTitle(num donatedKg) {
    if (donatedKg > 50) return "Zero Waste Hero 🌍";
    if (donatedKg > 20) return "Hunger Fighter 🦸‍♂️";
    if (donatedKg > 5) return "Community Feeder 🍲";
    return "Food Saver 🌱";
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("My Impact"),
          backgroundColor: Colors.green[800],
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.green),
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("My Impact"),
          backgroundColor: Colors.green[800],
        ),
        body: Center(
          child: Text(_error, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    num totalDonatedKg = _donationSummary?['totalFoodDonatedKg'] ?? 0;
    num totalReceivedKg = _receivedSummary?['totalFoodReceivedKg'] ?? 0;

    num carbonSavedDonating = _donationSummary?['totalCarbonSaved'] ?? 0;
    num carbonSavedReceiving = _receivedSummary?['totalCarbonImpact'] ?? 0;
    num totalCarbonImpact = carbonSavedDonating + carbonSavedReceiving;

    String profilePicUrl = _user?['profilePic'] ?? "";
    if (profilePicUrl.isNotEmpty && !profilePicUrl.startsWith('http')) {
      profilePicUrl = '${ApiService.baseUrl}$profilePicUrl';
    }

    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        title: const Text("My Food Rescue Impact"),
        backgroundColor: Colors.green[800],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 20, bottom: 40),
              decoration: BoxDecoration(
                color: Colors.green[800],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    backgroundImage:
                        profilePicUrl.isNotEmpty
                            ? NetworkImage(profilePicUrl)
                            : null,
                    child:
                        profilePicUrl.isEmpty
                            ? Text(
                              _user?['username']
                                      ?.substring(0, 1)
                                      .toUpperCase() ??
                                  "U",
                              style: TextStyle(
                                fontSize: 40,
                                color: Colors.green[800],
                              ),
                            )
                            : null,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    _user?['username'] ?? "Eco Warrior",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _user?['email'] ?? "No email provided",
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getEcoTitle(totalDonatedKg),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Text(
                    "Your Lifetime Impact",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "See how your actions are saving food and the planet.",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),

                  _buildStatCard(
                    title: "Total Donated",
                    value: "$totalDonatedKg kg",
                    subtitle:
                        "${_donationSummary?['totalDonations'] ?? 0} individual donations",
                    icon: Icons.volunteer_activism,
                    color: Colors.orange,
                  ),

                  _buildStatCard(
                    title: "Food Rescued",
                    value: "$totalReceivedKg kg",
                    subtitle:
                        "${_receivedSummary?['totalReceived'] ?? 0} claims accepted",
                    icon: Icons.restaurant,
                    color: Colors.blue,
                  ),

                  _buildStatCard(
                    title: "Carbon Offset",
                    value: "${totalCarbonImpact.toStringAsFixed(2)} kg CO₂",
                    subtitle: "Greenhouse gases prevented",
                    icon: Icons.eco,
                    color: Colors.green,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
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
