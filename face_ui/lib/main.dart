// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:face_locker/controller/face_detect_controller.dart';
import 'package:face_locker/model/face_box.dart';
import 'package:face_locker/view/camera_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_size_getter/image_size_getter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_tray/system_tray.dart';
import 'package:win32/win32.dart';
import 'controller/camera_controller.dart';
import 'utils/flib.dart';
import 'package:face_locker/utils/log_util.dart' as LOG;

void main() async {
  runApp(const ProviderScope(child: MyApp()));

  String path = Platform.isWindows ? 'assets/images/notebook.ico' : 'assets/images/flutter.png';

  final AppWindow appWindow = AppWindow();
  final SystemTray systemTray = SystemTray();

  // We first init the systray menu
  await systemTray.initSystemTray(
    title: "system tray",
    iconPath: path,
  );

  // create context menu
  final Menu menu = Menu();
  await menu.buildFrom([
    MenuItemLabel(label: 'Show', onClicked: (menuItem) => appWindow.show()),
    MenuItemLabel(label: 'Hide', onClicked: (menuItem) => appWindow.hide()),
    MenuItemLabel(label: 'Exit', onClicked: (menuItem) => appWindow.close()),
  ]);

  // set context menu
  await systemTray.setContextMenu(menu);

  // handle system tray event
  systemTray.registerSystemTrayEventHandler((eventName) {
    debugPrint("eventName: $eventName");
    if (eventName == kSystemTrayEventClick) {
      Platform.isWindows ? appWindow.show() : systemTray.popUpContextMenu();
    } else if (eventName == kSystemTrayEventRightClick) {
      Platform.isWindows ? systemTray.popUpContextMenu() : appWindow.show();
    }
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _cameraInfo = 'Unknown';
  List<CameraDescription> _cameras = <CameraDescription>[];
  CameraDescription? _selectedCamera;
  bool _initialized = false;
  Size? _imageSize;
  ResolutionPreset _resolutionPreset = ResolutionPreset.medium;
  MemoryImage? _image;
  CameraController? _cameraController;
  final FaceDetectController _faceDetectController = FaceDetectController();

  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized();
    selectCamera(null);
  }

  @override
  void dispose() {
    _disposeCurrentCamera();
    super.dispose();
  }

  Future<void> selectCamera(String? selectedName) async {
    if (selectedName == null) {
      final prefs = await SharedPreferences.getInstance();
      selectedName = prefs.getString('camera1');
    }

    String cameraInfo = "Unknown";

    List<CameraDescription> cameras = <CameraDescription>[];
    try {
      cameras = await CameraController.getCameras();
      if (cameras.isEmpty) {
        cameraInfo = 'No available cameras';
      }
    } on PlatformException catch (e) {
      cameraInfo = 'Failed to get cameras: ${e.code}: ${e.message}';
    }

    var camera = await CameraController.getCameraByName(selectedName!);
    if (camera != null) {
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('camera1', camera.name);
      setState(() {
        _cameras = cameras;
        _selectedCamera = camera;
        _cameraInfo = camera.getName;
      });
    } else {
      // 没有选择相机，或者选择的相机不在 _cameras 中，则显示未知相机信息
      setState(() {
        _cameras = cameras;
        _selectedCamera = cameras.firstOrNull;
        _cameraInfo = cameraInfo;
      });
    }
  }

  /// Initializes the camera on the device.
  Future<void> _initializeCamera() async {
    _cameraController?.closeCamera();
    if (_selectedCamera == null) return;

    final cameraController = CameraController(_selectedCamera!);
    try {
      await cameraController.openCamera(_resolutionPreset, _onCameraError, _onCameraClosing);
      _cameraController = cameraController;
      _faceDetectController.setCameraController(cameraController);
      _faceDetectController.startFaceDetection();
      if (mounted) {
        setState(() {
          _initialized = true;
          _cameraInfo = 'Capturing camera: ${_selectedCamera!.name}';
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      if (mounted) {
        setState(() {
          _initialized = true;
          _cameraInfo = 'Capturing camera: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _disposeCurrentCamera() async {
    if (_cameraController?.isInitialized() == true) {
      try {
        await _cameraController?.closeCamera();
        _cameraController = null;
        _faceDetectController.setCameraController(null);
        _faceDetectController.stopFaceDetection();
        if (mounted) {
          setState(() {
            _initialized = false;
            _imageSize = null;
            _cameraInfo = 'Camera disposed';
          });
        }
      } on CameraException catch (e) {
        if (mounted) {
          setState(() {
            _cameraInfo = 'Failed to dispose camera: ${e.code}: ${e.description}';
          });
        }
      }
    }
  }

  // Widget _buildPreview() {
  //   return SizedBox(
  //     width: 100,
  //     height: 100,
  //     child: CameraPlatform.instance.buildPreview(_cameraId),
  //   );
  // }

  Future<void> _takePicture() async {
    if (_cameraController?.isInitialized() != true) {
      LOG.LogD('Camera is not initialized');
      return;
    }

    // 读取摄像头图像，并显示到 _image
    final path = await _cameraController!.captureImageToDisk();
    await _faceDetectController.detectFace(path: path);
    if (path == "") return;

    _showInSnackBar('Picture captured to: $path');

    var fs = FaceLib.getInstance().detectFaces(path);
    LOG.LogD(fs);

    // 将 path 读取为 bytes
    File file = File(path);
    final bytes = file.readAsBytesSync();
    final memoryImageSize = ImageSizeGetter.getSize(MemoryInput(bytes));
    final image = MemoryImage(bytes);
    setState(() {
      _cameraInfo = 'Picture captured to: $path';
      // _previewSize = const Size(100, 100);
      _image = image;
      _imageSize = Size(memoryImageSize.width, memoryImageSize.height);
    });

    // 删除 path 路径指向的文件
    final f = File(path);
    if (f.existsSync()) {
      await f.delete();
    }
  }

  Future<void> _onResolutionChange(ResolutionPreset newValue) async {
    setState(() {
      _resolutionPreset = newValue;
    });
    if (_cameraController?.isInitialized() != true) return;
    // Re-inits camera with new resolution preset.
    await _disposeCurrentCamera();
    await _initializeCamera();
  }

  void _onCameraError(CameraErrorEvent event) {
    if (mounted) {
      _scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(content: Text('Error: ${event.description}')));
      // Dispose camera on camera error as it can not be used anymore.
      _disposeCurrentCamera();
    }
  }

  void _onCameraClosing(CameraClosingEvent event) {
    if (mounted) {
      _showInSnackBar('Camera is closing');
    }
  }

  void _showInSnackBar(String message) {
    _scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 1),
    ));
  }

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    final List<DropdownMenuItem<ResolutionPreset>> resolutionItems = ResolutionPreset.values.map<DropdownMenuItem<ResolutionPreset>>((ResolutionPreset value) {
      return DropdownMenuItem<ResolutionPreset>(
        value: value,
        child: Text(value.toString()),
      );
    }).toList();

    return MaterialApp(
      scaffoldMessengerKey: _scaffoldMessengerKey,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: ListView(
          children: <Widget>[
            CameraSelector(
              cameras: _cameras,
              selectedCamera: _selectedCamera,
              onCameraSelected: (CameraDescription camera) async {
                if (_initialized) {
                  await _disposeCurrentCamera();
                }
                await selectCamera(camera.name);
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 5,
                horizontal: 10,
              ),
              child: Text(_cameraInfo),
            ),
            if (_cameras.isEmpty)
              ElevatedButton(
                onPressed: () {
                  selectCamera(_selectedCamera?.name);
                },
                child: const Text('Re-check available cameras'),
              ),
            if (_cameras.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  DropdownButton<ResolutionPreset>(
                    value: _resolutionPreset,
                    onChanged: (ResolutionPreset? value) {
                      if (value != null) {
                        _onResolutionChange(value);
                      }
                    },
                    items: resolutionItems,
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: _initialized ? _disposeCurrentCamera : _initializeCamera,
                    child: Text(_initialized ? 'Dispose camera' : 'Create camera'),
                  ),
                  const SizedBox(width: 5),
                  ElevatedButton(
                    onPressed: _initialized ? _takePicture : null,
                    child: const Text('Take picture'),
                  ),
                ],
              ),
            const SizedBox(height: 5),
            if (_cameraController?.isInitialized() == true && _imageSize != null && _image != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                ),
                child: Align(
                  child: SizedBox(
                    width: 400,
                    child: AspectRatio(
                      aspectRatio: _imageSize!.width / _imageSize!.height,
                      child: Image(image: _image!),
                    ),
                  ),
                ),
              ),
            if (_imageSize != null)
              Center(
                child: Text(
                  'Preview size: ${_imageSize!.width.toStringAsFixed(0)}x${_imageSize!.height.toStringAsFixed(0)}',
                ),
              ),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.start,
              children: [
                const SizedBox(
                  width: 10,
                ),
                TextButton(
                  onPressed: () {
                    LockWorkStation();
                  },
                  child: const Text(
                    "LockWorkStation",
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
