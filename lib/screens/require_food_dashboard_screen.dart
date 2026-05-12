import 'dart:async';
import 'package:flutter/material.dart';

class RequireFoodDashboardScreen extends StatefulWidget {
  const RequireFoodDashboardScreen({super.key});

  @override
  _RequireFoodDashboardScreenState createState() =>
      _RequireFoodDashboardScreenState();
}

class _RequireFoodDashboardScreenState
    extends State<RequireFoodDashboardScreen> {
  String _quoteText = "";
  int _quoteIndex = 0;

  final List<String> _quotes = [
    "Connecting surplus with necessity.",
    "Good food belongs to people, not landfills.",
    "Claim a meal, save the planet.",
    "Every rescued meal reduces your carbon footprint.",
    "Community support, one plate at a time.",
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
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text("Receive Surplus Food"),
        backgroundColor: Colors.blue[800],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.blue[300]!),
              ),
              child: Column(
                children: [
                  const Text(
                    "Food Retrieval Portal",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "$_quoteText|",
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ✅ Available Food
            _buildActionCard(
              title: "Available Food",
              desc:
                  "Browse current food donations ready for immediate pickup or delivery in your local area.",
              icon: Icons.fastfood,
              color: Colors.blue,
              bullets: [
                "Household & event surplus",
                "Time-sensitive availability",
                "Verified local listings",
              ],
              btnText: "View Available Food",
              onTap:
                  () => Navigator.pushNamed(context, '/food-waste/available'),
            ),

            // ✅ NGOs
            _buildActionCard(
              title: "Nearby NGOs",
              desc:
                  "Find trusted organizations and community kitchens that provide regular food support.",
              icon: Icons.map,
              color: Colors.teal,
              bullets: [
                "Community kitchens",
                "Charity food centers",
                "Local shelters",
              ],
              btnText: "Locate NGOs",
              onTap: () => Navigator.pushNamed(context, '/food-waste/ngos'),
            ),

            // ✅ Received Food
            _buildActionCard(
              title: "My Received Food",
              desc:
                  "Track the food you’ve successfully claimed and view your positive environmental impact.",
              icon: Icons.history,
              color: Colors.purple,
              bullets: [
                "Past accepted donations",
                "Carbon impact tracking",
                "Quick re-requests",
              ],
              btnText: "View History",
              onTap: () => Navigator.pushNamed(context, '/food-waste/received'),
            ),

            // Footer
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified_user, color: Colors.blue, size: 30),
                  const SizedBox(width: 15),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Safety & Transparency",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "All food coordination is handled through verified partners to ensure safety.",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required List<String> bullets,
    required String btnText,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.2),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(desc, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            ...bullets.map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.check, size: 16, color: color),
                    const SizedBox(width: 8),
                    Text(b, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: color),
                onPressed: onTap,
                child: Text(
                  btnText,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
