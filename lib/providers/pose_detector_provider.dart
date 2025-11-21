// lib/providers/pose_detector_provider.dart
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

  Pose? get latestPose => _latestPose;
  bool get isDetecting => _isDetecting;

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

      final poses = await _poseDetector!.processImage(inputImage);

      if (poses.isNotEmpty) {
        _latestPose = poses.first;
        onPoseDetected(poses.first);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error detecting pose: $e');
    } finally {
      _isDetecting = false;
    }
  }

  @override
  void dispose() {
    _poseDetector?.close();
    super.dispose();
  }
}