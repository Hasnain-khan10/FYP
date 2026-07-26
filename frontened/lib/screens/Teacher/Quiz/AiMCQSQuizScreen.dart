import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:frontened/Provider/quiz_provider.dart';
import 'package:frontened/Provider/course_provider.dart';

class TeacherAIMCQSQuizScreen extends StatefulWidget {
  final String courseId;
  final String quizTitle;

  const TeacherAIMCQSQuizScreen({super.key, required this.courseId, required this.quizTitle});

  @override
  State<TeacherAIMCQSQuizScreen> createState() => _TeacherAIMCQSQuizScreenState();
}

class _TeacherAIMCQSQuizScreenState extends State<TeacherAIMCQSQuizScreen> {
  File? pdfFile;

  final promptController = TextEditingController();
  final countController = TextEditingController(text: "10");
  final marksController = TextEditingController(text: "1");
  String difficulty = "Medium";

  // 🔥 AUTOMATED TIME-BASED RULES
  DateTime? openDateTime;
  DateTime? deadlineDateTime;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<CourseProvider>().fetchCourses());
  }

  @override
  void dispose() { promptController.dispose(); countController.dispose(); marksController.dispose(); super.dispose(); }

  String _getCourseTitle(BuildContext context) {
    final courses = context.read<CourseProvider>().courses;
    try { return courses.firstWhere((c) => c.id == widget.courseId).title; } catch (e) { return "Unknown Subject"; }
  }

  int _calculateTotal() {
    int count = int.tryParse(countController.text) ?? 10;
    int marks = int.tryParse(marksController.text) ?? 1;
    return count * marks;
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'txt', 'docx']);
    if (result != null && result.files.single.path != null) setState(() => pdfFile = File(result.files.single.path!));
  }

  // 🔥 FUNCTION TO PICK PRECISE DATE AND TIME FOR AUTOMATION
  Future<void> _pickDateTime(bool isOpenTime) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (date == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    final selected = DateTime(date.year, date.month, date.day, time.hour, time.minute);

    setState(() {
      if (isOpenTime) {
        openDateTime = selected;
      } else {
        deadlineDateTime = selected;
      }
    });
  }

  Future<void> _generateQuiz() async {
    if (pdfFile == null && promptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: Provide Topic OR Reference Doc!"), backgroundColor: Colors.red)); return;
    }

    // 🔥 PRE-VALIDATION CHECK: Ensures teacher selected the time correctly before hitting API
    if (openDateTime == null || deadlineDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please set both Open Time and Deadline!"), backgroundColor: Colors.red));
      return;
    }

    if (deadlineDateTime!.isBefore(openDateTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: Deadline cannot be before the Open Time!"), backgroundColor: Colors.red));
      return;
    }

    final quizProvider = context.read<QuizProvider>();
    String finalPrompt = promptController.text.trim();
    if (finalPrompt.isEmpty) finalPrompt = "Generate MCQs for: ${_getCourseTitle(context)}";

    final result = await quizProvider.createAIMCQQuiz(
      courseId: widget.courseId,
      prompt: finalPrompt,
      difficulty: difficulty.toLowerCase(),
      questionCount: int.tryParse(countController.text) ?? 10,
      marksPerQuestion: int.tryParse(marksController.text) ?? 1,
      file: pdfFile,
      // 🔥 SENDING CORRECT TIME-BASED STRINGS TO BACKEND
      openDateTime: openDateTime!.toIso8601String(),
      deadlineDateTime: deadlineDateTime!.toIso8601String(),
    );

    if (result != null && mounted) {
      await quizProvider.fetchQuizzes(widget.courseId);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("AI MCQ Quiz Secured & Created! 🎉"), backgroundColor: Colors.green));
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(quizProvider.error ?? "Failed to create AI Quiz"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizProvider = context.watch<QuizProvider>();
    final String courseTitle = _getCourseTitle(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text("AI MCQ - ${widget.quizTitle}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)), backgroundColor: const Color(0xFF4F46E5), elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF4F46E5).withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Total Exam Marks:", style: TextStyle(fontWeight: FontWeight.bold)), Text("${_calculateTotal()}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF4F46E5)))])),
            const SizedBox(height: 20),

            // 🔥 REVERTED TO AUTOMATED TIME SELECTORS (Protected by Expanded to prevent overflow)
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickDateTime(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
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
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
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
            const SizedBox(height: 20),

            TextFormField(initialValue: courseTitle, readOnly: true, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)), decoration: InputDecoration(labelText: "Locked Subject Domain", prefixIcon: const Icon(Icons.school, color: Color(0xFF4F46E5)), filled: true, fillColor: const Color(0xFF4F46E5).withValues(alpha: 0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xFF4F46E5).withValues(alpha: 0.3))))),
            const SizedBox(height: 20),
            TextField(controller: promptController, decoration: InputDecoration(labelText: "Topic Focus / Prompt Instructions", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 16),
            Row(children: [ Expanded(child: TextField(controller: countController, keyboardType: TextInputType.number, onChanged: (_) => setState((){}), decoration: InputDecoration(labelText: "Questions", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))))), const SizedBox(width: 12), Expanded(child: TextField(controller: marksController, keyboardType: TextInputType.number, onChanged: (_) => setState((){}), decoration: InputDecoration(labelText: "Marks Per MCQ", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))))) ]),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(initialValue: difficulty, decoration: InputDecoration(labelText: "Difficulty Level", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))), items: ["Easy", "Medium", "Hard"].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(), onChanged: (val) => setState(() => difficulty = val ?? "Medium")),
            const SizedBox(height: 24),
            GestureDetector(onTap: _pickFile, child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16), decoration: BoxDecoration(color: pdfFile != null ? Colors.green.shade50 : Colors.grey.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: pdfFile != null ? Colors.green : Colors.grey.shade300)), child: Column(children: [Icon(pdfFile != null ? Icons.check_circle : Icons.upload_file, color: pdfFile != null ? Colors.green : Colors.grey), const SizedBox(height: 8), Text(pdfFile != null ? pdfFile!.path.split('/').last : "Upload Reference Document", style: TextStyle(color: pdfFile != null ? Colors.green : Colors.black87, fontWeight: FontWeight.bold))]))),
            const SizedBox(height: 30),
            SizedBox(width: double.infinity, height: 55, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: quizProvider.isLoading || quizProvider.isGeneratingAI ? null : _generateQuiz, child: quizProvider.isGeneratingAI ? const CircularProgressIndicator(color: Colors.white) : const Text("Generate Secure AI Exam", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))))
          ],
        ),
      ),
    );
  }
}