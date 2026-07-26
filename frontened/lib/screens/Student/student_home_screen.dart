import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontened/Provider/auth_provider.dart';
import 'package:frontened/Provider/course_provider.dart';
import 'package:frontened/Provider/quiz_provider.dart';
import 'package:provider/provider.dart';
import 'package:frontened/models/Quiz/quiz_model.dart';
import 'package:frontened/screens/Student/Courses/JoinCourseScreen.dart';
import 'package:frontened/screens/Student/Profile/ProfileScreen.dart';
import 'package:intl/intl.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});
  static const String routeName = '/student-home';

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  Timer? _homeTimer;

  @override
  void initState() {
    super.initState();
    _loadData();

    _homeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _homeTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      context.read<CourseProvider>().fetchCourses(),
      context.read<QuizProvider>().fetchAllQuizzes(),
      context.read<AuthProvider>().loadProfile(),
    ]);
  }

  String _formatDuration(Duration d) {
    if (d.isNegative) return "00:00:00";
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String days = d.inDays > 0 ? "${d.inDays}d " : "";
    String hours = twoDigits(d.inHours.remainder(24));
    String minutes = twoDigits(d.inMinutes.remainder(60));
    String seconds = twoDigits(d.inSeconds.remainder(60));
    return "$days$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final quizProvider = context.watch<QuizProvider>();
    final authProvider = context.watch<AuthProvider>();
    final student = authProvider.user;
    final courseProvider = context.watch<CourseProvider>();
    final courses = courseProvider.courses;
    final now = DateTime.now();

    // 🔥 FIX: Extract list of active enrolled course IDs
    final List<String> enrolledCourseIds = courses.map((c) => c.id.toString().trim()).toList();

    // 🔥 FIX: Only show quizzes that belong to enrolled courses AND match deadline state
    final pendingQuizzes = quizProvider.quizzes.where((q) {
      final qCourseId = (q.course ?? "").toString().trim();
      if (!enrolledCourseIds.contains(qCourseId)) return false; // Hide if student hasn't joined this course!
      
      if (q.isCompleted == true) return false;
      final deadline = q.deadlineDateTime;
      if (deadline != null && now.isAfter(deadline)) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, JoinCourseScreen.routeName).then((_) => _loadData()),
        backgroundColor: const Color(0xFF16A34A),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: const Color(0xFF4F46E5),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentProfileScreen())),
                      child: CircleAvatar(
                        radius: 25,
                        backgroundColor: const Color(0xFF4F46E5).withAlpha(40),
                        backgroundImage: (student?.profileImage != null && student!.profileImage!.isNotEmpty) ? NetworkImage(student.profileImage!) : null,
                        child: (student?.profileImage == null || student!.profileImage!.isEmpty) ? const Icon(Icons.person, color: Color(0xFF4F46E5)) : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Hello, ${student?.name ?? 'Student'} 👋", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const Text("Student Dashboard", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                const Text("Enrolled Courses", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B))),
                const SizedBox(height: 15),
                if (courseProvider.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (courses.isEmpty)
                  const Center(child: Text("No courses joined yet.", style: TextStyle(color: Colors.grey)))
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 1.3,
                    ),
                    itemCount: courses.length,
                    itemBuilder: (context, index) {
                      final course = courses[index];
                      return GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/course-detail', arguments: course),
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white, borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 5)],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.menu_book_rounded, color: Color(0xFF4F46E5), size: 30),
                              const SizedBox(height: 10),
                              Text(course.title, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 35),
                const Text("Pending Quizzes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B))),
                const SizedBox(height: 12),
                if (quizProvider.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (pendingQuizzes.isEmpty)
                  const Text("No pending quizzes.", style: TextStyle(color: Colors.grey))
                else
                  ...pendingQuizzes.map((quiz) {
                    final openDate = quiz.openDateTime;
                    final deadline = quiz.deadlineDateTime;
                    final isLocked = openDate != null && now.isBefore(openDate);

                    return GestureDetector(
                      onTap: () {
                        if (isLocked) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Exam Locked! This exam unlocks at ${DateFormat('hh:mm a, dd MMM').format(openDate.toLocal())}"),
                                backgroundColor: Colors.redAccent,
                                behavior: SnackBarBehavior.floating,
                              )
                          );
                        } else {
                          Navigator.pushNamed(context, '/quiz-attempt', arguments: quiz);
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isLocked ? Colors.grey.withValues(alpha: 0.08) : Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: isLocked ? Colors.grey.shade300 : Colors.red.shade100, width: 1.5),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 4)],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Icon(isLocked ? Icons.lock : Icons.assignment_late_outlined, color: isLocked ? Colors.grey : Colors.red, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      quiz.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isLocked ? Colors.grey : const Color(0xFF1E1B4B))
                                  ),
                                  const SizedBox(height: 6),

                                  Row(
                                    children: [
                                      Icon(Icons.date_range, size: 12, color: isLocked ? Colors.orange : Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Start: ${openDate != null ? DateFormat('dd MMM, hh:mm a').format(openDate.toLocal()) : 'Immediate'}",
                                        style: TextStyle(color: isLocked ? Colors.orange.shade800 : Colors.grey.shade600, fontSize: 11, fontWeight: isLocked ? FontWeight.bold : FontWeight.normal),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),

                                  Row(
                                    children: [
                                      Icon(Icons.alarm, size: 12, color: isLocked ? Colors.grey : Colors.red.shade300),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Deadline: ${deadline != null ? DateFormat('dd MMM, hh:mm a').format(deadline.toLocal()) : 'No Limit'}",
                                        style: TextStyle(color: isLocked ? Colors.grey.shade600 : Colors.red.shade700, fontSize: 11, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),

                                  if (!isLocked && deadline != null) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      "Ends in: ${_formatDuration(deadline.difference(now))}",
                                      style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ]
                                ],
                              ),
                            ),
                            const SizedBox(width: 5),
                            Icon(isLocked ? Icons.lock_outline : Icons.chevron_right, color: isLocked ? Colors.grey : Colors.red, size: 22),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}