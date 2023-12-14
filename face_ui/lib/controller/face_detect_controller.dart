import 'dart:async';
import 'dart:io';

import 'package:face_locker/controller/camera_controller.dart';
import 'package:face_locker/model/face_box.dart';
import 'package:face_locker/utils/flib.dart';
import 'package:face_locker/utils/log_util.dart';
import 'package:win32/win32.dart';

enum FaceDetectionMode {
  normal,
  fast,
}

class FaceDetectController {
  Timer? _timer;
  FaceDetectionMode _mode = FaceDetectionMode.normal;
  CameraController? _cameraController;

  void setCameraController(CameraController? cameraController) {
    _cameraController = cameraController;
  }

  int _normalTimerCounter = 0;
  int _fastTimerCounter = 0;

  void startFaceDetection() {
    stopFaceDetection();
    _mode = FaceDetectionMode.normal;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_cameraController?.isInitialized() != true) {
        LogD("timer reached, camera not initialized");
        return;
      } else {}

      if (_mode == FaceDetectionMode.normal) {
        _fastTimerCounter = 0;
        _normalTimerCounter++;
        if (_normalTimerCounter >= 10) {
          _normalTimerCounter = 0;
          if (!await detectFace()) {
            logWarning('未检测到人脸，进入快速模式');
            _mode = FaceDetectionMode.fast;
          } else {
            LogD('检测到人脸');
          }
        }
        return;
      } else {
        _normalTimerCounter = 0;
        if (!await detectFace()) {
          _fastTimerCounter++;
          if (_fastTimerCounter >= 10) {
            logWarning('长时间未检测到人脸');
            // TODO lock system
            // stop timer until system is unlock again
          }
        } else {
          _mode = FaceDetectionMode.normal;
        }
      }
    });
  }

  void stopFaceDetection() {
    _timer?.cancel();
  }

  Future<bool> detectFace({String? path}) async {
    if (_cameraController?.isInitialized() == true) {
      String p = path ?? await _cameraController!.captureImageToDisk();
      var fs = FaceLib.getInstance().detectFaces(p);
      if (path == null) {
        final f = File(p);
        if (f.existsSync()) {
          await f.delete();
        }
      }

      // 打印 area 最大的 fs
      FaceBox? maxAreaFace;
      for (var f in fs) {
        if (maxAreaFace == null) {
          maxAreaFace = f;
        } else {
          if (f.area > maxAreaFace.area) {
            maxAreaFace = f;
          }
        }
      }
      if (maxAreaFace != null) {
        LogD('max area face: $maxAreaFace');
      }
      LogD(fs);
      return (maxAreaFace?.area ?? 0) > 4000;
    }
    return false;
  }
}
