import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontened/Provider/auth_provider.dart';
import 'package:frontened/Provider/course_provider.dart';
import 'package:frontened/Provider/quiz_provider.dart';
import 'package:frontened/models/Quiz/quiz_model.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontened/screens/Student/Courses/JoinCourseScreen.dart';
import 'package:frontened/screens/Student/Profile/ProfileScreen.dart';
import 'package:frontened/services/socket_service.dart';
import 'package:intl/intl.dart';

class MainScreen extends StatefulWidget {
  static const String routeName = '/student-placeholder';
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<Map<String, String>> _deletedCourseAlerts = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadData();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      context.read<CourseProvider>().fetchCourses(),
      context.read<QuizProvider>().fetchAllQuizzes(),
      context.read<AuthProvider>().loadProfile(),
    ]);

    if (mounted) {
      final courseProvider = context.read<CourseProvider>();
      if (courseProvider.error == null) {
        await _syncCacheAndFindDeleted(courseProvider.courses);

        try {
          List<String> activeCourseIds = courseProvider.courses
              .map((c) => c.id.toString())
              .toList();
          SocketService.initialize(context, activeCourseIds);
        } catch (e) {
          debugPrint("Real-time Tunnel Boot Exception Error: $e");
        }
      }
    }
  }

  Future<void> _syncCacheAndFindDeleted(List<dynamic> currentCourses) async {
    final authProvider = context.read<AuthProvider>();
    final String studentId = authProvider.user?.id ?? "fallback_id";
    final String cacheKey = 'smart_cache_courses_v3_$studentId';

    final prefs = await SharedPreferences.getInstance();
    final String? cachedData = prefs.getString(cacheKey);

    List<Map<String, dynamic>> previousCourses = [];
    if (cachedData != null) {
      try {
        List<dynamic> decoded = jsonDecode(cachedData);
        previousCourses = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (e) {
        previousCourses = [];
      }
    }

    List<String> currentCourseIds = currentCourses.map((c) => c.id.toString()).toList();
    List<Map<String, String>> newlyDeleted = [];

    for (var prev in previousCourses) {
      String prevId = prev['id'].toString();
      String prevTitle = prev['title'].toString();
      String isDeleted = prev['isDeleted'].toString();

      if (!currentCourseIds.contains(prevId) && isDeleted != "true") {
        newlyDeleted.add({"id": prevId, "title": prevTitle, "isDeleted": "true"});
      } else if (isDeleted == "true") {
        newlyDeleted.add({"id": prevId, "title": prevTitle, "isDeleted": "true"});
      }
    }

    setState(() {
      _deletedCourseAlerts = newlyDeleted;
    });

    List<Map<String, dynamic>> newCache = currentCourses.map((c) => {
      "id": c.id.toString(),
      "title": c.title.toString(),
      "isDeleted": "false"
    }).toList();

    newCache.addAll(newlyDeleted);
    await prefs.setString(cacheKey, jsonEncode(newCache));
  }

  Future<void> _dismissDeletedCard(String courseId) async {
    setState(() {
      _deletedCourseAlerts.removeWhere((c) => c['id'] == courseId);
    });

    final authProvider = context.read<AuthProvider>();
    final String studentId = authProvider.user?.id ?? "fallback_id";
    final String cacheKey = 'smart_cache_courses_v3_$studentId';

    final prefs = await SharedPreferences.getInstance();
    final String? cachedData = prefs.getString(cacheKey);

    if (cachedData != null) {
      List<dynamic> cacheList = jsonDecode(cachedData);
      cacheList.removeWhere((c) => c['id'].toString() == courseId);
      await prefs.setString(cacheKey, jsonEncode(cacheList));
    }
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

    // 🔥 FIX: Only display quizzes belonging to joined courses!
    final pendingQuizzes = quizProvider.quizzes.where((q) {
      final qCourseId = (q.course ?? "").toString().trim();
      if (!enrolledCourseIds.contains(qCourseId)) return false; // Skip quizzes of unjoined courses!
      
      if (q.isCompleted == true) return false;
      final deadline = q.deadlineDateTime;
      if (deadline != null && now.isAfter(deadline)) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: _AnimatedWaveButton(
        onTap: () => Navigator.pushNamed(context, JoinCourseScreen.routeName).then((_) => _loadData()),
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
                        backgroundImage: (student != null && student.profileImage != null && student.profileImage!.isNotEmpty)
                            ? NetworkImage(student.profileImage!)
                            : null,
                        child: (student == null || student.profileImage == null || student.profileImage!.isEmpty)
                            ? const Icon(Icons.person, color: Color(0xFF4F46E5))
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Hello, ${student?.name ?? 'Student'} 👋", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B))),
                          const Text("Student Dashboard", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Enrolled Courses", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B))),
                    Text("${courses.length} Active", style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 15),

                ..._deletedCourseAlerts.map((delCourse) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red.shade300, width: 1.5)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 24), const SizedBox(width: 8), Expanded(child: Text("${delCourse['title']} (Removed)", style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold, fontSize: 16)))],
                      ),
                      const SizedBox(height: 8),
                      Text("The instructor has permanently deleted this subject.", style: TextStyle(color: Colors.red.shade700, fontSize: 13, height: 1.4)),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white, elevation: 0), onPressed: () => _dismissDeletedCard(delCourse['id']!), child: const Text("OK, Got it", style: TextStyle(fontWeight: FontWeight.bold))),
                      )
                    ],
                  ),
                )),

                if (courseProvider.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (courses.isEmpty && _deletedCourseAlerts.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No courses joined yet.", style: TextStyle(color: Colors.grey))))
                else
                  ...courses.map((course) => GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/course-detail', arguments: course),
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 5)],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: const Color(0xFF4F46E5).withAlpha(25), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.menu_book_rounded, color: Color(0xFF4F46E5)),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Text(
                                course.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E1B4B))
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                        ],
                      ),
                    ),
                  )),

                const SizedBox(height: 30),
                const Text("Pending Exams", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B))),
                const SizedBox(height: 12),

                if (quizProvider.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (pendingQuizzes.isEmpty)
                  const Text("No pending exams. Great job!", style: TextStyle(color: Colors.grey))
                else
                  ...pendingQuizzes.map((quiz) => LiveQuizCard(quiz: quiz)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LiveQuizCard extends StatelessWidget {
  final Quiz quiz;
  const LiveQuizCard({super.key, required this.quiz});

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
    final now = DateTime.now();
    final openDate = quiz.openDateTime;
    final deadline = quiz.deadlineDateTime;

    final isLocked = openDate != null && now.isBefore(openDate);

    return GestureDetector(
      onTap: () {
        if (isLocked) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Exam Locked! This exam will activate precisely at ${DateFormat('hh:mm a, dd MMM').format(openDate.toLocal())}"),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
              )
          );
        } else {
          Navigator.pushNamed(context, '/quiz-attempt', arguments: quiz);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isLocked ? Colors.grey.withAlpha(15) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isLocked ? Colors.grey.withAlpha(80) : Colors.green.withAlpha(100), width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4)],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(isLocked ? Icons.lock_outline : Icons.play_circle_fill, color: isLocked ? Colors.grey : Colors.green, size: 26),
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
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isLocked ? Colors.grey.shade700 : const Color(0xFF1E1B4B))
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 13, color: isLocked ? Colors.orange : Colors.grey),
                      const SizedBox(width: 5),
                      Text(
                        "Start: ${openDate != null ? DateFormat('dd MMM, hh:mm a').format(openDate.toLocal()) : 'Immediate'}",
                        style: TextStyle(color: isLocked ? Colors.orange.shade800 : Colors.grey.shade600, fontSize: 12, fontWeight: isLocked ? FontWeight.bold : FontWeight.normal),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 13, color: isLocked ? Colors.grey : Colors.red.shade400),
                      const SizedBox(width: 5),
                      Text(
                        "Deadline: ${deadline != null ? DateFormat('dd MMM, hh:mm a').format(deadline.toLocal()) : 'No Limit'}",
                        style: TextStyle(color: isLocked ? Colors.grey.shade600 : Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),

                  if (!isLocked && deadline != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      "Remaining: ${_formatDuration(deadline.difference(now))}",
                      style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.2),
                    ),
                  ]
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(isLocked ? Icons.lock_clock : Icons.chevron_right, color: isLocked ? Colors.grey : Colors.green, size: 24),
          ],
        ),
      ),
    );
  }
}

class _AnimatedWaveButton extends StatefulWidget {
  final VoidCallback onTap;
  const _AnimatedWaveButton({required this.onTap});
  @override
  State<_AnimatedWaveButton> createState() => _AnimatedWaveButtonState();
}
class _AnimatedWaveButtonState extends State<_AnimatedWaveButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() { super.initState(); _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(); }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(animation: _controller, builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(scale: 1.0 + (_controller.value * 0.4), child: Opacity(opacity: 1.0 - _controller.value, child: Container(width: 65, height: 65, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF16A34A).withAlpha(128))))),
            Container(width: 65, height: 65, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFF16A34A), Color(0xFF22C55E)]), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))]), child: const Icon(Icons.add, color: Colors.white, size: 30))
          ],
        );
      }),
    );
  }
}