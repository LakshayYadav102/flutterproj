import 'package:flutter/material.dart';
import '../widgets/ev_map_widget.dart';
import '../widgets/carpool_bottom_nav.dart';

class EVStationsScreen extends StatelessWidget {
  const EVStationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFF1A1A2E,
      ), // Dark slate background matching the web CSS
      appBar: AppBar(
        title: const Text(
          "EV Charging Stations",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 10.0,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.yellow.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.electric_bolt,
                        color: Colors.yellow,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "Charge Up",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  "Locate nearby fast and standard charging points for your electric vehicle.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),

          // The Interactive Map Widget
          const Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(35),
                topRight: Radius.circular(35),
              ),
              child: EVMapWidget(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CarpoolBottomNav(currentIndex: 4),
    );
  }
}
