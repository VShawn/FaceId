import 'dart:async';
import 'dart:io';

import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:face_locker/utils/log_util.dart';

class CameraController {
  final CameraDescription _camera;
  int? _cameraId;
  int wdith = 0;
  int height = 0;
  StreamSubscription<CameraErrorEvent>? _errorStreamSubscription;
  StreamSubscription<CameraClosingEvent>? _cameraClosingStreamSubscription;

  CameraController(this._camera);

  Future<void> openCamera(
      ResolutionPreset resolutionPreset, void Function(CameraErrorEvent event)? onCameraError, void Function(CameraClosingEvent event)? onCameraClosing) async {
    try {
      final cameraId = await CameraPlatform.instance.createCamera(
        _camera,
        resolutionPreset,
        enableAudio: false,
      );
      unawaited(_errorStreamSubscription?.cancel());
      _errorStreamSubscription = CameraPlatform.instance.onCameraError(cameraId).listen(onCameraError);

      unawaited(_cameraClosingStreamSubscription?.cancel());
      _cameraClosingStreamSubscription = CameraPlatform.instance.onCameraClosing(cameraId).listen(onCameraClosing);

      final Future<CameraInitializedEvent> initialized = CameraPlatform.instance.onCameraInitialized(cameraId).first;

      await CameraPlatform.instance.initializeCamera(
        cameraId,
      );

      _cameraId = cameraId;
      final event = await initialized;
      wdith = event.previewWidth.toInt();
      height = event.previewHeight.toInt();
    } catch (e) {
      await closeCamera();
      throw Exception('Failed to open camera: $e');
    }
  }

  Future<void> closeCamera() async {
    _errorStreamSubscription?.cancel();
    _errorStreamSubscription = null;
    _cameraClosingStreamSubscription?.cancel();
    _cameraClosingStreamSubscription = null;
    if (isInitialized()) {
      try {
        if (_cameraId! >= 0) {
          await CameraPlatform.instance.dispose(_cameraId!);
        }
      } on CameraException catch (e) {
        LogD('Failed to dispose camera: ${e.code}: ${e.description}');
      }
    }
  }

  Future<String> captureImageToDisk() async {
    if (!isInitialized()) {
      throw Exception('Camera is not initialized');
    }

    // 读取摄像头图像，并显示到 _image
    final XFile file = await CameraPlatform.instance.takePicture(_cameraId!);
    return file.path;
  }

  bool isInitialized() {
    return _cameraId != null;
  }

  /// 读取相机列表
  static Future<List<CameraDescription>> getCameras() async {
    return CameraPlatform.instance.availableCameras();
  }

  // /// 获取相机名称列表
  // static Future<List<String>> getCameraNames(List<CameraDescription> cameras) async {
  //   return cameras.map((e) => getCameraName(e)).toList();
  // }

  static String getCameraDisplayName(CameraDescription camera) {
    final name = camera.name;
    // 如果是 windows， 则相机名称为 USB Camere <\\?USB#vid ...>，需要去掉 `<\\?` 后面的内容
    if (Platform.isWindows) {
      if (name.indexOf(r'<\\') > 0) return name.substring(0, name.indexOf(r'<\\'));
    } else {
      // TODO 支持其他系统
      throw Exception('Unsupported platform');
    }
    return name;
  }

  /// 根据相机名称获取相机
  static Future<CameraDescription?> getCameraByName(String cameraName) async {
    final cameras = await getCameras();
    return findCameraByName(cameras, cameraName);
  }

  static Future<CameraDescription?> findCameraByName(List<CameraDescription> cameras, String cameraName) async {
    try {
      return cameras.firstWhere((element) => element.name == cameraName);
    } catch (e) {
      return null;
    }
  }
}
