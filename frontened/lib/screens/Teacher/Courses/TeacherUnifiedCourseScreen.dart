import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontened/Provider/course_provider.dart';
import 'package:frontened/Provider/quiz_provider.dart';
import 'package:frontened/Provider/week_plan_provider.dart';
import 'package:frontened/core/api.dart';
import 'package:frontened/services/storage_service.dart';
import 'package:frontened/screens/Teacher/Courses/GenerateAIPlanScreen.dart';
import 'package:frontened/screens/Teacher/Quiz/CreateQuizScreen.dart';
import 'package:frontened/screens/Teacher/Quiz/TeacherQuizManagementCenter.dart';
import 'package:frontened/models/week_plan_model.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;

class TeacherUnifiedCourseScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;

  const TeacherUnifiedCourseScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  State<TeacherUnifiedCourseScreen> createState() => _TeacherUnifiedCourseScreenState();
}

class _TeacherUnifiedCourseScreenState extends State<TeacherUnifiedCourseScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    Future.microtask(() {
      _refreshAllData();
    });
  }

  Future<void> _refreshAllData() async {
    await context.read<WeekPlanProvider>().fetchPlan(widget.courseId);
    await context.read<QuizProvider>().fetchQuizzes(widget.courseId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _copyJoinLink() {
    try {
      final courses = context.read<CourseProvider>().courses;
      final currentCourse = courses.firstWhere((c) => c.id.toString() == widget.courseId.toString());

      if (currentCourse.joinLink != null && currentCourse.joinLink!.isNotEmpty) {
        Clipboard.setData(ClipboardData(text: currentCourse.joinLink!));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Join link copied to clipboard!"), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invite link not available."), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Course data not found."), backgroundColor: Colors.red));
    }
  }

  void _shareWeekToAI(WeekModel week) {
    String textToShare = """
I am preparing a lecture for university students. Can you provide a highly detailed and expansive explanation for the following topic?

*Course:* ${widget.courseTitle}
*Week ${week.weekNumber}:* ${week.title}
*Definition:* ${week.definition}
*Sub-Topics:* ${week.subTopics.join(", ")}
*Analogy Idea:* ${week.realWorldAnalogy}

Please expand on this comprehensively.
""";
    Share.share(textToShare);
  }

  Future<void> _deleteSubject() async {
    final bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text("Delete Subject?", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          "Are you absolutely sure you want to delete this Subject? \n\nThis will permanently erase all Weekly Plans, Quizzes, and Student Records linked to this course. This action cannot be undone!",
          style: TextStyle(height: 1.4, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Yes, Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm && mounted) {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.red)));

      try {
        final token = await StorageService.getToken();
        final response = await http.delete(
          Uri.parse("${Api.baseUrl}/courses/${widget.courseId}"),
          headers: {"Authorization": "Bearer $token", "Content-Type": "application/json"},
        );

        if (mounted) Navigator.pop(context);

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Subject and all data deleted successfully!"), backgroundColor: Colors.green));
          context.read<CourseProvider>().fetchCourses();
          Navigator.pop(context);
        } else {
          final errorMsg = jsonDecode(response.body)['message'] ?? "Failed to delete subject.";
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ $errorMsg"), backgroundColor: Colors.red));
        }
      } catch (e) {
        if (mounted) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Connection Error: $e"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF4F46E5),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.courseTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            const Text("Course Management Workspace", style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(tooltip: "Copy Student Invite Link", icon: const Icon(Icons.share, color: Colors.white), onPressed: _copyJoinLink),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              if (value == 'delete') _deleteSubject();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(children: [Icon(Icons.delete_forever, color: Colors.red, size: 20), SizedBox(width: 10), Text("Delete Subject", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))]),
              ),
            ],
          )
        ],
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
              tabs: const [Tab(text: "18-Week Syllabus"), Tab(text: "Quizzes & Exams")],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSyllabusTab(),
          _buildQuizzesTab(),
        ],
      ),
    );
  }

  // ===============================================
  // SYLLABUS TAB (PULL-TO-REFRESH ENABLED)
  // ===============================================
  Widget _buildSyllabusTab() {
    final provider = context.watch<WeekPlanProvider>();
    final plan = provider.plan;

    if (provider.isLoading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      color: const Color(0xFF4F46E5),
      onRefresh: () async {
        await provider.fetchPlan(widget.courseId);
      },
      child: (plan == null || plan.weeks.isEmpty)
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _AnimatedWaveButtonSquare(
                        title: "Create AI Weekly Plan",
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherAIWeekPlanScreen(courseId: widget.courseId))).then((_) => _refreshAllData()),
                      ),
                      const SizedBox(height: 20),
                      const Text("No Syllabus Found", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: plan.weeks.length,
              itemBuilder: (context, index) {
                final week = plan.weeks[index];
                final bool isWorking = provider.isWeekActionLoading(week.weekNumber);

                return Card(
                  elevation: 0, margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade300)),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                        child: isWorking ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text("${week.weekNumber}", style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
                      ),
                      title: Text(week.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Text(week.subTopics.join(", "), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit, color: Colors.orange, size: 20), onPressed: () => _showEditChoiceDialog(week, plan.id, plan.weeks)),
                          IconButton(icon: const Icon(Icons.download, color: Colors.blue, size: 20), onPressed: () => provider.downloadAndOpenWeekPDF(widget.courseId, week.weekNumber)),
                          IconButton(icon: const Icon(Icons.share, color: Colors.green, size: 20), onPressed: () => _shareWeekToAI(week)),
                        ],
                      ),
                      childrenPadding: const EdgeInsets.all(16),
                      children: [
                        if (week.definition.isNotEmpty)
                          Container(
                            width: double.infinity, padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10), border: const Border(left: BorderSide(color: Colors.blue, width: 4))),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Core Definition", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)), const SizedBox(height: 4), Text(week.definition, style: TextStyle(fontSize: 14, color: Colors.blue.shade900))]),
                          ),
                        const SizedBox(height: 12),
                        if (week.detailedExplanation.isNotEmpty) ...[
                          const Align(alignment: Alignment.centerLeft, child: Text("Brief Explanation", style: TextStyle(fontWeight: FontWeight.bold))),
                          const SizedBox(height: 6),
                          Text(week.detailedExplanation, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5)),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showEditChoiceDialog(WeekModel week, String planId, List<WeekModel> allWeeks) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("Edit Week"), actionsAlignment: MainAxisAlignment.center, actions: [ElevatedButton(onPressed: (){ Navigator.pop(ctx); _showAIEditDialog(week);}, child: const Text("AI Edit")), ElevatedButton(onPressed: (){ Navigator.pop(ctx); _showManualEditDialog(week, planId, allWeeks);}, child: const Text("Manual Edit"))]));
  }
  void _showAIEditDialog(WeekModel week) {
    final TextEditingController promptCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("AI Edit"), content: TextField(controller: promptCtrl), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")), ElevatedButton(onPressed: () { if (promptCtrl.text.isNotEmpty) { context.read<WeekPlanProvider>().updateWeekAI(widget.courseId, week.weekNumber, prompt: promptCtrl.text); } Navigator.pop(ctx); }, child: const Text("Apply"))]));
  }
  void _showManualEditDialog(WeekModel week, String planId, List<WeekModel> allWeeks) {
    final titleCtrl = TextEditingController(text: week.title);
    final defCtrl = TextEditingController(text: week.definition);
    final expCtrl = TextEditingController(text: week.detailedExplanation);
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("Manual Edit"), content: SingleChildScrollView(child: Column(children: [TextField(controller: titleCtrl), TextField(controller: defCtrl), TextField(controller: expCtrl)])), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")), ElevatedButton(onPressed: () { final index = allWeeks.indexWhere((w) => w.weekNumber == week.weekNumber); if (index != -1) { allWeeks[index] = WeekModel(weekNumber: week.weekNumber, title: titleCtrl.text, definition: defCtrl.text, detailedExplanation: expCtrl.text, subTopics: week.subTopics, codeOrQuerySnippet: week.codeOrQuerySnippet, realWorldAnalogy: week.realWorldAnalogy); context.read<WeekPlanProvider>().updatePlan(planId, allWeeks); } Navigator.pop(ctx); }, child: const Text("Save"))]));
  }

  // ===============================================
  // QUIZZES TAB (FIXED: Direct Provider List + Pull-To-Refresh)
  // ===============================================
  Widget _buildQuizzesTab() {
    final provider = context.watch<QuizProvider>();
    
    // 🔥 FIX: Direct provider.quizzes array reference without strict String comparison blockage!
    final courseQuizzes = provider.quizzes;

    return RefreshIndicator(
      color: const Color(0xFF4F46E5),
      onRefresh: () async {
        await context.read<QuizProvider>().fetchQuizzes(widget.courseId);
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0), 
            child: _AnimatedWaveButtonSquare(
              title: "Create New Exam", 
              onTap: () => Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => TeacherCreateQuizScreen(courseId: widget.courseId, courseTitle: widget.courseTitle))
              ).then((_) => context.read<QuizProvider>().fetchQuizzes(widget.courseId))
            )
          ),
          Expanded(
            child: provider.isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
              : courseQuizzes.isEmpty 
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 100),
                      Center(child: Text("No quizzes found. Drag down to refresh.", style: TextStyle(color: Colors.grey))),
                    ],
                  ) 
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: courseQuizzes.length,
                    itemBuilder: (context, index) {
                      final quiz = courseQuizzes[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12), 
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                        child: ListTile(
                          leading: CircleAvatar(backgroundColor: Colors.green.shade50, child: const Icon(Icons.assignment, color: Colors.green)), 
                          title: Text(quiz.title, style: const TextStyle(fontWeight: FontWeight.bold)), 
                          subtitle: Text("${quiz.type.toUpperCase()} Format • ${quiz.totalMarks} Marks"), 
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14), 
                          onTap: () => Navigator.push(
                            context, 
                            MaterialPageRoute(
                              builder: (_) => TeacherQuizManagementCenter(
                                quizId: quiz.id, 
                                courseId: widget.courseId, 
                                quizTitle: quiz.title, 
                                quizType: quiz.type, 
                                totalMarks: quiz.totalMarks
                              )
                            )
                          ).then((_) => context.read<QuizProvider>().fetchQuizzes(widget.courseId))
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedWaveButtonSquare extends StatefulWidget {
  final VoidCallback onTap; final String title;
  const _AnimatedWaveButtonSquare({required this.onTap, required this.title});
  @override State<_AnimatedWaveButtonSquare> createState() => _AnimatedWaveButtonSquareState();
}
class _AnimatedWaveButtonSquareState extends State<_AnimatedWaveButtonSquare> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override void initState() { super.initState(); _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(); }
  @override void dispose() { _controller.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Stack(alignment: Alignment.center, children: [Transform.scale(scale: 1.0 + (_controller.value * 0.2), child: Opacity(opacity: 1.0 - _controller.value, child: Container(width: 250, height: 60, decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: const Color(0xFF4F46E5).withValues(alpha: 0.4))))), Container(width: 250, height: 60, decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))]), child: Center(child: Text(widget.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))))]),
      ),
    );
  }
}