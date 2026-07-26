import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontened/Provider/course_provider.dart';
import 'package:frontened/Provider/quiz_provider.dart';

import 'package:frontened/screens/Teacher/Quiz/TeacherQuizPreviewScreen.dart';
import 'package:frontened/screens/Teacher/Quiz/TeacherQuizEvaluationScreen.dart';
import 'package:frontened/screens/Teacher/Quiz/TeacherEditQuizScreen.dart';

class TeacherQuizManagementCenter extends StatefulWidget {
  final String quizId;
  final String courseId;
  final String quizTitle;
  final String quizType;
  final int totalMarks;

  const TeacherQuizManagementCenter({
    super.key,
    required this.quizId,
    required this.courseId,
    required this.quizTitle,
    required this.quizType,
    required this.totalMarks,
  });

  @override
  State<TeacherQuizManagementCenter> createState() => _TeacherQuizManagementCenterState();
}

class _TeacherQuizManagementCenterState extends State<TeacherQuizManagementCenter> {
  String _activeView = "results";

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      // 🔥 FIX: Kept fetchQuizzes active so full quiz data never vanishes
      context.read<QuizProvider>().fetchQuizzes(widget.courseId);
      context.read<QuizProvider>().fetchQuizResults(widget.quizId, quizId: widget.quizId);
      context.read<CourseProvider>().fetchCourseStudents(widget.courseId);
    });
  }

  void _refreshData() {
    context.read<QuizProvider>().fetchQuizResults(widget.quizId, quizId: widget.quizId);
  }

  void _openStudentEvaluation(String studentId, String studentName, List results, {required bool isResultView}) {
    final attempt = results.firstWhere((r) => r["studentId"].toString() == studentId.toString(), orElse: () => null);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TeacherQuizEvaluationScreen(
          attemptId: attempt != null ? attempt["attemptId"].toString() : "",
          quizId: widget.quizId,
        ),
      ),
    ).then((_) => _refreshData());
  }

  @override
  Widget build(BuildContext context) {
    final quizProvider = context.watch<QuizProvider>();
    final courseProvider = context.watch<CourseProvider>();

    final results = (quizProvider.quizResults?["results"] as List?) ?? [];
    final enrolledStudents = courseProvider.courseStudents;
    final bool isMcqQuiz = widget.quizType.toLowerCase() == "mcq";

    final String? currentFetchedQuizId = quizProvider.quizResults?["quiz"]?["id"]?.toString();
    final bool isDataMatching = currentFetchedQuizId == widget.quizId;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF4F46E5),
        title: Text(widget.quizTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: TextButton.icon(
              onPressed: () {
                try {
                  final fullQuiz = quizProvider.quizzes.firstWhere((q) => q.id.toString() == widget.quizId.toString());
                  Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherQuizPreviewScreen(quiz: fullQuiz)));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Quiz data is loading..."), backgroundColor: Colors.orange));
                }
              },
              icon: const Icon(Icons.vpn_key, color: Colors.yellowAccent, size: 18),
              label: const Text("Key", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(backgroundColor: Colors.white12, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) async {
              if (value == 'edit') {
                try {
                  final fullQuiz = context.read<QuizProvider>().quizzes.firstWhere((q) => q.id.toString() == widget.quizId.toString());
                  Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherEditQuizScreen(quiz: fullQuiz, courseId: widget.courseId)));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Quiz data is loading, please wait..."), backgroundColor: Colors.orange));
                }
              }
              else if (value == 'delete') {
                final bool confirm = await showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Row(children: [Icon(Icons.warning, color: Colors.red), SizedBox(width: 8), Text("Delete Quiz?")]),
                    content: const Text("Are you sure you want to permanently delete this quiz? All student attempts will also be removed."),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                      ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete", style: TextStyle(color: Colors.white))),
                    ],
                  ),
                ) ?? false;

                if (confirm && mounted) {
                  final success = await context.read<QuizProvider>().deleteQuiz(quizId: widget.quizId, courseId: widget.courseId);
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Quiz Deleted Successfully!"), backgroundColor: Colors.green));
                    Navigator.pop(context);
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ Failed to delete quiz."), backgroundColor: Colors.red));
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, color: Colors.blue, size: 20), SizedBox(width: 10), Text("Edit Quiz")])),
              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 20), SizedBox(width: 10), Text("Delete Quiz", style: TextStyle(color: Colors.red))])),
            ],
          )
        ],
      ),
      body: (quizProvider.isLoadingQuizResults || !isDataMatching)
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
          : Column(
        children: [
          if (!isMcqQuiz)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: Container(
                height: 50,
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    _toggleButton("Results View", "results", Icons.analytics_outlined),
                    _toggleButton("Scan / Evaluate", "scanning", Icons.document_scanner_outlined),
                  ],
                ),
              ),
            ),

          Expanded(
            child: (isMcqQuiz || _activeView == "results")
                ? _buildResultsList(results)
                : _buildScanningList(enrolledStudents, results),
          ),
        ],
      ),
    );
  }

  Widget _toggleButton(String label, String value, IconData icon) {
    final bool isSelected = _activeView == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeView = value),
        child: Container(
          decoration: BoxDecoration(color: isSelected ? const Color(0xFF4F46E5) : Colors.transparent, borderRadius: BorderRadius.circular(10), boxShadow: isSelected ? const [BoxShadow(color: Colors.black12, blurRadius: 4)] : null,),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.grey),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsList(List results) {
    if (results.isEmpty) return const Center(child: Text("No student attempts recorded yet."));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final r = results[index] ?? {};
        final name = r["studentName"] ?? r["name"] ?? "Unknown Student";
        final studentId = (r["studentId"] ?? "").toString();
        final marks = (r["score"] ?? 0).toInt();
        final evaluatedByAI = r["evaluatedByAI"] ?? false;

        return GestureDetector(
          onTap: () => _openStudentEvaluation(studentId, name, results, isResultView: true),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                const CircleAvatar(backgroundColor: Color(0xFF4F46E5), child: Icon(Icons.person, color: Colors.white, size: 20)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      if (evaluatedByAI)
                        const Text("AI Scanned/Evaluated", style: TextStyle(color: Colors.purple, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text("$marks / ${widget.totalMarks}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScanningList(List students, List results) {
    if (students.isEmpty) return const Center(child: Text("No students enrolled in this course."));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final s = students[index];
        final studentName = s["name"] ?? "Enrolled Student";
        final studentId = (s["_id"] ?? s["id"] ?? "").toString();

        final attempt = results.firstWhere((r) => r["studentId"].toString() == studentId, orElse: () => null);
        final bool isEvaluated = attempt != null && attempt["evaluatedByAI"] == true;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              const CircleAvatar(backgroundColor: Color(0xFF7C3AED), child: Icon(Icons.person_search, color: Colors.white, size: 20)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(isEvaluated ? "Partially/Fully Evaluated" : "Pending Evaluation", style: TextStyle(fontSize: 12, color: isEvaluated ? Colors.green : Colors.grey)),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _openStudentEvaluation(studentId, studentName, results, isResultView: false),
                icon: const Icon(Icons.open_in_new, size: 16, color: Colors.white),
                label: const Text("Open", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isEvaluated ? Colors.teal : const Color(0xFF4F46E5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  elevation: 0,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}