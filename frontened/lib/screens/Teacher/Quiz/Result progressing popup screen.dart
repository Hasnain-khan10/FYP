import 'dart:async';

import 'package:flutter/material.dart';

class TeacherResultProcessingScreen extends StatefulWidget {
  const TeacherResultProcessingScreen({super.key});

  @override
  State<TeacherResultProcessingScreen> createState() =>
      _TeacherResultProcessingScreenState();
}

class _TeacherResultProcessingScreenState
    extends State<TeacherResultProcessingScreen> {

  static const Color primary = Color(0xFF4F46E5);
  static const Color secondary = Color(0xFF7C3AED);

  double progress = 0.2;
  bool showSuccess = false;

  @override
  void initState() {
    super.initState();
    startProcessing();
  }

  void startProcessing() {
    Timer.periodic(const Duration(milliseconds: 600), (timer) {
      setState(() {
        progress += 0.2;
      });

      if (progress >= 1.0) {
        timer.cancel();

        // Simulate save marks
        saveQuizResult();

        Future.delayed(const Duration(milliseconds: 500), () {
          setState(() => showSuccess = true);
        });
      }
    });
  }

  void saveQuizResult() {
    final student =
        ModalRoute.of(context)!.settings.arguments as Map?;

    // 👉 YAHAN BACKEND/FIREBASE SAVE KARO
    // Example:
    // quizId = "quiz_1"
    // studentId = student['id']
    // marks = 45

    print("Saving result for: ${student?['name']}");
  }

  @override
  Widget build(BuildContext context) {

    final student =
        ModalRoute.of(context)!.settings.arguments as Map?;

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.6),
      body: Stack(
        children: [

          // ===== AUTO CHECKING POPUP =====
          if (!showSuccess)
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 30),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // Icon
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [primary, secondary],
                        ),
                      ),
                      child: const Icon(Icons.auto_awesome,
                          color: Colors.white, size: 30),
                    ),

                    const SizedBox(height: 14),

                    const Text(
                      "Auto-checking with AI in progress...",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16),
                    ),

                    const SizedBox(height: 14),

                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade200,
                        valueColor:
                            const AlwaysStoppedAnimation(primary),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Cancel Button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Text("Cancel"),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),

          // ===== SUCCESS POPUP =====
          if (showSuccess)
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 30),
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // Success Icon
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.green,
                      child: Icon(Icons.check,
                          color: Colors.white, size: 30),
                    ),

                    const SizedBox(height: 14),

                    const Text(
                      "Quiz result uploaded",
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 14),

                    GestureDetector(
                      onTap: () {
                        Navigator.popUntil(
                            context, (route) => route.isFirst);
                      },
                      child: Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Text("Close"),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}