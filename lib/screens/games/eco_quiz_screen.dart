import 'package:flutter/material.dart';
import 'dart:async';

class QuizQuestion {
  final String question;
  final List<String> options;
  final String answer;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.answer,
  });
}

class EcoQuizScreen extends StatefulWidget {
  const EcoQuizScreen({Key? key}) : super(key: key);

  @override
  _EcoQuizScreenState createState() => _EcoQuizScreenState();
}

class _EcoQuizScreenState extends State<EcoQuizScreen> {
  final List<QuizQuestion> questions = [
    QuizQuestion(
      question: "What is the main cause of global warming?",
      options: [
        "Deforestation",
        "Burning fossil fuels",
        "Plastic waste",
        "Overfishing",
      ],
      answer: "Burning fossil fuels",
    ),
    QuizQuestion(
      question: "Which of these materials is NOT biodegradable?",
      options: ["Banana Peel", "Glass Bottle", "Cotton Cloth", "Paper"],
      answer: "Glass Bottle",
    ),
    QuizQuestion(
      question: "How much of Earth's water is freshwater?",
      options: ["3%", "10%", "25%", "50%"],
      answer: "3%",
    ),
  ];

  int currentQuestion = 0;
  int score = 0;
  String? selectedOption;
  bool quizOver = false;

  void handleAnswerClick(String option) {
    setState(() {
      selectedOption = option;
      if (option == questions[currentQuestion].answer) {
        score += 1;
      }
    });

    Timer(const Duration(seconds: 1), () {
      setState(() {
        if (currentQuestion + 1 < questions.length) {
          currentQuestion += 1;
          selectedOption = null;
        } else {
          quizOver = true;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Eco Quiz"),
        backgroundColor: isDarkMode ? Colors.teal[800] : Colors.teal,
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Center(
          child:
              quizOver
                  ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Quiz Over!",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Your Score: $score / ${questions.length}",
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Back to Games"),
                      ),
                    ],
                  )
                  : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "🌿 Eco Quiz Challenge",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C7A7B),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        questions[currentQuestion].question,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ...questions[currentQuestion].options.map((option) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: ElevatedButton(
                            onPressed:
                                selectedOption == null
                                    ? () => handleAnswerClick(option)
                                    : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  selectedOption == option
                                      ? Colors.orange
                                      : Colors.green,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            child: Text(option),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
        ),
      ),
    );
  }
}
