import 'dart:async';
import 'package:flutter/material.dart';

class DonateFoodDashboardScreen extends StatefulWidget {
  const DonateFoodDashboardScreen({super.key});

  @override
  _DonateFoodDashboardScreenState createState() =>
      _DonateFoodDashboardScreenState();
}

class _DonateFoodDashboardScreenState extends State<DonateFoodDashboardScreen> {
  String _quoteText = "";
  int _quoteIndex = 0;

  final List<String> _quotes = [
    "Share your surplus, multiply your impact.",
    "From leftovers to lifelines.",
    "Small donations, massive community impact.",
    "Don't throw it out, pass it on.",
    "Feed people, not landfills.",
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
      backgroundColor: Colors.orange[50],
      appBar: AppBar(
        title: const Text("Donate Surplus Food"),
        backgroundColor: Colors.orange[800],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Animated Text
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.orange),
              ),
              child: Text(
                "$_quoteText|",
                style: TextStyle(
                  color: Colors.orange[800],
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),

            // ✅ Household
            _buildDonationCard(
              title: "Household Donation",
              desc:
                  "Donate leftover or excess food from your home kitchen before it spoils.",
              icon: Icons.home,
              color: Colors.green,
              bullets: [
                "Cooked or raw ingredients",
                "Packaged grocery items",
                "Daily surplus management",
              ],
              btnText: "Donate from Home",
              onTap:
                  () => Navigator.pushNamed(
                    context,
                    '/food-waste/donate/household',
                  ),
            ),

            // ✅ Event
            _buildDonationCard(
              title: "Event / Bulk Donation",
              desc:
                  "Donate bulk surplus from large functions, weddings, and corporate parties.",
              icon: Icons.celebration,
              color: Colors.purple,
              bullets: [
                "Large catering quantities",
                "Time-sensitive pickup",
                "High community impact",
              ],
              btnText: "Donate Event Food",
              onTap:
                  () =>
                      Navigator.pushNamed(context, '/food-waste/donate/event'),
            ),

            // ✅ Analytics
            _buildDonationCard(
              title: "Donation Analytics",
              desc:
                  "Track your past donations and measure your direct environmental impact.",
              icon: Icons.analytics,
              color: Colors.blue,
              bullets: [
                "View accepted/expired history",
                "See total carbon offset",
                "Monitor your green score",
              ],
              btnText: "View Analytics",
              onTap:
                  () =>
                      Navigator.pushNamed(context, '/food-waste/my-donations'),
            ),

            // ✅ NGOs
            _buildDonationCard(
              title: "Locate Local NGOs",
              desc:
                  "Find nearby verified NGOs and community kitchens to donate food directly.",
              icon: Icons.map,
              color: Colors.red,
              bullets: [
                "Interactive map routing",
                "Verified community centers",
                "Direct contact details",
              ],
              btnText: "Find NGOs Near Me",
              onTap: () => Navigator.pushNamed(context, '/food-waste/ngos'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonationCard({
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
