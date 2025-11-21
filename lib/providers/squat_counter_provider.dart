// lib/providers/squat_counter_provider.dart
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math' as math;

class SquatCounterProvider extends ChangeNotifier {
  int _squatCount = 0;
  String _squatState = 'standing'; // 'standing', 'squatting'
  bool _inSquatPosition = false;
  String _feedback = 'Start squatting!';

  // Calibration values
  final double _squatThresholdAngle = 90;
  final double _standingThresholdAngle = 140;
  final double _minHipAngle = 70;
  final double _maxHipAngle = 120;

  int get squatCount => _squatCount;
  String get squatState => _squatState;
  String get feedback => _feedback;

  void processPose(Pose pose, Function(String) onSpeak) {
    // Get landmarks
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];

    if (leftHip == null ||
        leftKnee == null ||
        leftAnkle == null ||
        rightHip == null ||
        rightKnee == null ||
        rightAnkle == null ||
        leftShoulder == null ||
        rightShoulder == null) {
      return;
    }

    // Calculate angles
    final leftKneeAngle =
    _calculateAngleFromLandmarks(leftHip, leftKnee, leftAnkle);
    final rightKneeAngle =
    _calculateAngleFromLandmarks(rightHip, rightKnee, rightAnkle);
    final leftHipAngle =
    _calculateAngleFromLandmarks(leftShoulder, leftHip, leftKnee);
    final rightHipAngle =
    _calculateAngleFromLandmarks(rightShoulder, rightHip, rightKnee);

    // Use average of both sides
    final avgKneeAngle = (leftKneeAngle + rightKneeAngle) / 2.0;
    final avgHipAngle = (leftHipAngle + rightHipAngle) / 2.0;

    // Get feedback
    String newFeedback = _getFeedback(avgKneeAngle, avgHipAngle);

    // Squat counting logic
    if (avgKneeAngle < _squatThresholdAngle && !_inSquatPosition) {
      _inSquatPosition = true;
      _squatState = 'squatting';
      onSpeak('Squatting');
    } else if (avgKneeAngle > _standingThresholdAngle && _inSquatPosition) {
      _inSquatPosition = false;
      _squatState = 'standing';
      _squatCount++;
      onSpeak('Rep $_squatCount completed');
    }

    // Speak feedback for form corrections
    if (newFeedback != _feedback && newFeedback.contains('!')) {
      onSpeak(newFeedback.replaceAll('!', ''));
    }

    _feedback = newFeedback;
    notifyListeners();
  }

  double _calculateAngleFromLandmarks(
      PoseLandmark a,
      PoseLandmark b,
      PoseLandmark c,
      ) {
    final double abx = a.x - b.x;
    final double aby = a.y - b.y;
    final double cbx = c.x - b.x;
    final double cby = c.y - b.y;

    final double dot = (abx * cbx) + (aby * cby);
    final double magAB = math.sqrt(abx * abx + aby * aby);
    final double magCB = math.sqrt(cbx * cbx + cby * cby);

    if (magAB == 0 || magCB == 0) return 0.0;

    double cosAngle = dot / (magAB * magCB);
    cosAngle = cosAngle.clamp(-1.0, 1.0);

    final angle = math.acos(cosAngle) * 180.0 / math.pi;
    return angle;
  }

  String _getFeedback(double kneeAngle, double hipAngle) {
    if (_squatState == 'squatting') {
      if (kneeAngle < 70) {
        return 'Too deep! Come up slightly';
      } else if (hipAngle < _minHipAngle) {
        return 'Keep your chest up!';
      } else if (hipAngle > _maxHipAngle) {
        return 'Lean forward slightly more';
      } else {
        return 'Great form! Hold and rise';
      }
    } else {
      if (kneeAngle > _standingThresholdAngle) {
        return 'Ready for next rep';
      } else if (kneeAngle > _squatThresholdAngle) {
        return 'Go deeper!';
      } else {
        return 'Good depth!';
      }
    }
  }

  void reset(Function(String) onSpeak) {
    _squatCount = 0;
    _squatState = 'standing';
    _inSquatPosition = false;
    _feedback = 'Start squatting!';
    notifyListeners();
    onSpeak('Counter reset');
  }
}