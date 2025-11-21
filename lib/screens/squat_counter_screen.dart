// lib/screens/squat_counter_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import '../providers/camera_provider.dart';
import '../providers/pose_detector_provider.dart';
import '../providers/squat_counter_provider.dart';
import '../providers/tts_provider.dart';
import '../widgets/camera_preview_widget.dart';
import '../widgets/squat_ui_overlay.dart';

class SquatCounterScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const SquatCounterScreen({required this.cameras});

  @override
  _SquatCounterScreenState createState() => _SquatCounterScreenState();
}

class _SquatCounterScreenState extends State<SquatCounterScreen> {
  @override
  void initState() {
    super.initState();
    _initializeProviders();
  }

  Future<void> _initializeProviders() async {
    final cameraProvider = context.read<CameraProvider>();
    final poseProvider = context.read<PoseDetectorProvider>();
    final squatProvider = context.read<SquatCounterProvider>();
    final ttsProvider = context.read<TtsProvider>();

    // Initialize TTS
    await ttsProvider.initialize();

    // Initialize Pose Detector
    await poseProvider.initialize();

    // Initialize Camera with image stream callback
    await cameraProvider.initialize(
      widget.cameras,
          (image) async {
        final imageSize = Size(
          image.width.toDouble(),
          image.height.toDouble(),
        );
        final rotation = cameraProvider.getImageRotation();

        // Update camera metadata
        cameraProvider.updateImageMetadata(imageSize, rotation);

        // Detect pose
        await poseProvider.detectPose(
          image,
          imageSize,
          rotation,
              (pose) {
            // Process pose for squat counting
            squatProvider.processPose(pose, (text) {
              ttsProvider.speak(text);
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Squat Counter'),
        centerTitle: true,
        elevation: 2,
        actions: [
          Consumer<TtsProvider>(
            builder: (context, ttsProvider, child) {
              return IconButton(
                icon: Icon(ttsProvider.isEnabled
                    ? Icons.volume_up
                    : Icons.volume_off),
                onPressed: () => ttsProvider.toggleEnabled(),
                tooltip: 'Toggle Voice Feedback',
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera Preview
          CameraPreviewWidget(),

          // UI Overlay
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: SquatUiOverlay(),
          ),

          // Reset Button
          Positioned(
            bottom: 30,
            right: 20,
            child: Consumer2<SquatCounterProvider, TtsProvider>(
              builder: (context, squatProvider, ttsProvider, child) {
                return FloatingActionButton(
                  onPressed: () {
                    squatProvider.reset((text) {
                      ttsProvider.speak(text);
                    });
                  },
                  backgroundColor: Colors.red,
                  child: Icon(Icons.refresh, color: Colors.white),
                  tooltip: 'Reset Counter',
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}