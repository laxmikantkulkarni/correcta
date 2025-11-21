// lib/widgets/skeleton_painter.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'dart:math' as math;

class SkeletonPainter extends CustomPainter {
  final Pose? pose;
  final Size imageSize;
  final Size previewSize;
  final InputImageRotation rotation;
  final bool isFrontCamera;

  SkeletonPainter({
    required this.pose,
    required this.imageSize,
    required this.previewSize,
    required this.rotation,
    required this.isFrontCamera,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (pose == null) return;

    final Paint landmarkPaint = Paint()
      ..color = Colors.lightGreenAccent
      ..strokeWidth = 6
      ..style = PaintingStyle.fill;

    final Paint bonePaint = Paint()
      ..color = Colors.deepPurpleAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Draw all bones first
    for (var bone in _bones) {
      final p1 = pose!.landmarks[bone.$1];
      final p2 = pose!.landmarks[bone.$2];

      if (p1 != null && p2 != null) {
        final mapped1 = _mapPoint(p1.x, p1.y);
        final mapped2 = _mapPoint(p2.x, p2.y);

        canvas.drawLine(mapped1, mapped2, bonePaint);
      }
    }

    // Draw all keypoints
    pose!.landmarks.forEach((type, landmark) {
      final mapped = _mapPoint(landmark.x, landmark.y);
      canvas.drawCircle(mapped, 4, landmarkPaint);
    });
  }

  /// Mapping ML Kit camera coordinates to the device preview coordinates
  Offset _mapPoint(double x, double y) {
    double rotatedX = x;
    double rotatedY = y;

    // 1. FIX ORIENTATION
    switch (rotation) {
      case InputImageRotation.rotation90deg:
        rotatedX = y;
        rotatedY = imageSize.width - x;
        break;

      case InputImageRotation.rotation180deg:
        rotatedX = imageSize.width - x;
        rotatedY = imageSize.height - y;
        break;

      case InputImageRotation.rotation270deg:
        rotatedX = imageSize.height - y;
        rotatedY = x;
        break;

      default:
        break;
    }

    // 2. MIRROR FOR FRONT CAMERA
    if (isFrontCamera) {
      rotatedX = imageSize.width - rotatedX;
    }

    // 3. SCALE TO PREVIEW SIZE
    final double scaleX = previewSize.width / imageSize.width;
    final double scaleY = previewSize.height / imageSize.height;
    final double scale = math.max(scaleX, scaleY);

    final scaledX = rotatedX * scale;
    final scaledY = rotatedY * scale;

    // 4. REMOVE LETTERBOXING
    final double offsetX = (scaledWidth - previewSize.width) / 2;
    final double offsetY = (scaledHeight - previewSize.height) / 2;

    return Offset(
      scaledX - offsetX,
      scaledY - offsetY,
    );
  }

  double get scaledWidth =>
      (rotation == InputImageRotation.rotation90deg ||
          rotation == InputImageRotation.rotation270deg)
          ? imageSize.height *
          math.max(previewSize.width / imageSize.height,
              previewSize.height / imageSize.width)
          : imageSize.width *
          math.max(previewSize.width / imageSize.width,
              previewSize.height / imageSize.height);

  double get scaledHeight =>
      (rotation == InputImageRotation.rotation90deg ||
          rotation == InputImageRotation.rotation270deg)
          ? imageSize.width *
          math.max(previewSize.width / imageSize.height,
              previewSize.height / imageSize.width)
          : imageSize.height *
          math.max(previewSize.width / imageSize.width,
              previewSize.height / imageSize.height);

  @override
  bool shouldRepaint(covariant SkeletonPainter oldDelegate) =>
      oldDelegate.pose != pose;
}

/// BONES (connecting joints)
final List<(PoseLandmarkType, PoseLandmarkType)> _bones = [
  (PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder),
  (PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow),
  (PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist),
  (PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow),
  (PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist),
  (PoseLandmarkType.leftHip, PoseLandmarkType.rightHip),
  (PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip),
  (PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip),
  (PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee),
  (PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle),
  (PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee),
  (PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle),
];