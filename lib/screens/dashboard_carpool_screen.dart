import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/carpool_bottom_nav.dart'; // Ensure correct path

class DashboardCarpoolScreen extends StatefulWidget {
  const DashboardCarpoolScreen({super.key});

  @override
  _DashboardCarpoolScreenState createState() => _DashboardCarpoolScreenState();
}

class _DashboardCarpoolScreenState extends State<DashboardCarpoolScreen> {
  String _quoteText = "";
  int _quoteIndex = 0;
  final List<String> _quotes = [
    "Share the ride, split the emissions.",
    "Fewer cars today, a greener tomorrow.",
    "Your journey towards sustainable travel.",
    "Connect, commute, and conserve.",
    "Driving change, one shared seat at a time.",
  ];

  final List<Map<String, dynamic>> _buttons = [
    {
      "id": "offer",
      "label": "Offer a Ride",
      "path": "/ride/offer",
      "icon": Icons.local_taxi,
      "color": Colors.green,
      "desc": "Share your journey and save costs",
    },
    {
      "id": "find",
      "label": "Find a Ride",
      "path": "/ride/find",
      "icon": Icons.search,
      "color": Colors.blue,
      "desc": "Join others going your way",
    },
    {
      "id": "ev",
      "label": "EV Stations",
      "path": "/ev-stations",
      "icon": Icons.ev_station,
      "color": Colors.teal,
      "desc": "Locate charging points nearby",
    },
    {
      "id": "mytrips",
      "label": "My Trips",
      "path": "/my-trips",
      "icon": Icons.history,
      "color": Colors.orange,
      "desc": "View offered and booked rides",
    },
    {
      "id": "request",
      "label": "Request a Ride",
      "path": "/ride-request", // ✅ FIXED PATH
      "icon": Icons.waving_hand,
      "color": Colors.purple,
      "desc": "Post a request for drivers",
    },
  ];

  @override
  void initState() {
    super.initState();
    _startTypingEffect();
  }

  void _startTypingEffect() async {
    while (mounted) {
      String fullQuote = _quotes[_quoteIndex];
      for (int i = 0; i <= fullQuote.length; i++) {
        if (!mounted) return;
        setState(() => _quoteText = fullQuote.substring(0, i));
        await Future.delayed(const Duration(milliseconds: 80));
      }
      await Future.delayed(const Duration(seconds: 2));
      for (int i = fullQuote.length; i >= 0; i--) {
        if (!mounted) return;
        setState(() => _quoteText = fullQuote.substring(0, i));
        await Future.delayed(const Duration(milliseconds: 40));
      }
      _quoteIndex = (_quoteIndex + 1) % _quotes.length;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        title: const Text("Carpooling Hub"),
        backgroundColor: Colors.teal[700],
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.teal[700],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                const Icon(Icons.directions_car, size: 60, color: Colors.white),
                const SizedBox(height: 10),
                const Text(
                  "Eco-Transit",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "$_quoteText|",
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: _buttons.length,
              itemBuilder: (context, index) {
                final btn = _buttons[index];
                return GestureDetector(
                  onTap: () {
                    // ✅ FIXED NAVIGATION
                    Navigator.pushNamed(context, btn['path']);
                  },
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: btn['color'].withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: btn['color'].withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              btn['icon'],
                              color: btn['color'],
                              size: 36,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            btn['label'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            btn['desc'],
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CarpoolBottomNav(
        currentIndex: 0,
      ), // ✅ ADDED NAVBAR
    );
  }
}
