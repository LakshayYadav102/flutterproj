import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';

// ✅ IMPORT your Games Screen here (adjust path if necessary)
import '../screens/games/games_screen.dart';

class GreentrailDrawer extends StatefulWidget {
  const GreentrailDrawer({super.key});

  @override
  _GreentrailDrawerState createState() => _GreentrailDrawerState();
}

class _GreentrailDrawerState extends State<GreentrailDrawer> {
  String? _profilePic;
  String _username = "Eco Warrior"; // Default fallback
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      // Try to get it from local storage first so UI loads fast
      setState(() {
        _username = prefs.getString('username') ?? "Eco Warrior";
      });

      if (token != null) {
        final res = await http.get(
          Uri.parse('${ApiService.baseUrl}/api/profile'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);

          setState(() {
            // ✅ FIX 2: Override the username with the REAL name from the database
            if (data['username'] != null &&
                data['username'].toString().isNotEmpty) {
              _username = data['username'];
            } else if (data['name'] != null &&
                data['name'].toString().isNotEmpty) {
              _username = data['name'];
            }

            // Set Profile Picture
            if (data['profilePic'] != null) {
              String picUrl = data['profilePic'];
              _profilePic =
                  picUrl.startsWith('http')
                      ? picUrl
                      : '${ApiService.baseUrl}$picUrl';
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching profile for drawer: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.green[50],
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.green[800],
                image: const DecorationImage(
                  image: AssetImage('assets/images/home.jpg'),
                  fit: BoxFit.cover,
                  opacity: 0.3,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/profile'),
                    child: CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white,
                      backgroundImage:
                          _profilePic != null
                              ? NetworkImage(_profilePic!)
                              : null,
                      child:
                          _profilePic == null
                              ? (_isLoading
                                  ? const CircularProgressIndicator(
                                    color: Colors.green,
                                  )
                                  : Text(
                                    _username[0].toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 30,
                                      color: Colors.green[800],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ))
                              : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "GreenTrail Dashboard",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Text("🏆", style: TextStyle(fontSize: 20)),
              title: const Text(
                'Leaderboard',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/leaderboard');
              },
            ),

            // ✅ FIX 1: Directly push the GamesScreen using MaterialPageRoute
            ListTile(
              leading: const Text("🎮", style: TextStyle(fontSize: 20)),
              title: const Text(
                'Games',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(context); // Close Drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GamesScreen()),
                );
              },
            ),

            ListTile(
              leading: const Text("👤", style: TextStyle(fontSize: 20)),
              title: const Text(
                'Profile',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Text("🏠", style: TextStyle(fontSize: 20)),
              title: const Text(
                'Return to GreenVerse',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/home');
              },
            ),
          ],
        ),
      ),
    );
  }
}
