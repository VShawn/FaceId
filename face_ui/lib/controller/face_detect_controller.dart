import 'dart:async';

import 'package:face_locker/utils/log_util.dart';

enum FaceDetectionMode {
  normal,
  fast,
}

class FaceDetectController {
  Timer? _timer;
  int _faceDetectionCount = 0;
  FaceDetectionMode _mode = FaceDetectionMode.normal;

  int _normalTimerCounter = 0;
  int _fastTimerCounter = 0;
  void startFaceDetection() {
    stopFaceDetection();
    _mode = FaceDetectionMode.normal;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_mode == FaceDetectionMode.normal) {
        _fastTimerCounter = 0;
        _normalTimerCounter++;
        if (_normalTimerCounter >= 5) {
          _normalTimerCounter = 0;
          bool faceDetected = detectFace();
          if (!faceDetected) {
            LogW('未检测到人脸，进入快速模式');
            _mode = FaceDetectionMode.fast;
          } else {
            LogD('检测到人脸');
          }
        }
        return;
      } else {
        _normalTimerCounter = 0;
        bool faceDetected = detectFace();
        if (!faceDetected) {
          _fastTimerCounter++;
          if (_fastTimerCounter >= 5) {
            LogW('长时间未检测到人脸');
            stopFaceDetection();
          }
        }
      }
    });
  }

  void stopFaceDetection() {
    _timer?.cancel();
  }

  bool detectFace() {
    // TODO: 实现面部检测的逻辑
    return false;
  }
}
