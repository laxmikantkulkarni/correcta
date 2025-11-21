// lib/providers/camera_provider.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

class CameraProvider extends ChangeNotifier {
  CameraController? _cameraController;
  CameraDescription? _cameraDescription;
  bool _isInitialized = false;
  bool _isFrontCamera = false;
  Size? _imageSize;
  InputImageRotation? _imageRotation;
  Size? _previewSize;

  CameraController? get cameraController => _cameraController;
  bool get isInitialized => _isInitialized;
  bool get isFrontCamera => _isFrontCamera;
  Size? get imageSize => _imageSize;
  InputImageRotation? get imageRotation => _imageRotation;
  Size? get previewSize => _previewSize;

  void setPreviewSize(Size size) {
    _previewSize = size;
    notifyListeners();
  }

  Future<void> initialize(
      List<CameraDescription> cameras,
      Function(CameraImage) onImageAvailable,
      ) async {
    if (cameras.isEmpty) {
      debugPrint('No cameras available');
      return;
    }

    _cameraDescription = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    _isFrontCamera =
        _cameraDescription!.lensDirection == CameraLensDirection.front;

    _cameraController = CameraController(
      _cameraDescription!,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    try {
      await _cameraController!.initialize();

      // Lock orientation to portrait
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);

      // Start image stream
      await _cameraController!.startImageStream(onImageAvailable);

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  InputImageRotation getImageRotation() {
    if (_cameraDescription == null) {
      return InputImageRotation.rotation0deg;
    }

    final int sensorOrientation = _cameraDescription!.sensorOrientation;
    int rotationDegrees;

    if (Platform.isAndroid) {
      if (_isFrontCamera) {
        rotationDegrees = (360 - sensorOrientation) % 360;
      } else {
        rotationDegrees = sensorOrientation % 360;
      }
    } else {
      rotationDegrees = 90; // iOS always delivers images as portraitUp
    }

    switch (rotationDegrees) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  void updateImageMetadata(Size imageSize, InputImageRotation rotation) {
    _imageSize = imageSize;
    _imageRotation = rotation;
    notifyListeners();
  }

  Future<void> stopImageStream() async {
    await _cameraController?.stopImageStream();
  }

  @override
  void dispose() {
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }
}