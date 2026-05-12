import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EcoLearnBottomNav extends StatelessWidget {
  final int currentIndex;

  const EcoLearnBottomNav({super.key, required this.currentIndex});

  Future<void> _onItemTapped(BuildContext context, int index) async {
    if (index == currentIndex) return;

    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/ecolearn/feed');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/ecolearn/explore');
    } else if (index == 2) {
      Navigator.pushNamed(
        context,
        '/ecolearn/upload',
      ); // Push, not replace for upload modal effect
    } else if (index == 3) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');
      if (userId != null) {
        // We use push to allow going back to feed
        Navigator.pushNamed(context, '/ecolearn/creator', arguments: userId);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please log in to view your profile")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _onItemTapped(context, index),
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.black, // Dark mode aesthetic
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.grey[600],
      showSelectedLabels: true,
      showUnselectedLabels: true,
      items: [
        const BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        const BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: "Explore",
        ),
        // Custom styling for the center add button
        BottomNavigationBarItem(
          icon: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.add, color: Colors.black),
          ),
          label: "",
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: "Profile",
        ),
      ],
    );
  }
}
