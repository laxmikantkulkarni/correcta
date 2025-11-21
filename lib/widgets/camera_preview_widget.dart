// lib/widgets/camera_preview_widget.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../providers/camera_provider.dart';
import '../providers/pose_detector_provider.dart';
import 'skeleton_painter.dart';

class CameraPreviewWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer2<CameraProvider, PoseDetectorProvider>(
      builder: (context, cameraProvider, poseProvider, child) {
        if (!cameraProvider.isInitialized ||
            cameraProvider.cameraController == null) {
          return Center(child: CircularProgressIndicator());
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            // Update preview size
            WidgetsBinding.instance.addPostFrameCallback((_) {
              cameraProvider.setPreviewSize(constraints.biggest);
            });

            return Stack(
              fit: StackFit.expand,
              children: [
                // Camera Preview
                CameraPreview(cameraProvider.cameraController!),

                // Skeleton Overlay
                if (poseProvider.latestPose != null &&
                    cameraProvider.imageSize != null &&
                    cameraProvider.imageRotation != null &&
                    cameraProvider.previewSize != null)
                  CustomPaint(
                    painter: SkeletonPainter(
                      pose: poseProvider.latestPose,
                      imageSize: cameraProvider.imageSize!,
                      previewSize: cameraProvider.previewSize!,
                      rotation: cameraProvider.imageRotation!,
                      isFrontCamera: cameraProvider.isFrontCamera,
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}