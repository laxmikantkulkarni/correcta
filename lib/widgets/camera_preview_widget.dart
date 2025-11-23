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
            final double aspect =
                cameraProvider.cameraController!.value.aspectRatio;

            return Center(
              child: AspectRatio(
                aspectRatio: aspect, // Ensures no stretch
                child: LayoutBuilder(
                  builder: (context, cameraConstraints) {
                    final previewSize = Size(
                      cameraConstraints.maxWidth,
                      cameraConstraints.maxHeight,
                    );



                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        // Camera Preview
                        CameraPreview(cameraProvider.cameraController!),

                        // Skeleton Overlay
                        if (poseProvider.latestPose != null)
                          CustomPaint(
                            painter: SkeletonPainter(
                              poses: poseProvider.poses,
                              imageSize: cameraProvider.imageSize!,   // MLKit size (e.g. 720x480)
                              previewSize: previewSize,               // Current preview dimensions
                              cameraLensDirection:
                              cameraProvider.cameraLensDirection!,
                              rotation: cameraProvider.imageRotation!,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
