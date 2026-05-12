import 'package:flutter/material.dart';

class CarpoolBottomNav extends StatelessWidget {
  final int currentIndex;

  const CarpoolBottomNav({super.key, required this.currentIndex});

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return; // Don't navigate if already there

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/carpool');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/ride/find');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/ride/offer');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/my-trips');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/ev-stations');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _onItemTapped(context, index),
      type: BottomNavigationBarType.fixed, // Allows more than 3 items
      backgroundColor: Colors.white,
      selectedItemColor: Colors.teal[700],
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Hub"),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: "Find"),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle_outline),
          label: "Offer",
        ),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: "Trips"),
        BottomNavigationBarItem(icon: Icon(Icons.ev_station), label: "EV"),
      ],
    );
  }
}
