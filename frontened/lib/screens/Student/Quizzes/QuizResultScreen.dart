import 'package:flutter/material.dart';
import 'package:frontened/models/Quiz/quiz_model.dart';
import 'package:frontened/screens/Student/Main_Screen.dart';

class QuizResultScreen extends StatelessWidget {
  const QuizResultScreen({super.key});
  static const String routeName = '/quiz-result';

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: InteractiveViewer(
          panEnabled: true,
          boundaryMargin: const EdgeInsets.all(20),
          minScale: 0.5,
          maxScale: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.network(imageUrl, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments;
    int score = 0;
    int total = 0;
    List review = [];
    bool isAIEvaluated = false;

    if (args is Map) {
      score = (args['score'] ?? 0).toInt();
      total = (args['total'] ?? 0).toInt();
      review = args['review'] ?? [];
    } else if (args is Quiz) {
      score = (args.score ?? 0).toInt();
      total = (args.totalMarks ?? 0).toInt();
      if (total == 0) total = args.questions.length;

      isAIEvaluated = args.evaluatedByAI ?? false;

      if (isAIEvaluated) {
        review = (args.selectedAnswers ?? []).map((ans) {
          return {
            "question": ans["question_text"] ?? "Descriptive Question",
            "selectedAnswer": ans["student_answer"] ?? "Checked via Paper Scan",
            "correctAnswer": ans["correct_answer"] ?? "Refer to AI Rubric",
            "isCorrect": (ans["obtained_marks"] ?? 0) > 0,
            "obtained_marks": ans["obtained_marks"] ?? 0,
            "max_marks": ans["max_marks"] ?? 0,
            "scannedImageUrl": ans["scannedImageUrl"],
            "aiFeedback": ans["aiFeedback"] ?? "", // 🔥 GET AI REASON FROM DB
          };
        }).toList();
      } else {
        review = (args.selectedAnswers ?? []).asMap().entries.map((e) {
          int index = e.key;
          var ans = e.value;
          if (index < args.questions.length) {
            var q = args.questions[index];
            return {
              "question": q.question,
              "selectedAnswer": ans["selectedAnswer"] ?? "",
              "correctAnswer": q.correctAnswer,
              "isCorrect": ans["selectedAnswer"] == q.correctAnswer,
              "scannedImageUrl": null,
              "aiFeedback": "",
            };
          }
          return null;
        }).where((item) => item != null).toList();
      }
    }

    final correct = review.where((e) => e['isCorrect'] == true).length;
    final wrong = review.where((e) => e['isCorrect'] == false && (e['selectedAnswer'] ?? '') != "").length;
    final skipped = review.where((e) => (e['selectedAnswer'] ?? '') == "" || e['selectedAnswer'] == null).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF4F46E5),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(context, MainScreen.routeName, (route) => false),
        ),
        title: const Text("Evaluation Report", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 30),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF4F46E5),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: Column(
              children: [
                const Text("Grand Total Score", style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 8),
                Text("$score / $total", style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
                if (isAIEvaluated)
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(color: Colors.greenAccent.withAlpha(50), borderRadius: BorderRadius.circular(20)),
                    child: const Text("Verified by AI Teacher Scan", style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                  )
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (!isAIEvaluated)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _statCard("Correct", correct, Colors.green),
                  const SizedBox(width: 12),
                  _statCard("Wrong", wrong, Colors.red),
                  const SizedBox(width: 12),
                  _statCard("Skipped", skipped, Colors.orange),
                ],
              ),
            ),

          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(isAIEvaluated ? "Question-Wise Evaluation" : "Detailed Breakdown", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B))),
            ),
          ),
          const SizedBox(height: 10),

          Expanded(
            child: review.isEmpty
                ? const Center(child: Text("No detailed review available.", style: TextStyle(color: Colors.grey)))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: review.length,
              itemBuilder: (context, index) {
                final item = review[index];
                final isSkipped = (item['selectedAnswer'] ?? '') == "";
                final isCorrect = item['isCorrect'] ?? false;
                final obtainedMarks = item['obtained_marks'];
                final maxMarks = item['max_marks'];
                final String? imageUrl = item['scannedImageUrl'];
                final String aiFeedback = item['aiFeedback'] ?? ""; // 🔥 GET FEEDBACK

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isAIEvaluated ? Colors.grey.shade300 : (isSkipped ? Colors.orange.shade200 : (isCorrect ? Colors.green.shade200 : Colors.red.shade200)),
                    ),
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 5)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: Text("Q${index + 1}. ${item['question']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                          if (isAIEvaluated && maxMarks != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                              child: Text("$obtainedMarks / $maxMarks", style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                        ],
                      ),
                      const Divider(height: 20),

                      if (!isAIEvaluated) ...[
                        Text(
                          isSkipped ? "Skipped" : "Your Answer: ${item['selectedAnswer']}",
                          style: TextStyle(color: isSkipped ? Colors.orange : (isCorrect ? Colors.green : Colors.red), fontWeight: FontWeight.bold,),
                        ),
                        if (!isCorrect && !isSkipped)
                          Padding(padding: const EdgeInsets.only(top: 4), child: Text("Correct Answer: ${item['correctAnswer']}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                      ] else ...[
                        Text("Checked by AI Examiner", style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
                      ],

                      // 🔥 SHOW AI FEEDBACK FOR STUDENT
                      if (aiFeedback.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber.shade200)),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline, color: Colors.amber, size: 18),
                              const SizedBox(width: 8),
                              Expanded(child: Text(aiFeedback, style: TextStyle(color: Colors.amber.shade900, fontSize: 13, fontStyle: FontStyle.italic, height: 1.4))),
                            ],
                          ),
                        ),

                      if (imageUrl != null && imageUrl.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => _showFullScreenImage(context, imageUrl),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              imageUrl,
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (c,e,s) => Container(height: 120, color: Colors.grey.shade100, child: const Center(child: Icon(Icons.broken_image, color: Colors.grey))),
                            ),
                          ),
                        )
                      ]
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withAlpha(75))),
        child: Column(
          children: [
            Text("$value", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}