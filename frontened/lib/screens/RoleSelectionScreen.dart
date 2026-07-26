import 'package:flutter/material.dart';
import 'package:frontened/screens/Student/Authentication/StudentAuthScreen.dart'; // 🔥 Fixed Link
import 'package:frontened/screens/Teacher/TeacherAuthScreen.dart';
import 'package:frontened/services/storage_service.dart';
import 'package:frontened/utils/Auth_Widgets/AppLogo.dart';

import '../main.dart';

class RoleSelectionScreen extends StatefulWidget {
  static const String routeName = '/role-selection';

  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? selectedRole;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 35),
            const AppLogo(width: 160),
            const SizedBox(height: 20),
            const Text("Select Your Role", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0B0B47))),
            const SizedBox(height: 6),
            const Text("Choose how you want to continue", style: TextStyle(fontSize: 14, color: Colors.grey)),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(child: _roleCard(title: "Teacher", subtitle: "Create courses & quizzes", icon: Icons.menu_book_rounded, color: const Color(0xff2563EB), isSelected: selectedRole == "teacher", onTap: () => setState(() => selectedRole = "teacher"))),
                    const SizedBox(width: 14),
                    Expanded(child: _roleCard(title: "Student", subtitle: "Learn courses & attempt quizzes", icon: Icons.school_rounded, color: const Color(0xff16A34A), isSelected: selectedRole == "student", onTap: () => setState(() => selectedRole = "student"))),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
              child: SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedRole == null ? Colors.grey.shade300 : const Color(0xFF4F46E5),
                    elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: selectedRole == null || isLoading ? null : () async {
                    setState(() => isLoading = true);
                    await StorageService.saveRole(selectedRole!);
                    await Future.delayed(const Duration(milliseconds: 400));

                    if (!context.mounted) return;
                    setState(() => isLoading = false);

                    if (selectedRole == "student") {
                      Navigator.pushReplacementNamed(context, StudentAuthScreen.routeName);
                    } else if (selectedRole == "teacher") {
                      Navigator.pushReplacementNamed(context, TeacherAuthScreen.routeName);
                    }
                  },
                  child: isLoading ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text("Continue", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleCard({required String title, required String subtitle, required IconData icon, required Color color, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: isSelected ? color : Colors.grey.shade200, width: isSelected ? 2.5 : 1), boxShadow: [BoxShadow(color: isSelected ? color.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.03), blurRadius: 16, offset: const Offset(0, 8))]),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(height: 60, width: 60, decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: color, size: 30)),
                const SizedBox(height: 16),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87)),
                const SizedBox(height: 6),
                Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.grey, height: 1.3)),
              ],
            ),
            if (isSelected) Positioned(top: -14, right: -4, child: Icon(Icons.check_circle, color: color, size: 24)),
          ],
        ),
      ),
    );
  }
}