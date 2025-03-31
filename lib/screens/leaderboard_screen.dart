import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<dynamic> leaderboard = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchLeaderboard();
  }

  // Function to fetch leaderboard data from the backend
  Future<void> fetchLeaderboard() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:5000/api/leaderboard'));

    if (response.statusCode == 200) {
      setState(() {
        leaderboard = json.decode(response.body);
        isLoading = false;
      });
    } else {
      // Handle the error case
      setState(() {
        isLoading = false;
      });
      print('Failed to load leaderboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        backgroundColor: Colors.deepPurple,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: leaderboard.length,
              itemBuilder: (context, index) {
                final user = leaderboard[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user['profilePic'] != null
                        ? NetworkImage(user['profilePic'])
                        : const AssetImage('assets/default-avatar.png') as ImageProvider,
                  ),
                  title: Text(user['username']),
                  subtitle: Text('Carbon Footprint: ${user['carbonFootprint']} kg'),
                  trailing: Text('#${index + 1}'),
                );
              },
            ),
    );
  }
}
