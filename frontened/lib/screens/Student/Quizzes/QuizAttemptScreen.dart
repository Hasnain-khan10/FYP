import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontened/Provider/quiz_provider.dart';
import 'package:frontened/models/Quiz/quiz_model.dart';
import 'package:provider/provider.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class QuizAttemptScreen extends StatefulWidget {
  const QuizAttemptScreen({super.key});
  static const String routeName = '/quiz-attempt';

  @override
  State<QuizAttemptScreen> createState() => _QuizAttemptScreenState();
}

class _QuizAttemptScreenState extends State<QuizAttemptScreen> with WidgetsBindingObserver {
  late Quiz quiz;
  int currentIndex = 0;
  Map<int, String> selectedAnswers = {};
  Set<int> lockedQuestions = {};

  bool isSubmitting = false;
  bool autoSubmitted = false;

  Timer? timer;
  int remainingSeconds = 0;

  int proctoringStrikes = 0;
  bool _isWarningOpen = false;

  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  Timer? _aiProctorTimer;
  bool _isProcessingFace = false;

  bool _rulesAccepted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showPreExamRulesDialog();
    });
  }

  void _showPreExamRulesDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          // 🔥 FIX: Added Expanded to prevent 20-pixel overflow
          title: Row(
            children: [
              const Icon(Icons.gavel, color: Colors.purple, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: const Text("EXAM RULES & PROCTORING", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple, fontSize: 16), maxLines: 2),
              ),
            ],
          ),
          content: const Text(
            "Welcome to the Secure Exam Environment.\n\n"
                "🔴 CRITICAL RULES:\n"
                "1. Do not minimize or switch the app.\n"
                "2. Do not look away, left, or right.\n"
                "3. Do not turn or rotate your head.\n"
                "4. Keep your face clearly in front of the camera.\n\n"
                "⚠️ You will be given exactly 2 warnings for ANY violation. On the 3rd violation, your exam will be AUTOMATICALLY TERMINATED.",
            style: TextStyle(fontWeight: FontWeight.w600, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => _rulesAccepted = true);
                _secureClassroomEnvironment(true);
                _initializeAIProctoring();
                startTimer();
              },
              child: const Text("I Understand & Accept", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _secureClassroomEnvironment(bool enable) async {
    try {
      if (enable) {
        if (Theme.of(context).platform == TargetPlatform.android) {
          await const MethodChannel('plugins.flutter.io/window_to_front').invokeMethod('setFlags', {'flags': 8192});
        }
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    } catch (e) {
      debugPrint("Native System Flag Execution: $e");
    }
  }

  Future<void> _initializeAIProctoring() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.front);

      _cameraController = CameraController(frontCamera, ResolutionPreset.low, enableAudio: false);
      await _cameraController!.initialize();

      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableTracking: true,
          enableClassification: true,
          enableContours: false,
          minFaceSize: 0.1,
        ),
      );

      if (mounted) setState(() {});

      _aiProctorTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
        _scanFaceBehaviors();
      });
    } catch (e) {
      debugPrint("Camera AI Initialization Error: $e");
    }
  }

  Future<void> _scanFaceBehaviors() async {
    if (_isProcessingFace || _cameraController == null || !_cameraController!.value.isInitialized) return;
    if (isSubmitting || autoSubmitted || !_rulesAccepted) return;

    _isProcessingFace = true;
    try {
      final XFile imageFile = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(imageFile.path);

      final List<Face> faces = await _faceDetector!.processImage(inputImage);

      File(imageFile.path).delete().catchError((_) {});

      if (!mounted || isSubmitting || autoSubmitted) return;

      if (faces.isEmpty) {
        _triggerCheatingStrike("Face not detected! Keep your face clearly in front of the camera.");
      } else if (faces.length > 1) {
        _triggerCheatingStrike("Multiple faces detected! No other person is allowed in the room.");
      } else {
        final face = faces.first;

        if (face.headEulerAngleY != null) {
          double rotationY = face.headEulerAngleY!;
          if (rotationY > 12 || rotationY < -12) {
            _triggerCheatingStrike("Head movement detected! Stop looking around and focus on the screen.");
            return;
          }
        }

        if (face.leftEyeOpenProbability != null && face.rightEyeOpenProbability != null) {
          if (face.leftEyeOpenProbability! < 0.1 || face.rightEyeOpenProbability! < 0.1) {
            _triggerCheatingStrike("Eyes appear to be closed or looking away down! Keep your eyes on the exam.");
            return;
          }
        }
      }
    } catch (e) {
      debugPrint("Face Track Execution: $e");
    } finally {
      _isProcessingFace = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (!isSubmitting && !autoSubmitted && _rulesAccepted) {
        _triggerCheatingStrike("Application ecosystem switch or screen minimization detected!");
      }
    }
  }

  void _triggerCheatingStrike(String reason) {
    if (isSubmitting || autoSubmitted || _isWarningOpen || !_rulesAccepted) return;

    Future.microtask(() {
      setState(() { proctoringStrikes++; });

      if (proctoringStrikes >= 3) {
        if (_isWarningOpen) {
          Navigator.pop(context);
          _isWarningOpen = false;
        }
        _autoSubmit("Security Lock: $reason (Proctoring Threshold Exceeded)");
      } else {
        _showStrictWarningDialog(reason, 3 - proctoringStrikes);
      }
    });
  }

  void _showStrictWarningDialog(String reason, int strikesLeft) {
    if (_isWarningOpen) return;
    _isWarningOpen = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          // 🔥 FIX: Added Expanded to prevent overflow
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: const Text("AI PROCTOR SECURITY", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 16), maxLines: 2),
              ),
            ],
          ),
          content: Text(
            "$reason\n\n⚠️ RULES BREACH: You have $strikesLeft warning(s) left. The 3rd violation triggers absolute exam termination.",
            style: const TextStyle(fontWeight: FontWeight.w600, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                _isWarningOpen = false;
                Navigator.pop(ctx);
              },
              child: const Text("Acknowledge & Resume", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    quiz = ModalRoute.of(context)!.settings.arguments as Quiz;
  }

  void startTimer() {
    remainingSeconds = quiz.questions.length * 60;
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (remainingSeconds <= 0) {
        t.cancel();
        _autoSubmit("Allocated Time Frame Expired");
      } else {
        setState(() => remainingSeconds--);
      }
    });
  }

  String formatTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  void select(String answer) {
    if (lockedQuestions.contains(currentIndex)) return;
    setState(() {
      selectedAnswers[currentIndex] = answer;
      lockedQuestions.add(currentIndex);
    });
  }

  void next() {
    if (currentIndex < quiz.questions.length - 1) {
      setState(() => currentIndex++);
    } else {
      submit();
    }
  }

  Future<void> _autoSubmit(String reason) async {
    if (autoSubmitted || isSubmitting) return;
    autoSubmitted = true;
    timer?.cancel();
    _aiProctorTimer?.cancel();

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("SYSTEM RESTRAINT: $reason"), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating)
    );
    await submit();
  }

  Future<void> submit() async {
    if (isSubmitting) return;
    setState(() => isSubmitting = true);
    timer?.cancel();
    _aiProctorTimer?.cancel();

    final provider = context.read<QuizProvider>();
    final answers = quiz.questions.asMap().entries.map((e) {
      return {"selectedAnswer": selectedAnswers[e.key] ?? ""};
    }).toList();

    final result = await provider.attemptQuiz(quiz.id, quizId: quiz.id, answers: answers);
    await _secureClassroomEnvironment(false);

    setState(() => isSubmitting = false);

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/quiz-result', arguments: result ?? quiz);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    timer?.cancel();
    _aiProctorTimer?.cancel();
    _cameraController?.dispose();
    _faceDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (quiz.questions.isEmpty) {
      return const Scaffold(body: Center(child: Text("Empty Quiz Elements Structure.")));
    }

    final q = quiz.questions[currentIndex];
    final selected = selectedAnswers[currentIndex];
    final progress = (currentIndex + 1) / quiz.questions.length;
    final optionEntries = q.options.entries.toList();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Back navigation strictly blocked during runtime evaluation context!"), backgroundColor: Colors.orange));
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 10),
            decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Question ${currentIndex + 1} of ${quiz.questions.length}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B))),
                    if (_cameraController != null && _cameraController!.value.isInitialized)
                      Container(
                        height: 40, width: 40,
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.green, width: 2)),
                        child: ClipOval(child: CameraPreview(_cameraController!)),
                      ),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)), child: Row(children: [const Icon(Icons.timer, color: Colors.red, size: 16), const SizedBox(width: 4), Text(formatTime(remainingSeconds), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))])),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: progress, minHeight: 6, backgroundColor: Colors.grey.shade200, color: const Color(0xFF4F46E5), borderRadius: BorderRadius.circular(10)),
              ],
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)), child: Text(q.question, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.4))),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: optionEntries.length,
                  itemBuilder: (c, i) {
                    final key = optionEntries[i].key;
                    final value = optionEntries[i].value;
                    final isSelected = selected == key;

                    return GestureDetector(
                      onTap: () => select(key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF4F46E5).withAlpha(13) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isSelected ? const Color(0xFF4F46E5) : Colors.grey.shade300, width: isSelected ? 2 : 1),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(radius: 16, backgroundColor: isSelected ? const Color(0xFF4F46E5) : Colors.grey.shade200, child: Text(key, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold))),
                            const SizedBox(width: 12),
                            Expanded(child: Text(value, style: TextStyle(fontSize: 16, color: isSelected ? const Color(0xFF4F46E5) : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal))),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              height: 55,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : next,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(currentIndex == quiz.questions.length - 1 ? "Submit Final Answers" : "Next Question", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}