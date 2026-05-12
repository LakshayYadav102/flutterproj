import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../api/api_service.dart';

class GreenverseDrawer extends StatefulWidget {
  const GreenverseDrawer({super.key});

  @override
  _GreenverseDrawerState createState() => _GreenverseDrawerState();
}

class _GreenverseDrawerState extends State<GreenverseDrawer> {
  int coins = 0;
  String? profilePic;
  String username = "Eco Warrior";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token != null) {
      try {
        // Fetch Wallet
        final walletResponse = await http.get(
          Uri.parse('${ApiService.baseUrl}/api/profile/wallet'),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (walletResponse.statusCode == 200) {
          setState(() {
            coins = jsonDecode(walletResponse.body)['greenCoins'] ?? 0;
          });
        }

        // Fetch Profile
        final profileResponse = await http.get(
          Uri.parse('${ApiService.baseUrl}/api/profile'),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (profileResponse.statusCode == 200) {
          final data = jsonDecode(profileResponse.body);
          setState(() {
            username = data['username'] ?? "Eco Warrior";
            if (data['profilePic'] != null) {
              String picUrl = data['profilePic'];
              profilePic =
                  picUrl.startsWith('http')
                      ? picUrl
                      : '${ApiService.baseUrl}$picUrl';
            }
          });
        }
      } catch (e) {
        debugPrint("Error fetching drawer profile data: $e");
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  void _handleLogout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userId');
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Colors.green),
            accountName: Text(
              username,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: Row(
              children: [
                const Icon(
                  Icons.monetization_on,
                  color: Colors.amber,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text("$coins GreenCoins"),
              ],
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage:
                  profilePic != null ? NetworkImage(profilePic!) : null,
              child:
                  profilePic == null
                      ? Text(
                        username[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 24,
                        ),
                      )
                      : null,
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.dashboard,
                  title: "GreenTrail",
                  route: "/dashboard",
                ),
                _buildDrawerItem(
                  icon: Icons.directions_car,
                  title: "Carpooling & EV",
                  route: "/carpool",
                ),
                _buildDrawerItem(
                  icon: Icons.fastfood,
                  title: "Food Rescue",
                  route: "/food-waste",
                ),
                _buildDrawerItem(
                  icon: Icons.view_in_ar,
                  title: "GreenScan",
                  route: "https://greenversear.netlify.app/",
                  isExternal: true,
                ),
                _buildDrawerItem(
                  icon: Icons.school,
                  title: "GreenStream",
                  route: "/ecolearn/feed",
                ),
                const Divider(),
                _buildDrawerItem(
                  icon: Icons.storefront,
                  title: "EcoStore",
                  route: "/store",
                ),
                _buildDrawerItem(
                  icon: Icons.article,
                  title: "Blogs",
                  route: "/blogs",
                ),
                _buildDrawerItem(
                  icon: Icons.account_balance_wallet,
                  title: "Wallet",
                  route: "/wallet",
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout", style: TextStyle(color: Colors.red)),
            onTap: () => _handleLogout(context),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    String? route,
    bool isExternal = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.green[700]),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      onTap: () async {
        Navigator.pop(context); // Close the drawer first

        if (isExternal && route != null) {
          final Uri url = Uri.parse(route);
          try {
            if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not open link')),
                );
              }
            }
          } catch (e) {
            debugPrint("Error launching URL: $e");
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not open link')),
              );
            }
          }
        } else if (route != null) {
          Navigator.pushNamed(context, route);
        }
      },
    );
  }
}
