import 'package:flutter/material.dart';
import 'package:frontened/Provider/pdf_provider.dart';
import 'package:frontened/Provider/quiz_provider.dart';
import 'package:frontened/Provider/week_plan_provider.dart';
import 'package:provider/provider.dart';

class CourseDetailScreen extends StatefulWidget {
  const CourseDetailScreen({super.key});
  static const String routeName = '/course-detail';

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> with SingleTickerProviderStateMixin {
  bool _loaded = false;
  late final course;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null) {
      course = args;
      Future.microtask(() {
        context.read<WeekPlanProvider>().fetchPlan(course.id);
        context.read<QuizProvider>().fetchAllQuizzes(); // Fetch quizzes to filter later
      });
      _loaded = true;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF4F46E5),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(course.title ?? "Course Workspace", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            Text("Instructor: ${course.teacherName ?? "Unknown"}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(15)),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              labelColor: const Color(0xFF4F46E5),
              unselectedLabelColor: Colors.white,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [Tab(text: "Syllabus"), Tab(text: "Quizzes")],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildSyllabusTab(), _buildQuizzesTab()],
      ),
    );
  }

  Widget _buildSyllabusTab() {
    final provider = context.watch<WeekPlanProvider>();
    final pdfProvider = context.watch<PdfProvider>();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // MASTER PDF BUTTON
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))]),
            child: Row(
              children: [
                const Icon(Icons.picture_as_pdf, color: Colors.red, size: 30),
                const SizedBox(width: 12),
                const Expanded(child: Text("Course Outline.pdf", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                ElevatedButton(
                  onPressed: pdfProvider.isLoading ? null : () => pdfProvider.openPDF(course.id),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: pdfProvider.isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Open", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text("18-Week Plan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B))),
          const SizedBox(height: 12),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : (provider.plan == null || provider.plan!.weeks.isEmpty)
                ? const Center(child: Text("No Weekly Plan Found", style: TextStyle(color: Colors.grey)))
                : ListView.builder(
              itemCount: provider.plan!.weeks.length,
              itemBuilder: (context, index) {
                final week = provider.plan!.weeks[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: const Color(0xFF4F46E5).withValues(alpha: 0.1), child: Text("${week.weekNumber}", style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold))),
                    title: Text("Week ${week.weekNumber}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(week.subTopics.join(", "), maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: provider.isWeekLoading(week.weekNumber)
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : IconButton(
                      icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                      onPressed: () => provider.downloadAndOpenWeekPDF(course.id, week.weekNumber),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizzesTab() {
    final provider = context.watch<QuizProvider>();
    final courseQuizzes = provider.quizzes.where((q) => q.course == course.id).toList();

    if (provider.isLoading) return const Center(child: CircularProgressIndicator());
    if (courseQuizzes.isEmpty) return const Center(child: Text("No quizzes assigned for this course yet.", style: TextStyle(color: Colors.grey)));

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: courseQuizzes.length,
      itemBuilder: (context, index) {
        final quiz = courseQuizzes[index];
        final isCompleted = quiz.isCompleted == true;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Icon(isCompleted ? Icons.check_circle : Icons.quiz, color: isCompleted ? Colors.green : const Color(0xFF4F46E5), size: 30),
            title: Text(quiz.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(isCompleted ? "Score: ${quiz.score ?? 0} Marks" : "Pending Attempt", style: TextStyle(color: isCompleted ? Colors.green : Colors.orange, fontWeight: FontWeight.bold)),
            trailing: isCompleted
                ? const Icon(Icons.arrow_forward_ios, size: 16)
                : ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/quiz-attempt', arguments: quiz),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: const Text("Attempt", style: TextStyle(color: Colors.white)),
            ),
            onTap: isCompleted ? () => Navigator.pushNamed(context, '/quiz-result', arguments: quiz) : null,
          ),
        );
      },
    );
  }
}