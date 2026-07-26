import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:frontened/Provider/course_provider.dart';
import 'package:frontened/Provider/quiz_provider.dart';
import 'package:frontened/models/Quiz/quiz_model.dart';
import 'package:provider/provider.dart';

class StudentsScreen extends StatefulWidget {
  static const String students = '/students';

  final String courseId;
  final List<Quiz> quiz;

  const StudentsScreen({
    super.key,
    required this.courseId,
    required this.quiz,
  });

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  String _search = "";

  final TextEditingController _titleController =
  TextEditingController();

  // =========================================
  // CAMERA
  // =========================================
  CameraController? _cameraController;

  List<CameraDescription> _cameras = [];

  bool _isCameraInitialized = false;

  bool _isCapturing = false;

  // =========================================
  // SCANNED PAGES
  // =========================================
  final List<File> _scannedPages = [];

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      final courseProvider =
      Provider.of<CourseProvider>(context, listen: false);

      await courseProvider.fetchCourseStudents(widget.courseId);

      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();

    _cameraController?.dispose();

    super.dispose();
  }

  // =========================================
  // INITIALIZE CAMERA
  // =========================================
  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();

    if (_cameras.isEmpty) {
      throw Exception("No camera found");
    }

    _cameraController = CameraController(
      _cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _cameraController!.initialize();

    if (!mounted) return;

    setState(() {
      _isCameraInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final courseProvider =
    Provider.of<CourseProvider>(
      context,
    );

    final quizProvider =
    Provider.of<QuizProvider>(
      context,
    );

    final students =
    courseProvider.courseStudents
        .where((student) {
      final name =
      (student["name"] ?? "")
          .toString()
          .toLowerCase();

      final email =
      (student["email"] ?? "")
          .toString()
          .toLowerCase();

      return name.contains(
        _search.toLowerCase(),
      ) ||
          email.contains(
            _search.toLowerCase(),
          );
    }).toList();

    return Scaffold(
      backgroundColor:
      const Color(0xFFF4F7FF),

      body: SafeArea(
        child: Column(
          children: [

            // =========================================
            // HEADER
            // =========================================
            Container(
              margin:
              const EdgeInsets.all(18),

              padding:
              const EdgeInsets.all(20),

              decoration: BoxDecoration(
                borderRadius:
                BorderRadius.circular(
                    26),

                gradient:
                const LinearGradient(
                  colors: [
                    Color(0xFF6D5DF6),
                    Color(0xFF8E7BFF),
                  ],
                ),
              ),

              child: Row(
                children: [

                  GestureDetector(
                    onTap: () =>
                        Navigator.pop(
                            context),

                    child: Container(
                      padding:
                      const EdgeInsets
                          .all(10),

                      decoration:
                      BoxDecoration(
                        color: Colors.white
                            .withValues(alpha: .2),

                        borderRadius:
                        BorderRadius
                            .circular(
                            14),
                      ),

                      child: const Icon(
                        Icons
                            .arrow_back_ios_new,
                        color:
                        Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                      children: [

                        Text(
                          "AI Quiz Scanner",
                          style:
                          TextStyle(
                            color:
                            Colors.white,
                            fontSize: 24,
                            fontWeight:
                            FontWeight
                                .w800,
                          ),
                        ),

                        SizedBox(height: 4),

                        Text(
                          "Real Answer Sheet Scanner",
                          style:
                          TextStyle(
                            color:
                            Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),

                    decoration:
                    BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                      BorderRadius
                          .circular(
                          18),
                    ),

                    child: Column(
                      children: [

                        Text(
                          "${students.length}",
                          style:
                          const TextStyle(
                            fontSize: 18,
                            fontWeight:
                            FontWeight
                                .bold,
                            color: Color(
                                0xFF6D5DF6),
                          ),
                        ),

                        const Text(
                          "Students",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // =========================================
            // SEARCH
            // =========================================
            Padding(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 18,
              ),

              child: Container(
                decoration:
                BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.circular(
                      18),
                ),

                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _search = value;
                    });
                  },

                  decoration:
                  const InputDecoration(
                    prefixIcon:
                    Icon(Icons.search),

                    hintText:
                    "Search student...",

                    border:
                    InputBorder.none,

                    contentPadding:
                    EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // =========================================
            // BODY
            // =========================================
            Expanded(
              child: courseProvider
                  .isStudentsLoading
                  ? const Center(
                child:
                CircularProgressIndicator(),
              )

                  : ListView.builder(
                padding:
                const EdgeInsets
                    .symmetric(
                  horizontal: 18,
                ),

                itemCount:
                students.length,

                itemBuilder:
                    (context, index) {
                  final student =
                  students[index];

                  final name =
                      student["name"] ??
                          "Student";

                  final email =
                      student["email"] ??
                          "";

                  final image =
                  student[
                  "profileImage"];

                  final studentId =
                      student["_id"] ??
                          "";

                  return Container(
                    margin:
                    const EdgeInsets
                        .only(
                      bottom: 18,
                    ),

                    padding:
                    const EdgeInsets
                        .all(18),

                    decoration:
                    BoxDecoration(
                      color:
                      Colors.white,

                      borderRadius:
                      BorderRadius
                          .circular(
                          24),
                    ),

                    child: Column(
                      children: [

                        // =========================================
                        // PROFILE
                        // =========================================
                        Row(
                          children: [

                            CircleAvatar(
                              radius: 32,

                              backgroundImage: image !=
                                  null &&
                                  image
                                      .toString()
                                      .isNotEmpty
                                  ? NetworkImage(
                                image,
                              )
                                  : null,

                              child: (image == null &&
                                  (image == null ||
                                      image!.isEmpty))
                                  ? Text(
                                name[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                                  : null,
                            ),

                            const SizedBox(
                                width:
                                16),

                            Expanded(
                              child:
                              Column(
                                crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                                children: [

                                  Text(
                                    name,

                                    style:
                                    const TextStyle(
                                      fontSize:
                                      18,

                                      fontWeight:
                                      FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(
                                      height:
                                      4),

                                  Text(
                                    email,

                                    style:
                                    const TextStyle(
                                      color:
                                      Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                            height: 18),

                        // =========================================
                        // SCAN BUTTON
                        // =========================================
                        SizedBox(
                          width:
                          double.infinity,

                          height: 55,

                          child:
                          ElevatedButton.icon(
                            icon: quizProvider
                                .isScanningAI
                                ? const SizedBox(
                              width:
                              20,
                              height:
                              20,
                              child:
                              CircularProgressIndicator(
                                color:
                                Colors.white,
                                strokeWidth:
                                2,
                              ),
                            )
                                : const Icon(
                              Icons
                                  .document_scanner_outlined,
                            ),

                            label: Text(
                              quizProvider
                                  .isScanningAI
                                  ? "AI Scanning..."
                                  : "Start Scanner",
                            ),

                            style:
                            ElevatedButton
                                .styleFrom(
                              backgroundColor:
                              const Color(
                                  0xFF6D5DF6),

                              foregroundColor:
                              Colors.white,

                              shape:
                              RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(
                                    16),
                              ),
                            ),

                            onPressed:
                            quizProvider
                                .isScanningAI
                                ? null
                                : () =>
                                _showQuizTitleDialog(
                                  context:
                                  context,
                                  studentId:
                                  studentId,
                                  studentName:
                                  name,
                                ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================
  // QUIZ TITLE
  // =========================================
  Future<void> _showQuizTitleDialog({
    required BuildContext context,
    required String studentId,
    required String studentName,
  }) async {
    _titleController.clear();

    showDialog(
      context: context,

      builder: (_) {
        return Dialog(
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
                24),
          ),

          child: Padding(
            padding:
            const EdgeInsets.all(
                24),

            child: Column(
              mainAxisSize:
              MainAxisSize.min,

              children: [

                const Icon(
                  Icons.quiz,
                  size: 60,
                  color:
                  Color(0xFF6D5DF6),
                ),

                const SizedBox(height: 18),

                const Text(
                  "Quiz Title",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 18),

                TextField(
                  controller:
                  _titleController,

                  decoration:
                  InputDecoration(
                    hintText:
                    "Mid Term Quiz",

                    filled: true,

                    fillColor:
                    const Color(
                        0xFFF4F7FF),

                    border:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius
                          .circular(
                          16),

                      borderSide:
                      BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width:
                  double.infinity,

                  height: 52,

                  child:
                  ElevatedButton(
                    onPressed: () async {
                      final title =
                      _titleController
                          .text
                          .trim();

                      if (title
                          .isEmpty) {
                        return;
                      }

                      Navigator.pop(
                          context);

                      await _openScanner(
                        studentId:
                        studentId,

                        studentName:
                        studentName,

                        title: title,
                      );
                    },

                    style:
                    ElevatedButton
                        .styleFrom(
                      backgroundColor:
                      const Color(
                          0xFF6D5DF6),

                      foregroundColor:
                      Colors.white,
                    ),

                    child:
                    const Text(
                      "Start Scanning",
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openScanner({
    required String studentId,
    required String studentName,
    required String title,
  }) async {
    _scannedPages.clear();

    if (_cameraController == null ||
        !_cameraController!.value.isInitialized) {
      await _initializeCamera();
    }

    if (!mounted) return;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "Scanner",
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (context, _, _) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              backgroundColor: Colors.black,

              // =========================================
              // FULL SCREEN STACK UI
              // =========================================
              body: Stack(
                children: [

                  // =========================================
                  // CAMERA FULL SCREEN (FIXED)
                  // =========================================
                  Positioned.fill(
                    child: (_cameraController != null &&
                        _cameraController!.value.isInitialized)
                        ? FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _cameraController!
                            .value.previewSize!.height,
                        height: _cameraController!
                            .value.previewSize!.width,
                        child:
                        CameraPreview(_cameraController!),
                      ),
                    )
                        : const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),

                  // =========================================
                  // TOP BAR
                  // =========================================
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        color: Colors.black.withValues(alpha: 0.6),
                        child: Row(
                          children: [

                            // CLOSE
                            IconButton(
                              onPressed: () async {
                                await _cameraController?.stopImageStream();
                                Navigator.of(context,
                                    rootNavigator: true)
                                    .pop();
                              },
                              icon: const Icon(Icons.close,
                                  color: Colors.white),
                            ),

                            const Expanded(
                              child: Text(
                                "AI Scanner",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            // PAGE COUNT
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6D5DF6),
                                borderRadius:
                                BorderRadius.circular(12),
                              ),
                              child: Text(
                                "${_scannedPages.length}",
                                style: const TextStyle(
                                    color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // =========================================
                  // THUMBNAILS
                  // =========================================
                  if (_scannedPages.isNotEmpty)
                    Positioned(
                      bottom: 120,
                      left: 0,
                      right: 0,
                      child: SizedBox(
                        height: 90,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _scannedPages.length,
                          itemBuilder: (context, index) {
                            final file = _scannedPages[index];

                            return Container(
                              margin: const EdgeInsets.all(6),
                              width: 70,
                              decoration: BoxDecoration(
                                borderRadius:
                                BorderRadius.circular(10),
                                image: DecorationImage(
                                  image: FileImage(file),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                  // =========================================
                  // CAPTURE BUTTON
                  // =========================================
                  Positioned(
                    bottom: 25,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: _isCapturing
                            ? null
                            : () async {
                          try {
                            setState(() => _isCapturing = true);

                            final XFile image =
                            await _cameraController!
                                .takePicture();

                            _scannedPages.add(File(image.path));

                            setState(() => _isCapturing = false);
                          } catch (_) {
                            setState(() => _isCapturing = false);
                          }
                        },
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white, width: 4),
                          ),
                          child: const CircleAvatar(
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // =========================================
                  // DONE BUTTON
                  // =========================================
                  Positioned(
                    bottom: 35,
                    right: 20,
                    child: ElevatedButton(
                      onPressed: _scannedPages.isEmpty
                          ? null
                          : () async {
                        Navigator.of(context,
                            rootNavigator: true)
                            .pop();

                        await _sendToAI(
                          studentId: studentId,
                          studentName: studentName,
                          title: title,
                          files: _scannedPages,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        const Color(0xFF6D5DF6),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("DONE"),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // =========================================
  // SEND ALL PAGES TO AI
  // =========================================
  Future<void> _sendToAI({
    required String studentId,
    required String studentName,
    required String title,
    required List<File> files,
  }) async {

    try {

      final quizProvider =
      Provider.of<QuizProvider>(
        context,
        listen: false,
      );

      // =========================================
      // LOADING
      // =========================================
      showDialog(
        context: context,

        barrierDismissible: false,

        builder: (_) {
          return Dialog(
            shape:
            RoundedRectangleBorder(
              borderRadius:
              BorderRadius
                  .circular(24),
            ),

            child: const Padding(
              padding:
              EdgeInsets.all(24),

              child: Column(
                mainAxisSize:
                MainAxisSize.min,

                children: [

                  CircularProgressIndicator(),

                  SizedBox(height: 20),

                  Text(
                    "AI is scanning answer sheets...",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 8),

                  Text(
                    "Please wait...",
                  ),
                ],
              ),
            ),
          );
        },
      );

      // =========================================
      // API CALL
      // =========================================
      final response =
      await quizProvider
          .scanAIQuizMarks(
        courseId:
        widget.courseId,

        studentId:
        studentId,

        title: title,

        files: files,
      );

      // =========================================
      // CLOSE LOADING
      // =========================================
      if (mounted &&
          Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (response == null) {
        throw Exception(
            "AI scan failed");
      }

      final evaluation =
      response["evaluation"];

      final score =
          evaluation["score"] ?? 0;

      final total =
          evaluation["totalMarks"] ?? 0;

      final percentage =
          evaluation["percentage"] ?? "0";

      // =========================================
      // RESULT
      // =========================================
      showDialog(
        context: context,

        builder: (_) {
          return Dialog(
            shape:
            RoundedRectangleBorder(
              borderRadius:
              BorderRadius
                  .circular(28),
            ),

            child: Container(
              padding:
              const EdgeInsets
                  .all(24),

              child: Column(
                mainAxisSize:
                MainAxisSize.min,

                children: [

                  const CircleAvatar(
                    radius: 45,

                    backgroundColor:
                    Color(
                        0x116D5DF6),

                    child: Icon(
                      Icons.auto_awesome,

                      size: 40,

                      color: Color(
                          0xFF6D5DF6),
                    ),
                  ),

                  const SizedBox(
                      height: 20),

                  const Text(
                    "AI Evaluation Result",

                    style: TextStyle(
                      fontSize: 24,

                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                      height: 10),

                  Text(
                    studentName,

                    style:
                    const TextStyle(
                      color:
                      Colors.grey,
                    ),
                  ),

                  const SizedBox(
                      height: 6),

                  Text(
                    title,

                    style:
                    const TextStyle(
                      color: Color(
                          0xFF6D5DF6),

                      fontSize: 18,

                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                      height: 24),

                  Container(
                    width:
                    double.infinity,

                    padding:
                    const EdgeInsets
                        .all(20),

                    decoration:
                    BoxDecoration(
                      color: const Color(
                          0xFFF4F7FF),

                      borderRadius:
                      BorderRadius
                          .circular(
                          20),
                    ),

                    child: Column(
                      children: [

                        Text(
                          "$score/$total",

                          style:
                          const TextStyle(
                            fontSize:
                            40,

                            fontWeight:
                            FontWeight
                                .w900,

                            color: Color(
                                0xFF6D5DF6),
                          ),
                        ),

                        const SizedBox(
                            height: 8),

                        Text(
                          "$percentage%",

                          style:
                          const TextStyle(
                            fontSize:
                            20,

                            color:
                            Colors.green,

                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                      height: 24),

                  SizedBox(
                    width:
                    double.infinity,

                    height: 52,

                    child:
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(
                            context);
                      },

                      style:
                      ElevatedButton
                          .styleFrom(
                        backgroundColor:
                        const Color(
                            0xFF6D5DF6),

                        foregroundColor:
                        Colors.white,
                      ),

                      child:
                      const Text(
                        "DONE",
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

    } catch (e) {

      if (mounted &&
          Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          backgroundColor:
          Colors.red,

          content: Text(
            e.toString(),
          ),
        ),
      );
    }
  }
}