import 'package:flutter/material.dart';
import 'package:frontened/Provider/auth_provider.dart';
import 'package:frontened/Provider/course_provider.dart';
import 'package:frontened/screens/Teacher/Courses/CreatecourseScreen.dart';
import 'package:frontened/screens/Teacher/Teacher_ProfileScreen.dart';
import 'package:provider/provider.dart';
import 'package:frontened/screens/Teacher/Courses/TeacherUnifiedCourseScreen.dart';

class TeacherDashboardScreen extends StatefulWidget {
  static const String teacherRouteName = '/teacher-dashboard';

  const TeacherDashboardScreen({super.key});

  static const Color primary = Color(0xFF4F46E5);
  static const Color secondary = Color(0xFF7C3AED);
  static const Color background = Colors.white;
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1E1B4B);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE9EAF4);

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      await context.read<AuthProvider>().loadProfile();
      await context.read<CourseProvider>().fetchCourses();
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final courseProvider = context.watch<CourseProvider>();
    final courses = courseProvider.courses;
    courses.sort((a, b) => b.id.compareTo(a.id));

    return Scaffold(
      backgroundColor: TeacherDashboardScreen.background,

      floatingActionButton: _AnimatedWaveButton(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const TeacherCreateCourseScreen(quiz: []),
            ),
          ).then((_) => context.read<CourseProvider>().fetchCourses());
        },
      ),

      body: SafeArea(
        child: RefreshIndicator(
          color: TeacherDashboardScreen.primary,
          onRefresh: () async {
            await _loadInitialData();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(context, courses.length),
                const SizedBox(height: 18),
                _buildGreetingCard(context),
                const SizedBox(height: 24),

                const Text(
                  'Your Workspaces',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: TeacherDashboardScreen.textPrimary,
                  ),
                ),

                const SizedBox(height: 16),

                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(30),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (courses.isEmpty)
                  _buildEmptyState()
                else
                  Column(
                    children: courses.map((course) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildCourseCard(
                          context,
                          title: course.title,
                          subtitle: '${course.courseCode} • ${course.creditHours} Cr. Hours',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TeacherUnifiedCourseScreen(
                                  courseId: course.id,
                                  courseTitle: course.title,
                                ),
                              ),
                            ).then((_) => context.read<CourseProvider>().fetchCourses());
                          },
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, int totalCourses) {
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherProfileScreen())).then((_) => _loadInitialData()),
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(Icons.menu_rounded, size: 28, color: TeacherDashboardScreen.textPrimary),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: TeacherDashboardScreen.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: TeacherDashboardScreen.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _topStatItem(icon: Icons.menu_book_rounded, title: "Active Courses", value: "$totalCourses"),
                Container(height: 34, width: 1, color: TeacherDashboardScreen.border),
                _topStatItem(icon: Icons.school_rounded, title: "Role", value: "Teacher"),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _topStatItem({required IconData icon, required String title, required String value}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: TeacherDashboardScreen.primary),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: TeacherDashboardScreen.textPrimary)),
        Text(title, style: const TextStyle(fontSize: 11, color: TeacherDashboardScreen.textSecondary, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildGreetingCard(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: TeacherDashboardScreen.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: TeacherDashboardScreen.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: user == null
                ? const Center(child: CircularProgressIndicator())
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome, ${user.name} 👋', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const Text('Manage your syllabus, students, and quizzes.', style: TextStyle(fontSize: 14, color: TeacherDashboardScreen.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, {required String title, required String subtitle, required VoidCallback onTap}) {
    return Material(
      color: TeacherDashboardScreen.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: TeacherDashboardScreen.border),
          ),
          child: Row(
            children: [
              Container(
                width: 54, height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [TeacherDashboardScreen.primary, TeacherDashboardScreen.secondary]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.class_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 13, color: TeacherDashboardScreen.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(color: TeacherDashboardScreen.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: TeacherDashboardScreen.border)),
      child: const Column(
        children: [
          Icon(Icons.folder_open_rounded, size: 54, color: Colors.grey),
          SizedBox(height: 14),
          Text('No Workspaces Found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ],
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
                scale: 1.0 + (_controller.value * 0.5),
                child: Opacity(
                  opacity: 1.0 - _controller.value,
                  child: Container(
                    width: 65, height: 65,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: TeacherDashboardScreen.primary.withValues(alpha: 0.5)),
                  ),
                ),
              ),
              Container(
                width: 65, height: 65,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [TeacherDashboardScreen.primary, TeacherDashboardScreen.secondary]),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 30),
              ),
            ],
          );
        },
      ),
    );
  }
}