import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:frontened/Provider/quiz_provider.dart';
import 'package:frontened/Provider/course_provider.dart';
import 'package:provider/provider.dart';

class TeacherAIQuestionQuizScreen extends StatefulWidget {
  final String quizTitle;
  final String courseId;

  const TeacherAIQuestionQuizScreen({super.key, required this.quizTitle, required this.courseId});

  @override
  State<TeacherAIQuestionQuizScreen> createState() => _TeacherAIQuestionQuizScreenState();
}

class _TeacherAIQuestionQuizScreenState extends State<TeacherAIQuestionQuizScreen> {
  final TextEditingController _topicController = TextEditingController();

  // 🔥 DYNAMIC COUNTERS
  int _shortCount = 5;
  int _longCount = 2;
  int _shortMarks = 2;
  int _longMarks = 10;
  String difficulty = "medium";

  File? _selectedFile;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<CourseProvider>().fetchCourses());
  }

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  String _getCourseTitle(BuildContext context) {
    final courses = context.read<CourseProvider>().courses;
    try {
      return courses.firstWhere((c) => c.id == widget.courseId).title;
    } catch (e) {
      return "Unknown Subject";
    }
  }

  int _calculateTotal() => (_shortCount * _shortMarks) + (_longCount * _longMarks);

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'docx'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _selectedFile = File(result.files.single.path!));
    }
  }

  Future<void> _generateQuiz() async {
    if (_selectedFile == null && _topicController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: Please provide a Topic OR attach a Reference Document!"), backgroundColor: Colors.red));
      return;
    }

    final quizProvider = context.read<QuizProvider>();
    final String currentCourseTitle = _getCourseTitle(context);

    // Auto-detect quiz type
    String type = "both";
    if (_shortCount > 0 && _longCount == 0) type = "short";
    if (_longCount > 0 && _shortCount == 0) type = "long";

    // Auto-fill prompt if empty
    String finalPrompt = _topicController.text.trim();
    if (finalPrompt.isEmpty) {
      finalPrompt = "Generate questions for: $currentCourseTitle";
    }

    // 🔥 FIX: courseTitle removed, _selectedFile passed safely
    final result = await quizProvider.createAIQuestionQuiz(
      courseId: widget.courseId,
      prompt: finalPrompt,
      difficulty: difficulty,
      type: type,
      shortCount: _shortCount,
      shortEachMark: _shortMarks,
      longCount: _longCount,
      longEachMark: _longMarks,
      file: _selectedFile,
    );

    if (result != null && mounted) {
      await quizProvider.fetchQuizzes(widget.courseId); // Auto refresh
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("AI Subjective Exam Created Successfully! 🎉"), backgroundColor: Colors.green));
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(quizProvider.error ?? "Failed to create AI Exam"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizProvider = context.watch<QuizProvider>();
    final String courseTitle = _getCourseTitle(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4F46E5),
        title: Text("AI Theory - ${widget.quizTitle}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF4F46E5).withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total Exam Marks:", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("${_calculateTotal()}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF4F46E5))),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              initialValue: courseTitle,
              readOnly: true,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
              decoration: InputDecoration(
                  labelText: "Locked Subject Domain",
                  prefixIcon: const Icon(Icons.school, color: Color(0xFF4F46E5)),
                  filled: true,
                  fillColor: const Color(0xFF4F46E5).withValues(alpha: 0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xFF4F46E5).withValues(alpha: 0.3)))
              ),
            ),
            const SizedBox(height: 20),
            const Text("Topic / Prompt Instructions", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _topicController,
              decoration: InputDecoration(hintText: "e.g., Operating Systems Concepts", filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickFile,
              child: Container(
                width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(color: _selectedFile != null ? Colors.green.shade50 : Colors.grey.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: _selectedFile != null ? Colors.green : Colors.grey.shade300)),
                child: Column(
                  children: [
                    Icon(_selectedFile != null ? Icons.check_circle : Icons.upload_file, color: _selectedFile != null ? Colors.green : Colors.grey),
                    const SizedBox(height: 8),
                    Text(_selectedFile != null ? _selectedFile!.path.split('/').last : "Upload Reference Book / Document", style: TextStyle(color: _selectedFile != null ? Colors.green : Colors.black87, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),
            _buildCounterSection("Short Questions", _shortCount, (val) => setState(() => _shortCount = val), "Marks per Short", _shortMarks, (val) => setState(() => _shortMarks = val)),
            const Divider(height: 40),
            _buildCounterSection("Long Questions", _longCount, (val) => setState(() => _longCount = val), "Marks per Long", _longMarks, (val) => setState(() => _longMarks = val)),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: quizProvider.isLoading || quizProvider.isGeneratingAI ? null : _generateQuiz,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: quizProvider.isGeneratingAI
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Generate AI Theory Paper", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCounterSection(String title, int count, Function(int) onCountChange, String marksTitle, int marks, Function(int) onMarksChange) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B))),
        const SizedBox(height: 10),
        Row(
          children: [
            IconButton(onPressed: () => onCountChange(count > 0 ? count - 1 : 0), icon: const Icon(Icons.remove_circle_outline)),
            Text("$count", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(onPressed: () => onCountChange(count + 1), icon: const Icon(Icons.add_circle_outline)),
            const Spacer(),
            SizedBox(width: 120, child: TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: marksTitle, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              onChanged: (val) => setState(() => onMarksChange(int.tryParse(val) ?? 1)),
            ))
          ],
        ),
      ],
    );
  }
}