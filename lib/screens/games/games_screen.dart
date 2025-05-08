import 'package:flutter/material.dart';
import './recycle_rush_screen.dart';
import './eco_quiz_screen.dart';
import './eco_runner_screen.dart';

class GamesScreen extends StatelessWidget {
  const GamesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Eco Games",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor:
            isDarkMode ? Colors.deepPurple[800] : Colors.deepPurple,
        elevation: 10,
        shadowColor: Colors.deepPurple.withOpacity(0.5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, "Choose a Game"),
            const SizedBox(height: 16),
            _buildGameGrid(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onBackground,
        ),
      ),
    );
  }

  Widget _buildGameGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.2, // Fixed typo: Removed "OUNCE"
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildGameCard(
          context: context,
          icon: Icons.recycling_rounded,
          title: "Recycle Rush",
          color: Colors.green,
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RecycleRushScreen()),
              ),
        ),
        _buildGameCard(
          context: context,
          icon: Icons.quiz_rounded,
          title: "Eco Quiz",
          color: Colors.teal,
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EcoQuizScreen()),
              ),
        ),
        _buildGameCard(
          context: context,
          icon: Icons.directions_run_rounded,
          title: "Eco Runner",
          color: Colors.blue,
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EcoRunnerScreen()),
              ),
        ),
      ],
    );
  }

  Widget _buildGameCard({
    required BuildContext context,
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
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
