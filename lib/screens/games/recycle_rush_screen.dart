import 'package:flutter/material.dart';

class TrashItem {
  final int id;
  final String name;
  final String type;
  final String img;

  TrashItem({
    required this.id,
    required this.name,
    required this.type,
    required this.img,
  });
}

class RecycleRushScreen extends StatefulWidget {
  const RecycleRushScreen({Key? key}) : super(key: key);

  @override
  _RecycleRushScreenState createState() => _RecycleRushScreenState();
}

class _RecycleRushScreenState extends State<RecycleRushScreen> {
  final List<TrashItem> trashItems = [
    TrashItem(
      id: 1,
      name: "Plastic Bottle",
      type: "recycle",
      img: "assets/images/plastic-bottle.png",
    ),
    TrashItem(
      id: 2,
      name: "Banana Peel",
      type: "compost",
      img: "assets/images/banana-peel.png",
    ),
    TrashItem(
      id: 3,
      name: "Glass Bottle",
      type: "recycle",
      img: "assets/images/glass-bottle.png",
    ),
    TrashItem(
      id: 4,
      name: "Tin Can",
      type: "recycle",
      img: "assets/images/tin-can.png",
    ),
    TrashItem(
      id: 5,
      name: "Newspaper",
      type: "recycle",
      img: "assets/images/newspaper.png",
    ),
    TrashItem(
      id: 6,
      name: "Food Waste",
      type: "compost",
      img: "assets/images/food-waste.png",
    ),
    TrashItem(
      id: 7,
      name: "Plastic Bag",
      type: "waste",
      img: "assets/images/plastic-bag.png",
    ),
    TrashItem(
      id: 8,
      name: "Styrofoam Cup",
      type: "waste",
      img: "assets/images/styrofoam-cup.png",
    ),
  ];

  int score = 0;
  int attempts = 0;
  bool gameOver = false;
  final int maxAttempts = 5;

  void handleDrop(String binType, TrashItem item) {
    setState(() {
      if (item.type == binType) {
        score += 10;
      } else {
        attempts += 1;
        if (attempts >= maxAttempts) gameOver = true;
      }
    });
  }

  void restartGame() {
    setState(() {
      score = 0;
      attempts = 0;
      gameOver = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Recycle Rush"),
        backgroundColor: isDarkMode ? Colors.green[800] : Colors.green,
      ),
      body: SingleChildScrollView(
        child: Container(
          color: const Color(0xFFE3F2D4),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                "♻️ Recycle Rush - Sort the Waste!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C6E49),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                "Drag and drop the items into the correct bins.",
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Responsive grid-like layout for items
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children:
                    trashItems.map((item) {
                      return Draggable<TrashItem>(
                        data: item,
                        feedback: Image.asset(item.img, width: 70, height: 70),
                        childWhenDragging: Opacity(
                          opacity: 0.5,
                          child: Image.asset(item.img, width: 70, height: 70),
                        ),
                        child: Image.asset(item.img, width: 70, height: 70),
                      );
                    }).toList(),
              ),

              const SizedBox(height: 30),

              // Drop bins
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 20,
                runSpacing: 20,
                children: [
                  _buildBin("recycle", Colors.green, "♻️ Recyclable"),
                  _buildBin("compost", Colors.orange, "🌱 Compost"),
                  _buildBin("waste", Colors.red, "🗑️ Waste"),
                ],
              ),

              const SizedBox(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Score: $score", style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 20),
                  Text(
                    "Attempts Left: ${maxAttempts - attempts}",
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),

              if (gameOver)
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(color: Colors.grey.shade400, blurRadius: 5),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Game Over!",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Your Final Score: $score",
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: restartGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2C6E49),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Play Again"),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBin(String binType, Color color, String label) {
    return DragTarget<TrashItem>(
      onAccept: (item) => handleDrop(binType, item),
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: 100,
          height: 130,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(10),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }
}
