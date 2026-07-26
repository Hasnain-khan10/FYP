import 'package:flutter/material.dart';
import 'package:frontened/screens/Teacher/Quiz/AiMCQSQuizScreen.dart';
import 'package:frontened/screens/Teacher/Quiz/AiQuestionQuizScreen.dart';
import 'package:frontened/screens/Teacher/Quiz/TeacherManuallyQuizScreen.dart';

class TeacherCreateQuizScreen extends StatefulWidget {
  static const String createQuiz = '/create-quiz';
  final String courseId;
  final String courseTitle;

  const TeacherCreateQuizScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  State<TeacherCreateQuizScreen> createState() => _TeacherCreateQuizScreenState();
}

class _TeacherCreateQuizScreenState extends State<TeacherCreateQuizScreen> {
  final TextEditingController _titleController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _navigateIfValid(Widget targetScreen) {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please enter a Quiz Title first!"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => targetScreen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF4F46E5),
        title: Text("Create Quiz - ${widget.courseTitle}", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Step 1: Define Quiz Title", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300, width: 1.5),
                ),
                child: TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: "e.g., Mid-Term Examination",
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 35),
              const Text("Step 2: Choose Generation Engine", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 20),

              // 🔥 MANUAL CREATION ROUTE
              _WaveButton(
                title: "Create Manually",
                icon: Icons.edit_note,
                colors: const [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                onTap: () => _navigateIfValid(TeacherManualQuizScreen(
                    courseId: widget.courseId,
                    quizTitle: _titleController.text.trim()
                )),
              ),
              const SizedBox(height: 20),
              _WaveButton(
                title: "Generate MCQs via AI",
                icon: Icons.auto_awesome,
                colors: const [Color(0xFF2563EB), Color(0xFF3B82F6)],
                onTap: () => _navigateIfValid(TeacherAIMCQSQuizScreen(courseId: widget.courseId, quizTitle: _titleController.text.trim())),
              ),
              const SizedBox(height: 20),
              _WaveButton(
                title: "Generate Theory via AI",
                icon: Icons.text_snippet,
                colors: const [Color(0xFF9333EA), Color(0xFFA855F7)],
                onTap: () => _navigateIfValid(TeacherAIQuestionQuizScreen(courseId: widget.courseId, quizTitle: _titleController.text.trim())),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WaveButton extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  const _WaveButton({required this.title, required this.icon, required this.colors, required this.onTap});

  @override
  State<_WaveButton> createState() => _WaveButtonState();
}

class _WaveButtonState extends State<_WaveButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: 1.0 + (_controller.value * 0.15),
                child: Opacity(
                  opacity: 1.0 - _controller.value,
                  child: Container(
                    width: double.infinity, height: 65,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: widget.colors.first.withAlpha((0.4 * 255).toInt())
                    ),
                  ),
                ),
              ),
              Container(
                width: double.infinity, height: 65,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(colors: widget.colors),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.icon, color: Colors.white),
                    const SizedBox(width: 10),
                    Text(widget.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}