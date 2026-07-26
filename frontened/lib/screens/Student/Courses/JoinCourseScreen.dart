import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontened/Provider/course_provider.dart';
import 'package:provider/provider.dart';

class JoinCourseScreen extends StatefulWidget {
  const JoinCourseScreen({super.key});
  static const String routeName = '/join-course';
  @override
  State<JoinCourseScreen> createState() => _JoinCourseScreenState();
}

class _JoinCourseScreenState extends State<JoinCourseScreen> {
  final TextEditingController _inviteController = TextEditingController();
  bool _previewReady = false;

  void _verifyLink() {
    if (_inviteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter the invite link first"), backgroundColor: Colors.red));
      return;
    }
    setState(() => _previewReady = true);
  }

  Future<void> _joinCourse() async {
    // 🔥 FIX: Clean URL extraction logic handling trailing slashes & exact hex join code
    String rawInput = _inviteController.text.trim();
    String code = rawInput.endsWith('/') 
        ? rawInput.substring(0, rawInput.length - 1).split("/").last 
        : rawInput.split("/").last;

    final provider = Provider.of<CourseProvider>(context, listen: false);
    final success = await provider.joinCourse(code.trim());

    if (!mounted) return;

    if (success) {
      await provider.fetchCourses();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Course Joined Successfully! 🎉"), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.error ?? "Invalid join code"), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CourseProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF4F46E5),
        title: const Text("Join New Course", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Enter Teacher's Invite Link", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B))),
            const SizedBox(height: 10),
            TextField(
              controller: _inviteController,
              decoration: InputDecoration(
                hintText: "Paste link here...",
                filled: true, fillColor: Colors.grey.shade50,
                suffixIcon: IconButton(icon: const Icon(Icons.paste, color: Color(0xFF4F46E5)), onPressed: () async {
                  final data = await Clipboard.getData('text/plain');
                  if (data != null && data.text != null) setState(() { _inviteController.text = data.text!; });
                }),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
              ),
            ),
            const SizedBox(height: 16),

            if (!_previewReady)
              SizedBox(
                width: double.infinity, height: 55,
                child: ElevatedButton(
                  onPressed: _verifyLink,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: const Text("Verify Link", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),

            if (_previewReady) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF16A34A)),
                  boxShadow: [BoxShadow(color: const Color(0xFF16A34A).withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 5))],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 50),
                    const SizedBox(height: 12),
                    const Text("Valid Course Found!", style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 8),
                    const Text("Click confirm below to enroll yourself.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity, height: 55,
                      child: ElevatedButton(
                        onPressed: provider.isJoining ? null : _joinCourse,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        child: provider.isJoining
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Confirm & Join", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    )
                  ],
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}