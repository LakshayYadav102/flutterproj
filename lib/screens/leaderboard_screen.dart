import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api/api_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<dynamic> leaderboard = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    fetchLeaderboard();
  }

  Future<void> fetchLeaderboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/api/leaderboard"),
      );

      if (response.statusCode == 200) {
        setState(() {
          leaderboard = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception("Failed to load leaderboard data");
      }
    } catch (e) {
      setState(() {
        _error = "Error fetching leaderboard: $e";
        _isLoading = false;
      });
    }
  }

  String _getMedal(int rank) {
    if (rank == 1) return "🥇";
    if (rank == 2) return "🥈";
    if (rank == 3) return "🥉";
    return "#$rank";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Eco Leaderboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green[800],
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.green),
              )
              : _error != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: fetchLeaderboard,
                      child: const Text(
                        "Retry",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  // Header Banner explaining the 7-day rule
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green[800],
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: const Column(
                      children: [
                        Text(
                          "Top Eco Warriors",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "Ranked by least carbon footprint in the last 7 days",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Leaderboard List
                  Expanded(
                    child:
                        leaderboard.isEmpty
                            ? const Center(
                              child: Text(
                                "No active users this week yet.\nStart reducing your footprint!",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            )
                            : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              itemCount: leaderboard.length,
                              itemBuilder: (context, index) {
                                final user = leaderboard[index];
                                final rank = index + 1;
                                final isTop3 = rank <= 3;

                                return Card(
                                  elevation: isTop3 ? 4 : 1,
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 6,
                                    horizontal: 5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    side: BorderSide(
                                      color:
                                          isTop3
                                              ? Colors.green.withOpacity(0.5)
                                              : Colors.transparent,
                                      width: 1,
                                    ),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 16,
                                    ),
                                    leading: Stack(
                                      alignment: Alignment.bottomRight,
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: Colors.green[100],
                                          backgroundImage:
                                              user['profilePic'] != null
                                                  ? NetworkImage(
                                                    user['profilePic'],
                                                  )
                                                  : const AssetImage(
                                                        'assets/default_profile.png',
                                                      )
                                                      as ImageProvider,
                                          radius: 25,
                                        ),
                                        if (isTop3)
                                          Container(
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white,
                                            ),
                                            child: Text(
                                              _getMedal(rank),
                                              style: const TextStyle(
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    title: Text(
                                      user['username'] ?? 'Unknown',
                                      style: TextStyle(
                                        fontWeight:
                                            isTop3
                                                ? FontWeight.bold
                                                : FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        'Emissions: ${user['totalEmission']} kg CO₂',
                                        style: TextStyle(
                                          color: Colors.green[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    trailing:
                                        isTop3
                                            ? null // Top 3 have emojis on their avatar
                                            : Text(
                                              _getMedal(rank),
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
    );
  }
}
