import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  _ChallengesScreenState createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  bool _isLoading = true;
  String _error = '';
  List<dynamic> _challenges = [];
  String? _selectedChallengeId;
  String? _userId;
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    _fetchChallenges();
  }

  Future<void> _fetchChallenges() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString('userId');
      String? token = prefs.getString('token');

      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/api/challenges/'),
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _challenges = data;
          if (data.isNotEmpty) {
            _selectedChallengeId = data[0]['_id'];
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = "Failed to load challenges.";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Network error. Please try again.";
        _isLoading = false;
      });
    }
  }

  Future<void> _joinChallenge(String challengeId) async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please log in to join challenges")),
      );
      return;
    }

    setState(() => _isJoining = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/challenges/join'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({"userId": _userId, "challengeId": challengeId}),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? "Joined Successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? "Failed to join."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Network error."),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isJoining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Eco Challenges"),
        backgroundColor: Colors.green[800],
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.green),
              )
              : _error.isNotEmpty
              ? Center(
                child: Text(_error, style: const TextStyle(color: Colors.red)),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Text
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green[800],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Column(
                        children: [
                          Text(
                            "Community Spirit",
                            style: TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "Compete with the community to achieve the lowest carbon footprint this week.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Main Challenge Card
                    if (_challenges.isNotEmpty)
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  "Active Mission",
                                  style: TextStyle(
                                    color: Colors.green[800],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 15),
                              Text(
                                _challenges[0]['title'] ?? "Challenge",
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _challenges[0]['description'] ?? "",
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 20),

                              // Stats Row
                              Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Text(
                                          "🎯",
                                          style: TextStyle(fontSize: 24),
                                        ),
                                        const SizedBox(width: 10),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "Goal",
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              "${_challenges[0]['goal']} kg CO₂",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Text(
                                          "⏳",
                                          style: TextStyle(fontSize: 24),
                                        ),
                                        const SizedBox(width: 10),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "Duration",
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              "${_challenges[0]['duration']} Days",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Join Button
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green[600],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed:
                                      _isJoining
                                          ? null
                                          : () => _joinChallenge(
                                            _challenges[0]['_id'],
                                          ),
                                  child:
                                      _isJoining
                                          ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                          : const Text(
                                            "Join Challenge",
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
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.all(40.0),
                        child: Center(
                          child: Text(
                            "No active challenges at the moment. Stay tuned!",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),

                    const SizedBox(height: 30),

                    // Embedded Leaderboard
                    if (_selectedChallengeId != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Live Leaderboard",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // ✅ FIXED: Now actively calls the leaderboard!
                          LeaderboardWidget(challengeId: _selectedChallengeId!),
                        ],
                      ),
                  ],
                ),
              ),
    );
  }
}

// ==========================================
// LEADERBOARD WIDGET
// ==========================================
class LeaderboardWidget extends StatefulWidget {
  final String challengeId;

  const LeaderboardWidget({super.key, required this.challengeId});

  @override
  _LeaderboardWidgetState createState() => _LeaderboardWidgetState();
}

class _LeaderboardWidgetState extends State<LeaderboardWidget> {
  bool _isLoading = true;
  String _error = '';
  List<dynamic> _leaderboard = [];

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  @override
  void didUpdateWidget(covariant LeaderboardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.challengeId != widget.challengeId) {
      _fetchLeaderboard();
    }
  }

  Future<void> _fetchLeaderboard() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final res = await http.get(
        Uri.parse(
          '${ApiService.baseUrl}/api/challenges/leaderboard/${widget.challengeId}',
        ),
      );

      if (res.statusCode == 200) {
        setState(() {
          _leaderboard = jsonDecode(res.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = "Failed to load leaderboard.";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Network error fetching leaderboard.";
        _isLoading = false;
      });
    }
  }

  String _getMedal(int rank) {
    if (rank == 1) return "🥇";
    if (rank == 2) return "🥈";
    if (rank == 3) return "🥉";
    return "$rank";
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        child: const Column(
          children: [
            CircularProgressIndicator(color: Colors.green),
            SizedBox(height: 10),
            Text(
              "Calculating Eco Scores...",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text("⚠️ $_error", style: const TextStyle(color: Colors.red)),
      );
    }

    double maxCO2 = 100.0;
    if (_leaderboard.isNotEmpty) {
      maxCO2 = _leaderboard
          .map((e) => (e['totalCO2'] as num).toDouble())
          .reduce((a, b) => a > b ? a : b);
      if (maxCO2 == 0) maxCO2 = 1; // Prevent division by zero
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green[800]!, Colors.teal[700]!],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "${_leaderboard.length} Participants",
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "🏆 Community Hall of Fame",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                "Active participants ranked by lowest emissions this week.",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),

        // List
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(15),
              bottomRight: Radius.circular(15),
            ),
            boxShadow: [
              BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5),
            ],
          ),
          child:
              _leaderboard.isEmpty
                  ? const Padding(
                    padding: EdgeInsets.all(30.0),
                    child: Column(
                      children: [
                        Text("📭", style: TextStyle(fontSize: 40)),
                        SizedBox(height: 10),
                        Text(
                          "The podium is empty!",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                  : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _leaderboard.length,
                    separatorBuilder:
                        (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final entry = _leaderboard[index];
                      final double totalCO2 =
                          (entry['totalCO2'] as num).toDouble();
                      final bool isEligible = totalCO2 > 0;
                      final int rank = index + 1;
                      final double percentage = (totalCO2 / maxCO2).clamp(
                        0.05,
                        1.0,
                      );

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor:
                              isEligible ? Colors.green[100] : Colors.grey[200],
                          child: Text(
                            _getMedal(rank),
                            style: TextStyle(
                              fontSize: rank <= 3 ? 20 : 14,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              entry['username'] ?? 'Unknown',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isEligible ? Colors.black : Colors.grey,
                              ),
                            ),
                            if (isEligible && rank == 1)
                              const Text(" 👑", style: TextStyle(fontSize: 14)),
                          ],
                        ),
                        subtitle:
                            isEligible
                                ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 5),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(5),
                                      child: LinearProgressIndicator(
                                        value: percentage,
                                        backgroundColor: Colors.grey[200],
                                        color:
                                            rank == 1
                                                ? Colors.amber
                                                : Colors.green,
                                        minHeight: 6,
                                      ),
                                    ),
                                  ],
                                )
                                : const Text(
                                  "No data calculated this week",
                                  style: TextStyle(fontSize: 12),
                                ),
                        trailing: Text(
                          isEligible
                              ? "${totalCO2.toStringAsFixed(2)} kg"
                              : "Pending",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                isEligible ? Colors.blueGrey[800] : Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }
}
