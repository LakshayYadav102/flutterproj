import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api/api_service.dart'; // Import ApiService for baseUrl

class LeaderboardScreen extends StatefulWidget {
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
        Uri.parse(
          "${ApiService.baseUrl}/api/leaderboard",
        ), // Use dynamic base URL
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        backgroundColor: Colors.green,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
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
                      onPressed: fetchLeaderboard,
                      child: const Text("Retry"),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                itemCount: leaderboard.length,
                itemBuilder: (context, index) {
                  final user = leaderboard[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          user['profilePic'] != null
                              ? NetworkImage(user['profilePic'])
                              : const AssetImage('assets/default_profile.png')
                                  as ImageProvider, // Default image
                      radius: 25,
                    ),
                    title: Text(user['username']),
                    subtitle: Text(
                      'Carbon Footprint: ${user['totalEmission']} kg CO₂',
                    ),
                    trailing: Text(
                      "#${index + 1}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
