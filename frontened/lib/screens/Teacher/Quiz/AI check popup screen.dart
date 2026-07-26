import 'package:flutter/material.dart';
import 'package:frontened/main.dart' show AppColors;


class TeacherQuizUploadProcessingScreen extends StatefulWidget {
  static const String quizUploadProcessing = '/quiz-upload-processing';

  const TeacherQuizUploadProcessingScreen({super.key});

  @override
  State<TeacherQuizUploadProcessingScreen> createState() =>
      _TeacherQuizUploadProcessingScreenState();
}

class _TeacherQuizUploadProcessingScreenState
    extends State<TeacherQuizUploadProcessingScreen> {

  double progress = 0;
  bool completed = false;

  @override
  void initState() {
    super.initState();
    _startProcessing();
  }

  void _startProcessing() async {
    for (int i = 1; i <= 100; i++) {
      await Future.delayed(const Duration(milliseconds: 25));
      setState(() {
        progress = i / 100;
      });
    }

    setState(() {
      completed = true;
    });

    /// Auto close after success
    await Future.delayed(const Duration(seconds: 2));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.35),

      body: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: completed ? _successPopup() : _loadingPopup(),
        ),
      ),
    );
  }

  /// ================= LOADING =================
  Widget _loadingPopup() {
    return Container(
      key: const ValueKey("loading"),
      width: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x20000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          /// AI ICON
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 28,
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            "Checking Quiz...",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 14),

          /// PROGRESS BAR
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor:
              AppColors.primary.withValues(alpha: 0.15),
              valueColor:
              const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),

          const SizedBox(height: 10),

          Text(
            "${(progress * 100).toInt()}%",
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// ================= SUCCESS =================
  Widget _successPopup() {
    return Container(
      key: const ValueKey("success"),
      width: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x20000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          /// SUCCESS ICON
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green, // 🔥 Yahan error tha, isay fix kar diya hai
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 28,
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            "Quiz Checked Successfully",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            "Results have been generated",
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}