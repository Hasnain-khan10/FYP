import 'package:flutter/material.dart';

class QuizTipsScreen extends StatelessWidget {
  const QuizTipsScreen({super.key});
  static const String routeName = '/quiz-tips';

  @override
  Widget build(BuildContext context) {
    // In future, you can pass actual dynamic AI feedback string via arguments here.
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0, backgroundColor: const Color(0xFF4F46E5),
        title: const Text("AI Performance Review", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity, padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)]), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: const Color(0xFF7C3AED).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))]),
              child: Row(
                children: [
                  Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle), child: const Icon(Icons.auto_awesome, color: Colors.white, size: 30)),
                  const SizedBox(width: 16),
                  const Expanded(child: Text("Based on your answers, AI has generated personalized tips to help you improve.", style: TextStyle(color: Colors.white, fontSize: 15, height: 1.4))),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text("Actionable Insights", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B))),
            const SizedBox(height: 16),

            Expanded(
              child: ListView(
                children: const [
                  TipCard(title: "Concept Clarity Required", description: "You answered incorrectly in Core Programming questions. Consider revising Object-Oriented concepts."),
                  SizedBox(height: 12),
                  TipCard(title: "Time Management", description: "You skipped a few questions. Try to allocate a maximum of 45 seconds per MCQ."),
                  SizedBox(height: 12),
                  TipCard(title: "Strength Identified", description: "Great job on Database concepts! Your accuracy in that section was 100%."),
                ],
              ),
            ),

            SizedBox(
              width: double.infinity, height: 55,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Text("Back to Results", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class TipCard extends StatelessWidget {
  final String title; final String description;
  const TipCard({super.key, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, color: Color(0xFFF59E0B), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E1B4B))),
                const SizedBox(height: 6),
                Text(description, style: const TextStyle(color: Colors.grey, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}