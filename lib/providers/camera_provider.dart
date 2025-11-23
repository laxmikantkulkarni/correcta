// lib/providers/camera_provider.dart (WITH THROTTLED DEBUG)
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

class CameraProvider extends ChangeNotifier {
  CameraController? _cameraController;
  CameraDescription? _cameraDescription;
  CameraLensDirection? _cameraLensDirection;
  bool _isInitialized = false;
  bool _isFrontCamera = false;
  Size? _imageSize;
  InputImageRotation? _imageRotation;
  DateTime? _lastDebugPrint;

  CameraController? get cameraController => _cameraController;
  bool get isInitialized => _isInitialized;
  bool get isFrontCamera => _isFrontCamera;
  Size? get imageSize => _imageSize;
  InputImageRotation? get imageRotation => _imageRotation;
  CameraLensDirection? get cameraLensDirection => _cameraLensDirection;


  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };


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
    _cameraLensDirection = _cameraDescription!.lensDirection;


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
    InputImageRotation? rotation = InputImageRotation.rotation0deg;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
      _orientations[_cameraController!.value.deviceOrientation];
      if (_isFrontCamera) {
        // front-facing
        rotationCompensation =
            (sensorOrientation + rotationCompensation!) % 360;
      } else {
        // back-facing
        rotationCompensation =
            (sensorOrientation - rotationCompensation! + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation != null) {
      return rotation;
    }
    return InputImageRotation.rotation0deg;
  }

  void updateImageMetadata(Size imageSize, InputImageRotation rotation) {
    _imageSize = imageSize;
    _imageRotation = rotation;

    // Throttled debug print (every 2 seconds instead of 60 times per second)
    final now = DateTime.now();
    if (_lastDebugPrint == null ||
        now.difference(_lastDebugPrint!) > Duration(seconds: 2)) {
      debugPrint('');
      debugPrint('═══════════════════════════════════════');
      debugPrint('📷 CAMERA METADATA:');
      debugPrint('Image Size: ${imageSize.width.toInt()} x ${imageSize.height.toInt()}');
      debugPrint('Rotation: $rotation');
      debugPrint('Sensor Orientation: ${_cameraDescription?.sensorOrientation}°');
      debugPrint('Is Front Camera: $_isFrontCamera');
      debugPrint('═══════════════════════════════════════');
      _lastDebugPrint = now;
    }

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