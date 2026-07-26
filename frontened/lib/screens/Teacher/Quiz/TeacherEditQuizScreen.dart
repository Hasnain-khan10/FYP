import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontened/Provider/quiz_provider.dart';
import 'package:frontened/models/Quiz/quiz_model.dart';
import 'package:intl/intl.dart';

class TeacherEditQuizScreen extends StatefulWidget {
  final Quiz quiz;
  final String courseId;

  const TeacherEditQuizScreen({super.key, required this.quiz, required this.courseId});

  @override
  State<TeacherEditQuizScreen> createState() => _TeacherEditQuizScreenState();
}

class _TeacherEditQuizScreenState extends State<TeacherEditQuizScreen> {
  late TextEditingController _titleController;

  // Maps to hold editable data
  List<Map<String, dynamic>> editableMcqs = [];
  List<Map<String, dynamic>> editableShorts = [];
  List<Map<String, dynamic>> editableLongs = [];

  // 🔥 EDITABLE AUTOMATED TIMINGS
  DateTime? openDateTime;
  DateTime? deadlineDateTime;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.quiz.title);

    // Load existing timings from database model
    openDateTime = widget.quiz.openDateTime;
    deadlineDateTime = widget.quiz.deadlineDateTime;

    // Load existing data into editable maps
    if (widget.quiz.type == 'mcq') {
      editableMcqs = widget.quiz.questions.map((q) => {
        "question": q.question,
        "options": Map<String, String>.from(q.options),
        "correctAnswer": q.correctAnswer,
        "marks": q.marks,
        "explanation": q.explanation
      }).toList();
    } else {
      editableShorts = widget.quiz.shortQuestions.map((q) => {
        "question": q.question, "idealAnswer": q.idealAnswer, "rubric": q.rubric, "marks": q.marks
      }).toList();

      editableLongs = widget.quiz.longQuestions.map((q) => {
        "question": q.question, "idealAnswer": q.idealAnswer, "rubric": q.rubric, "marks": q.marks
      }).toList();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  // 🔥 TIMING DATE-TIME PICKER CONTROLLER FOR EDIT LAYER
  Future<void> _pickDateTime(bool isOpenTime) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isOpenTime ? (openDateTime ?? DateTime.now()) : (deadlineDateTime ?? DateTime.now()),
      firstDate: DateTime.now().subtract(const Duration(days: 365)), // Allows modifying past schedules
      lastDate: DateTime(2030),
    );
    if (date == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: isOpenTime
          ? TimeOfDay.fromDateTime(openDateTime ?? DateTime.now())
          : TimeOfDay.fromDateTime(deadlineDateTime ?? DateTime.now()),
    );
    if (time == null) return;

    setState(() {
      if (isOpenTime) {
        openDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      } else {
        deadlineDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      }
    });
  }

  Future<void> _saveQuiz() async {
    // Validation constraints check to avoid corrupted updates
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Quiz title cannot be empty!"), backgroundColor: Colors.red));
      return;
    }

    if (openDateTime == null || deadlineDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please set both Open Time and Deadline!"), backgroundColor: Colors.red));
      return;
    }

    if (deadlineDateTime!.isBefore(openDateTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Deadline cannot be before the Open Time!"), backgroundColor: Colors.red));
      return;
    }

    final quizProvider = context.read<QuizProvider>();

    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

    final success = await quizProvider.updateQuiz(
      quizId: widget.quiz.id,
      courseId: widget.courseId,
      title: _titleController.text.trim(),
      questions: widget.quiz.type == 'mcq' ? editableMcqs : null,
      shortQuestions: widget.quiz.type != 'mcq' ? editableShorts : null,
      longQuestions: widget.quiz.type != 'mcq' ? editableLongs : null,
      openDateTime: openDateTime!.toIso8601String(),
      deadlineDateTime: deadlineDateTime!.toIso8601String(),
    );

    if (mounted) Navigator.pop(context); // Close loading

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Quiz Updated Successfully!"), backgroundColor: Colors.green));
      if (mounted) Navigator.pop(context); // Go back
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Update Failed: ${quizProvider.error}"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Edit Quiz", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF4F46E5),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveQuiz,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Quiz Title", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                filled: true, fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),

            // 🔥 EDIT TIME CONFIGURATION SELECTION TILES (Protected from UI line overflows)
            const Text("Adjust Scheduled Timings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickDateTime(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue.shade200)),
                      child: Column(
                          children: [
                            const Icon(Icons.timer, color: Colors.blue, size: 18),
                            const SizedBox(height: 4),
                            Text(
                              openDateTime == null ? "Set Open Time" : DateFormat('dd MMM, hh:mm a').format(openDateTime!),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            )
                          ]
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickDateTime(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
                      child: Column(
                          children: [
                            const Icon(Icons.block, color: Colors.red, size: 18),
                            const SizedBox(height: 4),
                            Text(
                              deadlineDateTime == null ? "Set Deadline" : DateFormat('dd MMM, hh:mm a').format(deadlineDateTime!),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            )
                          ]
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (widget.quiz.type == 'mcq') ...[
              const Text("Edit MCQs", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF4F46E5))),
              ...editableMcqs.asMap().entries.map((e) => _buildMcqEditor(e.value, e.key)),
            ] else ...[
              if (editableShorts.isNotEmpty) ...[
                const Text("Edit Short Questions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.teal)),
                ...editableShorts.asMap().entries.map((e) => _buildSubjectiveEditor(e.value, e.key, "Short")),
                const SizedBox(height: 24),
              ],
              if (editableLongs.isNotEmpty) ...[
                const Text("Edit Long Questions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.purple)),
                ...editableLongs.asMap().entries.map((e) => _buildSubjectiveEditor(e.value, e.key, "Long")),
              ]
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildMcqEditor(Map<String, dynamic> q, int index) {
    return Card(
      margin: const EdgeInsets.only(top: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Q${index + 1}.", style: const TextStyle(fontWeight: FontWeight.bold)),
            TextFormField(
              initialValue: q["question"],
              onChanged: (val) => q["question"] = val,
              decoration: const InputDecoration(hintText: "Question statement"),
            ),
            const SizedBox(height: 10),
            ...['A', 'B', 'C', 'D'].map((opt) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: TextFormField(
                initialValue: q["options"][opt],
                onChanged: (val) => q["options"][opt] = val,
                decoration: InputDecoration(prefixText: "$opt) ", isDense: true),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectiveEditor(Map<String, dynamic> q, int index, String type) {
    return Card(
      margin: const EdgeInsets.only(top: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("$type Q${index + 1}.", style: const TextStyle(fontWeight: FontWeight.bold)),
            TextFormField(
              initialValue: q["question"],
              onChanged: (val) => q["question"] = val,
              decoration: const InputDecoration(labelText: "Question"),
              maxLines: 2,
            ),
            const SizedBox(height: 10),
            TextFormField(
              initialValue: q["idealAnswer"],
              onChanged: (val) => q["idealAnswer"] = val,
              decoration: const InputDecoration(labelText: "Ideal Answer / Key"),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}