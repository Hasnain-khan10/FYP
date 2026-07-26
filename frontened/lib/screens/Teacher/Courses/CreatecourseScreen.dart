import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontened/Provider/course_provider.dart';
import 'package:frontened/models/Quiz/quiz_model.dart';
import 'package:frontened/models/course_model.dart';
import 'package:frontened/screens/Teacher/Courses/TeacherUnifiedCourseScreen.dart'; // Level 2 Link
import 'package:provider/provider.dart';

class TeacherCreateCourseScreen extends StatefulWidget {
  static const String createCourse = '/create-course';
  final List<Quiz> quiz;

  const TeacherCreateCourseScreen({super.key, required this.quiz});

  @override
  State<TeacherCreateCourseScreen> createState() => _TeacherCreateCourseScreenState();
}

class _TeacherCreateCourseScreenState extends State<TeacherCreateCourseScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController creditController = TextEditingController();

  String? selectedSemester;
  final List<String> semesters = List.generate(8, (i) => "Semester ${i + 1}");

  @override
  void dispose() {
    nameController.dispose();
    codeController.dispose();
    creditController.dispose();
    super.dispose();
  }

  void _showSnackBar(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _createCourse() async {
    final provider = context.read<CourseProvider>();

    if (nameController.text.isEmpty || codeController.text.isEmpty || creditController.text.isEmpty || selectedSemester == null) {
      _showSnackBar("Please fill all the required fields.");
      return;
    }

    final course = CourseModel(
      id: "",
      title: nameController.text.trim(),
      courseCode: codeController.text.trim(),
      creditHours: int.tryParse(creditController.text.trim()) ?? 3,
      syllabus: "",
      books: [],
      progress: 0,
      semester: selectedSemester,
    );

    final createdCourse = await provider.createCourse(course);

    if (!mounted) return;

    if (createdCourse != null) {
      final String joinLink = provider.joinLink ?? "No link generated";
      _showSuccessDialog(createdCourse.id, createdCourse.title, joinLink);
    } else {
      _showSnackBar(provider.error ?? "Failed to create workspace.");
    }
  }

  // 🔥 PREMIUM SUCCESS DIALOG
  void _showSuccessDialog(String courseId, String courseTitle, String joinLink) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Colors.green,
                child: Icon(Icons.check, color: Colors.white, size: 35),
              ),
              const SizedBox(height: 16),
              const Text("Workspace Created!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("Share this link with your students so they can join.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),

              // LINK CONTAINER
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Expanded(child: Text(joinLink, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)))),
                    IconButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: joinLink));
                        _showSnackBar("Link copied to clipboard!", isError: false);
                      },
                      icon: const Icon(Icons.copy, color: Color(0xFF4F46E5)),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to Level 2 (Unified Course Screen)
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => TeacherUnifiedCourseScreen(courseId: courseId, courseTitle: courseTitle)));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Enter Workspace", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CourseProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF4F46E5),
        title: const Text("Create Workspace", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Workspace Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B))),
              const SizedBox(height: 6),
              const Text("Fill in the details to setup your new virtual classroom.", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),

              _inputField("Course Title", nameController, Icons.menu_book),
              const SizedBox(height: 16),
              _inputField("Course Code (e.g. CS-101)", codeController, Icons.code),
              const SizedBox(height: 16),

              // SEMESTER DROPDOWN
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedSemester,
                    isExpanded: true,
                    hint: const Text("Select Semester"),
                    items: semesters.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (val) => setState(() => selectedSemester = val),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              _inputField("Credit Hours", creditController, Icons.timer, isNumber: true),
              const SizedBox(height: 40),

              // SUBMIT BUTTON
              SizedBox(
                width: double.infinity, height: 60,
                child: ElevatedButton(
                  onPressed: provider.isCreating ? null : _createCourse,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 5,
                  ),
                  child: provider.isCreating
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Create Workspace", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField(String hint, TextEditingController controller, IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
      ),
    );
  }
}