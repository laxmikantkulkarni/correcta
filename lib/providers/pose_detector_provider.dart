// lib/providers/pose_detector_provider.dart (WITH THROTTLED DEBUG)
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

class PoseDetectorProvider extends ChangeNotifier {
  PoseDetector? _poseDetector;
  bool _isDetecting = false;
  Pose? _latestPose;
  DateTime? _lastDebugPrint;
  late List<Pose> _poses;

  Pose? get latestPose => _latestPose;
  bool get isDetecting => _isDetecting;
  List<Pose> get poses => _poses;


  Future<void> initialize() async {
    final options = PoseDetectorOptions(
      model: PoseDetectionModel.base,
      mode: PoseDetectionMode.stream,
    );
    _poseDetector = PoseDetector(options: options);
  }

  Future<void> detectPose(
      CameraImage image,
      Size imageSize,
      InputImageRotation rotation,
      Function(Pose) onPoseDetected,
      ) async {
    if (_poseDetector == null || _isDetecting) return;

    _isDetecting = true;

    try {
      // Convert CameraImage to bytes
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      // Choose format based on platform
      final InputImageFormat inputImageFormat = Platform.isAndroid
          ? InputImageFormat.nv21
          : InputImageFormat.bgra8888;

      final inputImageData = InputImageMetadata(
        size: imageSize,
        rotation: rotation,
        format: inputImageFormat,
        bytesPerRow:
        image.planes.isNotEmpty ? image.planes[0].bytesPerRow : image.width,
      );

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: inputImageData,
      );

      _poses = await _poseDetector!.processImage(inputImage);

      if (_poses.isNotEmpty) {
        _latestPose = _poses.first;
        _printPoseLandmarks(_poses.first);
        onPoseDetected(_poses.first);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error detecting pose: $e');
    } finally {
      _isDetecting = false;
    }
  }

  void _printPoseLandmarks(Pose pose) {
    // Throttle to print every 2 seconds instead of 60 times per second
    final now = DateTime.now();
    if (_lastDebugPrint != null &&
        now.difference(_lastDebugPrint!) < Duration(seconds: 2)) {
      return;
    }
    _lastDebugPrint = now;

    debugPrint('');
    debugPrint('🧍 POSE LANDMARKS (Key Body Points):');
    debugPrint('─────────────────────────────────────');

    // Head
    final nose = pose.landmarks[PoseLandmarkType.nose];
    if (nose != null) {
      debugPrint('👃 Nose: (${nose.x.toStringAsFixed(1)}, ${nose.y.toStringAsFixed(1)})');
    }

    final leftEye = pose.landmarks[PoseLandmarkType.leftEye];
    final rightEye = pose.landmarks[PoseLandmarkType.rightEye];
    if (leftEye != null && rightEye != null) {
      debugPrint('👁️  Left Eye: (${leftEye.x.toStringAsFixed(1)}, ${leftEye.y.toStringAsFixed(1)})');
      debugPrint('👁️  Right Eye: (${rightEye.x.toStringAsFixed(1)}, ${rightEye.y.toStringAsFixed(1)})');
    }

    // Shoulders
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    if (leftShoulder != null && rightShoulder != null) {
      debugPrint('💪 Left Shoulder: (${leftShoulder.x.toStringAsFixed(1)}, ${leftShoulder.y.toStringAsFixed(1)})');
      debugPrint('💪 Right Shoulder: (${rightShoulder.x.toStringAsFixed(1)}, ${rightShoulder.y.toStringAsFixed(1)})');
    }

    // Elbows
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    if (leftElbow != null && rightElbow != null) {
      debugPrint('🦾 Left Elbow: (${leftElbow.x.toStringAsFixed(1)}, ${leftElbow.y.toStringAsFixed(1)})');
      debugPrint('🦾 Right Elbow: (${rightElbow.x.toStringAsFixed(1)}, ${rightElbow.y.toStringAsFixed(1)})');
    }

    // Wrists
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    if (leftWrist != null && rightWrist != null) {
      debugPrint('✋ Left Wrist: (${leftWrist.x.toStringAsFixed(1)}, ${leftWrist.y.toStringAsFixed(1)})');
      debugPrint('✋ Right Wrist: (${rightWrist.x.toStringAsFixed(1)}, ${rightWrist.y.toStringAsFixed(1)})');
    }

    // Hips
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    if (leftHip != null && rightHip != null) {
      debugPrint('🦴 Left Hip: (${leftHip.x.toStringAsFixed(1)}, ${leftHip.y.toStringAsFixed(1)})');
      debugPrint('🦴 Right Hip: (${rightHip.x.toStringAsFixed(1)}, ${rightHip.y.toStringAsFixed(1)})');
    }

    // Knees
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    if (leftKnee != null && rightKnee != null) {
      debugPrint('🦵 Left Knee: (${leftKnee.x.toStringAsFixed(1)}, ${leftKnee.y.toStringAsFixed(1)})');
      debugPrint('🦵 Right Knee: (${rightKnee.x.toStringAsFixed(1)}, ${rightKnee.y.toStringAsFixed(1)})');
    }

    // Ankles
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];
    if (leftAnkle != null && rightAnkle != null) {
      debugPrint('🦶 Left Ankle: (${leftAnkle.x.toStringAsFixed(1)}, ${leftAnkle.y.toStringAsFixed(1)})');
      debugPrint('🦶 Right Ankle: (${rightAnkle.x.toStringAsFixed(1)}, ${rightAnkle.y.toStringAsFixed(1)})');
    }

    // Feet
    final leftHeel = pose.landmarks[PoseLandmarkType.leftHeel];
    final rightHeel = pose.landmarks[PoseLandmarkType.rightHeel];
    if (leftHeel != null && rightHeel != null) {
      debugPrint('👠 Left Heel: (${leftHeel.x.toStringAsFixed(1)}, ${leftHeel.y.toStringAsFixed(1)})');
      debugPrint('👠 Right Heel: (${rightHeel.x.toStringAsFixed(1)}, ${rightHeel.y.toStringAsFixed(1)})');
    }

    debugPrint('─────────────────────────────────────');
  }

  @override
  void dispose() {
    _poseDetector?.close();
    super.dispose();
  }
}