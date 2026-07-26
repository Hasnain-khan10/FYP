import 'dart:io';
import 'package:flutter/material.dart';
import 'package:frontened/Provider/week_plan_provider.dart';
import 'package:frontened/Provider/course_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

class TeacherAIWeekPlanScreen extends StatefulWidget {
  final String courseId;

  const TeacherAIWeekPlanScreen({super.key, required this.courseId});

  @override
  State<TeacherAIWeekPlanScreen> createState() => _TeacherAIWeekPlanScreenState();
}

class _TeacherAIWeekPlanScreenState extends State<TeacherAIWeekPlanScreen> {
  File? uploadedBook;
  final topicController = TextEditingController();
  final promptController = TextEditingController();

  String selectedFormat = "PDF"; // Options: PDF, DOCX, PPT

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<CourseProvider>().fetchCourses());
  }

  @override
  void dispose() {
    topicController.dispose();
    promptController.dispose();
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

  Future<void> _pickBook() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'txt', 'ppt', 'pptx']
    );
    if (result != null && result.files.single.path != null) {
      setState(() => uploadedBook = File(result.files.single.path!));
    }
  }

  Future<void> _handleGeneration(String courseTitle) async {
    final provider = context.read<WeekPlanProvider>();
    bool success = false;

    if (uploadedBook != null) {
      success = await provider.generateAIPlanFromBook(
          widget.courseId,
          courseTitle: courseTitle,
          bookFile: uploadedBook!,
          format: selectedFormat // 🔥 Passes Format to Provider
      );
    } else {
      if (topicController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a Topic Name or Upload a Book"), backgroundColor: Colors.red));
        return;
      }
      success = await provider.generateAIPlan(
          widget.courseId,
          courseTitle: courseTitle,
          prompt: "Topic: ${topicController.text.trim()}, Additional Prompt: ${promptController.text.trim()}",
          format: selectedFormat // 🔥 Passes Format to Provider
      );
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Weekly Plan Generated Successfully! 🎉"), backgroundColor: Colors.green));
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.error ?? "Generation Failed"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WeekPlanProvider>();
    final String courseTitle = _getCourseTitle(context);

    bool isBookMode = uploadedBook != null;
    String buttonText = isBookMode ? "Generate from Book" : "Generate from Topic";
    Color buttonColor = isBookMode ? Colors.green.shade600 : const Color(0xFF4F46E5);
    IconData buttonIcon = isBookMode ? Icons.auto_stories : Icons.auto_awesome;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("18-Week Plan Studio", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF4F46E5),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: const Color(0xFF4F46E5).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF4F46E5).withValues(alpha: 0.3))),
              child: Row(
                children: [
                  const Icon(Icons.school, color: Color(0xFF4F46E5)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Target Subject Domain", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                        Text(courseTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
                      ],
                    ),
                  ),
                  const Icon(Icons.lock_outline, color: Colors.grey, size: 20),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Syllabus Configuration", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: topicController,
                    decoration: InputDecoration(labelText: "Main Topic Name", hintText: "e.g., Software Engineering Basics", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), filled: true, fillColor: Colors.grey.shade50),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: promptController,
                    maxLines: 2,
                    decoration: InputDecoration(labelText: "Custom Instructions (Optional)", hintText: "e.g., Focus on modern cloud architecture...", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), filled: true, fillColor: Colors.grey.shade50),
                  ),
                  const SizedBox(height: 20),

                  InkWell(
                    onTap: _pickBook,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      decoration: BoxDecoration(color: isBookMode ? Colors.green.shade50 : Colors.blue.shade50, border: Border.all(color: isBookMode ? Colors.green : Colors.blue.shade200, width: 2), borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        children: [
                          Icon(isBookMode ? Icons.check_circle : Icons.cloud_upload, color: isBookMode ? Colors.green : Colors.blue, size: 40),
                          const SizedBox(height: 8),
                          Text(isBookMode ? "Book Attached Successfully" : "Upload Reference Book (PDF/DOCX/PPT)", style: TextStyle(fontWeight: FontWeight.bold, color: isBookMode ? Colors.green.shade700 : Colors.blue.shade700)),
                          if (isBookMode) Text(uploadedBook!.path.split('/').last, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text("Output Format Extraction:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 10),
            Row(
              children: ["PDF", "DOCX", "PPT"].map((format) {
                bool isSelected = selectedFormat == format;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => selectedFormat = format),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(color: isSelected ? const Color(0xFF4F46E5) : Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? const Color(0xFF4F46E5) : Colors.grey.shade300)),
                      child: Center(
                        child: Text(format, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87)),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: buttonColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 2),
                icon: provider.isGeneratingAI || provider.isGeneratingFromBook ? const SizedBox.shrink() : Icon(buttonIcon, color: Colors.white),
                label: provider.isGeneratingAI || provider.isGeneratingFromBook
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(buttonText, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: provider.isGeneratingAI || provider.isGeneratingFromBook ? null : () => _handleGeneration(courseTitle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}