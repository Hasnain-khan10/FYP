import 'package:flutter/material.dart';
import 'package:frontened/models/Quiz/quiz_model.dart'; // Adjust path if needed

class TeacherQuizPreviewScreen extends StatelessWidget {
  final Quiz quiz;

  const TeacherQuizPreviewScreen({super.key, required this.quiz});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Modern Premium Gray
      appBar: AppBar(
        title: const Text("Exam Key Preview", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF4F46E5),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------- HEADER SUMMARY ----------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
                border: Border.all(color: const Color(0xFF4F46E5).withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(quiz.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
                  if (quiz.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(quiz.description, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                  ],
                  const Divider(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBadge(Icons.analytics, "Type: ${quiz.type.toUpperCase()}", Colors.blue),
                      _buildBadge(Icons.military_tech, "Total Marks: ${quiz.totalMarks}", Colors.green),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ---------------- RENDER MCQs ----------------
            if (quiz.questions.isNotEmpty) ...[
              const Text("Multiple Choice Section", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 12),
              ...quiz.questions.asMap().entries.map((entry) => _buildMcqCard(entry.value, entry.key + 1)),
              const SizedBox(height: 24),
            ],

            // ---------------- RENDER SHORT QUESTIONS ----------------
            if (quiz.shortQuestions.isNotEmpty) ...[
              const Text("Short Answer Section", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 12),
              ...quiz.shortQuestions.asMap().entries.map((entry) => _buildSubjectiveCard(entry.value, entry.key + 1, "Short")),
              const SizedBox(height: 24),
            ],

            // ---------------- RENDER LONG QUESTIONS ----------------
            if (quiz.longQuestions.isNotEmpty) ...[
              const Text("Long Essay Section", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 12),
              ...quiz.longQuestions.asMap().entries.map((entry) => _buildSubjectiveCard(entry.value, entry.key + 1, "Long")),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  // Helper: Mini Badge
  Widget _buildBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  // Helper: Premium MCQ Card
  Widget _buildMcqCard(McqQuestion q, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question Statement
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(radius: 14, backgroundColor: const Color(0xFF4F46E5), child: Text("$index", style: const TextStyle(color: Colors.white, fontSize: 12))),
              const SizedBox(width: 12),
              Expanded(child: Text(q.question, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
              Text("(${q.marks} Marks)", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          // Options
          ...q.options.entries.map((opt) {
            bool isCorrect = opt.key == q.correctAnswer;
            if (opt.value.isEmpty || opt.value == "None") return const SizedBox.shrink();
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isCorrect ? Colors.green.withValues(alpha: 0.1) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isCorrect ? Colors.green : Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Text("${opt.key}.", style: TextStyle(fontWeight: FontWeight.bold, color: isCorrect ? Colors.green : Colors.black87)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(opt.value, style: TextStyle(color: isCorrect ? Colors.green.shade800 : Colors.black87))),
                  if (isCorrect) const Icon(Icons.check_circle, color: Colors.green, size: 20),
                ],
              ),
            );
          }),
          // 🔥 AI RATIONALE / EXPLANATION
          if (q.explanation.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.blue.shade100)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb, color: Colors.blue, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("AI Rationale:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                        const SizedBox(height: 4),
                        Text(q.explanation, style: TextStyle(fontSize: 13, color: Colors.blue.shade900)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  // Helper: Premium Subjective Card
  Widget _buildSubjectiveCard(SubjectiveQuestion q, int index, String type) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(radius: 14, backgroundColor: Colors.teal, child: Text("$index", style: const TextStyle(color: Colors.white, fontSize: 12))),
              const SizedBox(width: 12),
              Expanded(child: Text(q.question, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
              Text("(${q.marks} Marks)", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          // 🔥 IDEAL ANSWER
          if (q.idealAnswer.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.green.shade100)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [Icon(Icons.check_circle_outline, color: Colors.green, size: 18), SizedBox(width: 8), Text("Ideal Solution:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))]),
                  const SizedBox(height: 6),
                  Text(q.idealAnswer, style: TextStyle(fontSize: 13, color: Colors.green.shade900)),
                ],
              ),
            ),
          // 🔥 GRADING RUBRIC
          if (q.rubric.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.purple.shade100)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [Icon(Icons.rule, color: Colors.purple, size: 18), SizedBox(width: 8), Text("Grading Rubric:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple))]),
                  const SizedBox(height: 6),
                  Text(q.rubric, style: TextStyle(fontSize: 13, color: Colors.purple.shade900)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}