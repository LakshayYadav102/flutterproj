import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'leaderboard_screen.dart';
import 'blog_list_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import 'carbon_calculator_screen.dart';
import 'user_activity_screen.dart';
import 'graph_component.dart';
import '../widgets/weather_aqi_widget.dart';
import 'Object_Detection_Screen.dart';

class DashboardScreen extends StatefulWidget {
  final String userId;

  const DashboardScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? storedUserId;
  String? storedUsername;
  String? profilePic;
  String? token;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      storedUserId = prefs.getString('userId');
      storedUsername = prefs.getString('username');
      token = prefs.getString('token');
    });

    if (token != null) {
      await _fetchProfilePicture();
    }
  }

  Future<void> _fetchProfilePicture() async {
    try {
      final response = await http.get(
        Uri.parse("http://10.0.2.2:5000/api/profile"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        setState(() {
          profilePic = userData['profilePic'] != null
              ? "http://10.0.2.2:5000${userData['profilePic']}"
              : null;
        });
      }
    } catch (e) {
      print("Error fetching profile picture: $e");
    }
  }

  void _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Eco Dashboard", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isDarkMode ? Colors.deepPurple[800] : Colors.deepPurple,
        elevation: 10,
        shadowColor: Colors.deepPurple.withOpacity(0.5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      ),
      drawer: _buildDrawer(isDarkMode),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeHeader(),
              const SizedBox(height: 24),
              const WeatherAqiWidget(),
              const SizedBox(height: 24),
              _buildSectionTitle("Quick Actions"),
              const SizedBox(height: 16),
              _buildActionGrid(),
              const SizedBox(height: 24),
              _buildSectionTitle("Your Impact"),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: GraphComponent(userId: storedUserId ?? ''),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ObjectDetectionScreen()),
          );
        },
        backgroundColor: isDarkMode ? Colors.deepPurple[800] : Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.white, width: 2),
        ),
        child: const Icon(Icons.camera_alt_rounded, size: 28),
      ),
    );
  }

  Widget _buildDrawer(bool isDarkMode) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : Colors.white,
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDarkMode
                      ? [Colors.deepPurple[800]!, Colors.deepPurple[600]!]
                      : [Colors.deepPurple, Colors.purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProfileScreen()),
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: profilePic != null
                          ? NetworkImage(profilePic!)
                          : const AssetImage("assets/default-avatar.png") as ImageProvider,
                      child: profilePic == null
                          ? const Icon(Icons.person_rounded,
                                     size: 40,
                                     color: Colors.deepPurple)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text("Welcome!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      )),
                  Text(storedUsername ?? 'Guest',
                      style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            _buildDrawerTile(Icons.article_rounded, "Blogs", () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => BlogListScreen()));
            }),
            _buildDrawerTile(Icons.leaderboard_rounded, "Leaderboard", () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const LeaderboardScreen()));
            }),
            _buildDrawerTile(Icons.person_rounded, "Profile", () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen()));
            }),
            Divider(color: Colors.grey[600]),
            _buildDrawerTile(Icons.logout_rounded, "Logout", _logout),
          ],
        ),
      ),
    );
  }

  ListTile _buildDrawerTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).iconTheme.color),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      onTap: onTap,
      hoverColor: Colors.deepPurple.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.deepPurple, Colors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Welcome Back!",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              )),
          const SizedBox(height: 8),
          Text("Username: ${storedUsername ?? 'Guest'}",
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              )),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Text(title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onBackground,
          )),
    );
  }

 Widget _buildActionGrid() {
   return GridView.count(
     shrinkWrap: true,
     physics: const NeverScrollableScrollPhysics(),
     crossAxisCount: 2,
     childAspectRatio: 1.2,
     mainAxisSpacing: 16,
     crossAxisSpacing: 16,
     children: [
       _buildActionCard(
         icon: Icons.calculate_rounded,
         title: "Carbon Calculator",
         color: Colors.deepPurple,
         onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CarbonCalculatorScreen())),
       ),
       _buildActionCard(
         icon: Icons.history_rounded,
         title: "User Activity",
         color: Colors.green,
         onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => UserActivityScreen(userId: storedUserId ?? ''))),
       ),
       _buildActionCard(
         icon: Icons.show_chart_rounded,
         title: "Footprint Graph",
         color: Colors.blue,
         onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => GraphComponent(userId: storedUserId ?? ''))),
       ),
     ],
   );
 }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.9), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(height: 12),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}