import 'dart:async';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'widgets/animated_slide_fade.dart';

class PhotoScanGuidedScreen extends StatefulWidget {
  const PhotoScanGuidedScreen({Key? key}) : super(key: key);

  @override
  State<PhotoScanGuidedScreen> createState() => _PhotoScanGuidedScreenState();
}

class _PhotoScanGuidedScreenState extends State<PhotoScanGuidedScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _introController;

  CameraController? _cameraController;
  bool _isCameraReady = false;
  bool _isCapturing = false;

  int _photoCount = 0;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final camera = cameras.first;

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      setState(() => _isCameraReady = true);
    } catch (e) {
      print("Camera init error: $e");
    }
  }

  @override
  void dispose() {
    _introController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  // 🔹 Safe capture: prevents ImageReader overflow
  Future<void> _onCapturePressed() async {
    if (_isCapturing || !_cameraController!.value.isInitialized) return;

    setState(() => _isCapturing = true);

    try {
      await _cameraController!.takePicture();
      setState(() => _photoCount++);
    } catch (e) {
      print("Capture error: $e");
    } finally {
      await Future.delayed(const Duration(milliseconds: 350));
      setState(() => _isCapturing = false);
    }
  }

  void _onFinishPressed() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Captured $_photoCount photos — ready for next step.",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFCAF0F8);
    const pink = Color(0xFFF72585);
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    final topHeight = height * 0.22;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // 🔹 Top pattern
          AnimatedSlideFade(
            controller: _introController,
            beginOffset: const Offset(0, -0.4),
            startInterval: 0.0,
            endInterval: 0.4,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(50),
                bottomRight: Radius.circular(50),
              ),
              child: SizedBox(
                width: width,
                height: topHeight,
                child: Image.asset(
                  'assets/top_pattern.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 🔹 Top bar
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: width * 0.05, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AnimatedSlideFade(
                        controller: _introController,
                        beginOffset: const Offset(-0.4, 0),
                        startInterval: 0.1,
                        endInterval: 0.5,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.black87.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      AnimatedSlideFade(
                        controller: _introController,
                        beginOffset: const Offset(0.4, 0),
                        startInterval: 0.1,
                        endInterval: 0.5,
                        child: Row(
                          children: const [
                            Icon(Icons.sensors, color: Colors.white, size: 18),
                            SizedBox(width: 4),
                            Text(
                              "Photo Scan",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                // 🔹 Camera preview
                Expanded(
                  child: AnimatedSlideFade(
                    controller: _introController,
                    beginOffset: const Offset(0, 0.3),
                    startInterval: 0.2,
                    endInterval: 0.8,
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: width * 0.05),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1.2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: _isCameraReady
                            ? Stack(
                                children: [
                                  CameraPreview(_cameraController!),

                                  // 🔹 Floating Glass Counter
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.25),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(0.4),
                                            ),
                                            borderRadius: BorderRadius.circular(18),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.camera_alt_rounded,
                                                size: 16,
                                                color: Colors.white,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                "$_photoCount/40",
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : const Center(
                                child: CircularProgressIndicator(
                                  color: pink,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 🔹 Liquid-Glass Capture Button
                AnimatedSlideFade(
                  controller: _introController,
                  beginOffset: const Offset(0, 0.4),
                  startInterval: 0.4,
                  endInterval: 1.0,
                  child: GestureDetector(
                    onTap: _onCapturePressed,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(35),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(35),
                            color: Colors.white.withOpacity(0.35),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.55),
                              width: 1.3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 18,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: pink,
                            size: 42,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 🔹 Finish button
                AnimatedSlideFade(
                  controller: _introController,
                  beginOffset: const Offset(0, 0.4),
                  startInterval: 0.5,
                  endInterval: 1.0,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: width * 0.08),
                    child: GestureDetector(
                      onTap: _onFinishPressed,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.white.withOpacity(0.35),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.55),
                                width: 1.3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 15,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                "Finish & Continue",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: pink,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
