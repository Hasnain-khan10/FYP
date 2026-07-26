import 'package:flutter/material.dart';
import 'package:frontened/Provider/quiz_provider.dart';
import 'package:provider/provider.dart';

class TeacherQuizEvaluationScreen extends StatefulWidget {
  final String attemptId;
  final String quizId;

  const TeacherQuizEvaluationScreen({
    super.key,
    required this.attemptId,
    required this.quizId,
  });

  @override
  State<TeacherQuizEvaluationScreen> createState() => _TeacherQuizEvaluationScreenState();
}

class _TeacherQuizEvaluationScreenState extends State<TeacherQuizEvaluationScreen> {
  bool _isSaving = false;
  final List<TextEditingController> _controllers = [];
  Map<String, dynamic>? _quizResultsData;

  @override
  void initState() {
    super.initState();
    _fetchEvaluationDetails();
  }

  Future<void> _fetchEvaluationDetails() async {
    final provider = context.read<QuizProvider>();
    final data = await provider.fetchQuizResults(widget.quizId);
    if (mounted && data != null) {
      setState(() {
        _quizResultsData = data;
        final attempts = data['results'] as List?;
        if (attempts != null && attempts.isNotEmpty) {
          final targetAttempt = attempts.firstWhere(
            (element) => element['attemptId'].toString() == widget.attemptId.toString(),
            orElse: () => null,
          );
          if (targetAttempt != null && targetAttempt['detailedAnswers'] != null) {
            _controllers.clear();
            for (var ans in targetAttempt['detailedAnswers']) {
              _controllers.add(TextEditingController(text: (ans['obtained_marks'] ?? 0).toString()));
            }
          }
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveIndividualMarks(int index, String localAttemptId, int newScore) async {
    setState(() => _isSaving = true);

    bool success = await Provider.of<QuizProvider>(context, listen: false).updateManualMarks(
        attemptId: localAttemptId,
        manualScore: newScore,
        questionIndex: index
    );

    setState(() => _isSaving = false);

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Marks Updated Successfully!"), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update marks."), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_quizResultsData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Quiz Evaluation Panel", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF4F46E5),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _controllers.isEmpty
          ? const Center(child: Text("No answer scripts found to evaluate."))
          : ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _controllers.length,
        itemBuilder: (ctx, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Question Response #${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _controllers[index],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Assign Score",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
                      onPressed: _isSaving
                          ? null
                          : () {
                        int score = int.tryParse(_controllers[index].text.trim()) ?? 0;
                        _saveIndividualMarks(index, widget.attemptId, score);
                      },
                      child: _isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Save Score", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}