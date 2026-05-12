import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool _isLoading = true;
  String _error = '';
  Map<String, dynamic>? _walletData;

  @override
  void initState() {
    super.initState();
    _fetchWallet();
  }

  Future<void> _fetchWallet() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      setState(() {
        _error = "User not authenticated.";
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/api/profile/wallet-details'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _walletData = jsonDecode(response.body);
          _error = '';
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load wallet details.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("My Wallet"),
          backgroundColor: Colors.green[800],
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.green),
              SizedBox(height: 16),
              Text("Loading your GreenVerse Wallet..."),
            ],
          ),
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("My Wallet"),
          backgroundColor: Colors.green[800],
        ),
        body: Center(
          child: Text(_error, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    final int totalCoins = _walletData?['totalCoins'] ?? 0;
    final breakdown = _walletData?['breakdown'] ?? {};

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("My Wallet"),
        backgroundColor: Colors.green[800],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Section
            Container(
              color: Colors.green[800],
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: Column(
                children: [
                  const Text(
                    "My GreenCoin Wallet",
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("🪙", style: TextStyle(fontSize: 40)),
                      const SizedBox(width: 10),
                      Text(
                        "$totalCoins",
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "GreenCoins are awarded for making sustainable choices across GreenVerse.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "How You Earned Your Coins",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // GreenTrail Card
                  _buildBreakdownCard(
                    title: "🌳 GreenTrail",
                    total: breakdown['greenTrail']?['total'] ?? 0,
                    color: Colors.green,
                    details: [
                      "Logged ${breakdown['greenTrail']?['activitiesCount'] ?? 0} activities (1 coin/log)",
                      "Offset ${breakdown['greenTrail']?['treesPlanted'] ?? 0} trees (4 coins/tree)",
                    ],
                  ),

                  // Carpooling Card
                  _buildBreakdownCard(
                    title: "🚗 Carpooling",
                    total: breakdown['carpool']?['total'] ?? 0,
                    color: Colors.blue,
                    details: [
                      "Offered ${breakdown['carpool']?['ridesOffered'] ?? 0} shared rides (2 coins/ride)",
                      "Booked ${breakdown['carpool']?['bookings'] ?? 0} eco-rides (2 coins/booking)",
                    ],
                  ),

                  // FoodWaste Card
                  _buildBreakdownCard(
                    title: "🍲 Food Rescue",
                    total: breakdown['foodWaste']?['total'] ?? 0,
                    color: Colors.orange,
                    details: [
                      "Rescued ${breakdown['foodWaste']?['donationsCount'] ?? 0} donations",
                      "Prevented ${breakdown['foodWaste']?['foodCarbonSaved'] ?? 0} kg CO₂ (1 coin/5kg)",
                    ],
                  ),

                  // GreenStream Card
                  _buildBreakdownCard(
                    title: "📱 GreenStream",
                    total: breakdown['ecoLearn']?['total'] ?? 0,
                    color: Colors.purple,
                    details: [
                      "Uploaded ${breakdown['ecoLearn']?['videosCount'] ?? 0} educational videos",
                      "Generated ${breakdown['ecoLearn']?['videoViews'] ?? 0} views (1 coin/50 views)",
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownCard({
    required String title,
    required int total,
    required Color color,
    required List<String> details,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: color.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "+$total 🪙",
                    style: TextStyle(fontWeight: FontWeight.bold, color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...details.map(
              (desc) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: color.withOpacity(0.5),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        desc,
                        style: TextStyle(color: Colors.grey[800], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
