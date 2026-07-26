import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class TeacherScannerOverlay extends StatefulWidget {
  final String studentName;
  final String quizTitle;

  const TeacherScannerOverlay({
    super.key,
    required this.studentName,
    required this.quizTitle,
  });

  @override
  State<TeacherScannerOverlay> createState() => _TeacherScannerOverlayState();
}

class _TeacherScannerOverlayState extends State<TeacherScannerOverlay> with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;

  final List<File> _capturedPages = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Lifecycle observe karein
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        // High resolution use karte hain taake text (handwriting) clear aaye
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: false,
          imageFormatGroup: Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.jpeg,
        );

        await _cameraController!.initialize();

        if (!mounted) return;

        setState(() {
          _isCameraInitialized = true;
        });
      } else {
        _showError("No camera found on this device.");
      }
    } catch (e) {
      _showError("Failed to initialize camera: $e");
    }
  }

  // 🔥 App background mein jaye to camera release karo, wapas aaye to on karo
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      // Free up camera when app goes to background
      cameraController.dispose();
      if (mounted) setState(() => _isCameraInitialized = false);
    } else if (state == AppLifecycleState.resumed) {
      // Re-initialize when app comes back
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isCapturing) return;

    setState(() => _isCapturing = true);

    try {
      // Prevent focus issues by locking it before capture (optional but good for text)
      await _cameraController!.setFocusMode(FocusMode.locked);

      final XFile image = await _cameraController!.takePicture();

      await _cameraController!.setFocusMode(FocusMode.auto); // Unlock

      if (mounted) {
        setState(() {
          _capturedPages.add(File(image.path));
          _isCapturing = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isCapturing = false);
      _showError("Error capturing image. Try again.");
    }
  }

  void _finishScanning() {
    if (_capturedPages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Capture at least one page to evaluate."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    // Return the captured files back to the previous screen
    Navigator.pop(context, _capturedPages);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _cameraController == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF4F46E5)),
              SizedBox(height: 16),
              Text("Starting Camera...", style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. FULL SCREEN CAMERA PREVIEW
          Positioned.fill(
            child: CameraPreview(_cameraController!),
          ),

          // 2. SCANNING FRAME OVERLAY (Darkened edges)
          Positioned.fill(
            child: Container(
              decoration: ShapeDecoration(
                shape: _ScannerOverlayShape(borderColor: const Color(0xFF4F46E5), borderWidth: 3.0),
              ),
            ),
          ),

          // 3. TOP INFO BAR
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
              color: Colors.black.withValues(alpha: 0.6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const Text("Scanning Mode", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        Text("${widget.studentName} - ${widget.quizTitle}",
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFF4F46E5), borderRadius: BorderRadius.circular(12)),
                    child: Text("${_capturedPages.length} Pages", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
          ),

          // 4. BOTTOM CONTROLS & THUMBNAILS
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.only(bottom: 40, top: 20),
              color: Colors.black.withValues(alpha: 0.7),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Thumbnails Row
                  if (_capturedPages.isNotEmpty)
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _capturedPages.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(right: 15),
                                width: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFF4F46E5), width: 2),
                                  image: DecorationImage(image: FileImage(_capturedPages[index]), fit: BoxFit.cover),
                                ),
                              ),
                              // Chota sa remove icon thumbnail par
                              Positioned(
                                top: -5,
                                right: 5,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _capturedPages.removeAt(index);
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                                  ),
                                ),
                              )
                            ],
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Capture & Done Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(width: 60), // Spacer to center the capture button

                      // Capture Button
                      GestureDetector(
                        onTap: _isCapturing ? null : _capturePhoto,
                        child: Container(
                          width: 70, height: 70,
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _isCapturing ? Colors.grey : Colors.white, width: 4)),
                          child: Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(shape: BoxShape.circle, color: _isCapturing ? Colors.grey : Colors.white),
                            child: _isCapturing ? const CircularProgressIndicator(color: Color(0xFF4F46E5)) : null,
                          ),
                        ),
                      ),

                      // Finish Button
                      SizedBox(
                        width: 60,
                        child: _capturedPages.isNotEmpty
                            ? IconButton(
                          onPressed: _isCapturing ? null : _finishScanning,
                          icon: const Icon(Icons.check_circle, color: Colors.green, size: 45),
                        )
                            : null,
                      )
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

// Custom Painter for the clear cutout in the middle of a dark overlay
class _ScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;

  const _ScannerOverlayShape({required this.borderColor, required this.borderWidth});

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(borderWidth);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path();

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..addRect(rect)
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: rect.center, width: rect.width * 0.85, height: rect.height * 0.65),
          const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final cutoutRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: rect.center, width: rect.width * 0.85, height: rect.height * 0.65),
        const Radius.circular(16));

    canvas.drawPath(getOuterPath(rect), paint);
    canvas.drawRRect(cutoutRect, borderPaint);
  }

  @override
  ShapeBorder scale(double t) => this;
}