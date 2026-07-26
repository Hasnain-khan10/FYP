import 'package:flutter/material.dart';
import 'package:frontened/Provider/course_provider.dart';
import 'package:provider/provider.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});
  static const String routeName = '/courses';

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<CourseProvider>().fetchCourses();
    });
  }

  Future<void> _refresh() async {
    await context.read<CourseProvider>().fetchCourses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF4F46E5),
        automaticallyImplyLeading: false,
        title: const Text("My Learning", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Consumer<CourseProvider>(
        builder: (context, provider, child) {
          final courses = provider.courses.toList()..sort((a, b) => b.id.compareTo(a.id));

          // 🔥 100% threshold fix kiya gaya hai (Progress is out of 100 now)
          final activeCourses = courses.where((c) => c.progress < 100.0).toList();
          final completedCourses = courses.where((c) => c.progress >= 100.0).toList();

          if (provider.isLoading) return const Center(child: CircularProgressIndicator());

          return RefreshIndicator(
            onRefresh: _refresh,
            color: const Color(0xFF4F46E5),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text("Active Courses", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B))),
                const SizedBox(height: 16),
                if (activeCourses.isEmpty)
                  const _EmptyState(icon: Icons.menu_book, message: "No active courses found.")
                else
                  ...activeCourses.map((course) => _CourseCard(
                    title: course.title,
                    instructor: course.teacherName ?? "Instructor",
                    progress: (course.progress / 100).clamp(0.0, 1.0), // Fixed to pass 0.0 to 1.0
                    onTap: () => Navigator.pushNamed(context, '/course-detail', arguments: course),
                  )),

                const SizedBox(height: 30),

                const Text("Completed Courses", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B))),
                const SizedBox(height: 16),
                if (completedCourses.isEmpty)
                  const _EmptyState(icon: Icons.workspace_premium, message: "You haven't completed any course yet.")
                else
                  ...completedCourses.map((course) => _CourseCard(
                    title: course.title,
                    instructor: course.teacherName ?? "Instructor",
                    progress: 1.0,
                    isCompleted: true,
                    onTap: () => Navigator.pushNamed(context, '/course-detail', arguments: course),
                  )),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final String title; final String instructor; final double progress; final bool isCompleted; final VoidCallback onTap;
  const _CourseCard({required this.title, required this.instructor, required this.progress, required this.onTap, this.isCompleted = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: isCompleted ? Colors.green.withValues(alpha: 0.1) : const Color(0xFF4F46E5).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(isCompleted ? Icons.workspace_premium : Icons.class_, color: isCompleted ? Colors.green : const Color(0xFF4F46E5))),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E1B4B))), const SizedBox(height: 4), Text(instructor, style: const TextStyle(color: Colors.grey, fontSize: 12))])),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: LinearProgressIndicator(value: progress, color: isCompleted ? Colors.green : const Color(0xFF4F46E5), backgroundColor: Colors.grey.shade200, borderRadius: BorderRadius.circular(10))),
                const SizedBox(width: 12),
                Text(isCompleted ? "Done" : "${(progress * 100).toInt()}%", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isCompleted ? Colors.green : const Color(0xFF4F46E5))),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon; final String message;
  const _EmptyState({required this.icon, required this.message});
  @override
  Widget build(BuildContext context) {
    return Container(width: double.infinity, padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)), child: Column(children: [Icon(icon, size: 40, color: Colors.grey.shade400), const SizedBox(height: 12), Text(message, style: const TextStyle(color: Colors.grey))]));
  }
}