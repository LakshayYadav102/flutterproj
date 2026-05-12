import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';

class FoodWasteDrawer extends StatefulWidget {
  const FoodWasteDrawer({super.key});

  @override
  _FoodWasteDrawerState createState() => _FoodWasteDrawerState();
}

class _FoodWasteDrawerState extends State<FoodWasteDrawer> {
  String? _profilePic;
  String _username = "Eco Hero";
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      setState(() {
        _isLoggedIn = token != null;
        _username = prefs.getString('username') ?? "Eco Hero";
      });

      if (token != null) {
        final res = await http.get(
          Uri.parse('${ApiService.baseUrl}/api/profile'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);

          setState(() {
            if (data['username'] != null &&
                data['username'].toString().isNotEmpty) {
              _username = data['username'];
            } else if (data['name'] != null &&
                data['name'].toString().isNotEmpty) {
              _username = data['name'];
            }

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

  void _navigate(BuildContext context, String path) {
    Navigator.pop(context); // Close the drawer first
    if (_isLoggedIn) {
      Navigator.pushNamed(context, path);
    } else {
      Navigator.pushNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.amber[50], // Themed background
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.amber[800],
                image: const DecorationImage(
                  image: AssetImage(
                    'assets/images/food-waste.png',
                  ), // Use your asset if available, else remove this line
                  fit: BoxFit.cover,
                  opacity: 0.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => _navigate(context, '/food-waste/profile'),
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
                                    color: Colors.amber,
                                  )
                                  : Text(
                                    _username[0].toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 30,
                                      color: Colors.amber[800],
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
                    "Food Rescue Network",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

            ListTile(
              leading: Icon(
                Icons.volunteer_activism,
                color: Colors.amber[900],
                size: 26,
              ),
              title: const Text(
                'Donate Food',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () => _navigate(context, '/food-waste/donate'),
            ),

            ListTile(
              leading: Icon(
                Icons.local_dining,
                color: Colors.amber[900],
                size: 26,
              ),
              title: const Text(
                'Need Food',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () => _navigate(context, '/food-waste/require'),
            ),

            ListTile(
              leading: Icon(
                Icons.list_alt_rounded,
                color: Colors.amber[900],
                size: 26,
              ),
              title: const Text(
                'My Donations',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () => _navigate(context, '/food-waste/my-donations'),
            ),

            ListTile(
              leading: Icon(Icons.person, color: Colors.amber[900], size: 26),
              title: const Text(
                'Profile',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () => _navigate(context, '/food-waste/profile'),
            ),

            const Divider(height: 30, thickness: 1),

            ListTile(
              leading: const Icon(Icons.home, color: Colors.green, size: 26),
              title: const Text(
                'Return to GreenVerse',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
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
