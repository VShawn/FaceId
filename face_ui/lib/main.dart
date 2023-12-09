// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:face_locker/model/face_box.dart';
import 'package:face_locker/view/camera_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:image_size_getter/image_size_getter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:win32/win32.dart';
import 'utils/flib.dart';
import 'package:face_locker/utils/log_util.dart' as LOG;

void main() {
  runApp(const MyApp());
}

/// Example app for Camera Windows plugin.
class MyApp extends StatefulWidget {
  /// Default Constructor
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _cameraInfo = 'Unknown';
  List<CameraDescription> _cameras = <CameraDescription>[];
  CameraDescription? _selectedCamera;
  int _cameraId = -1;
  bool _initialized = false;
  Size? _imageSize;
  List<FaceBox>? faces;
  ResolutionPreset _resolutionPreset = ResolutionPreset.veryHigh;
  StreamSubscription<CameraErrorEvent>? _errorStreamSubscription;
  StreamSubscription<CameraClosingEvent>? _cameraClosingStreamSubscription;
  late Timer _timer;
  MemoryImage? _image;

  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized();
    selectCamera(null);
    _timer = Timer.periodic(Duration(milliseconds: 1000 * 10), (timer) {
      _takePicture();
    });
  }

  @override
  void dispose() {
    _disposeCurrentCamera();
    _errorStreamSubscription?.cancel();
    _errorStreamSubscription = null;
    _cameraClosingStreamSubscription?.cancel();
    _cameraClosingStreamSubscription = null;
    _timer.cancel();
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
      cameras = await CameraPlatform.instance.availableCameras();
      if (cameras.isEmpty) {
        cameraInfo = 'No available cameras';
      }
    } on PlatformException catch (e) {
      cameraInfo = 'Failed to get cameras: ${e.code}: ${e.message}';
    }

    // 从 _cameras 中查找 name 和 selected.name 相同的相机的索引
    if (cameras.isNotEmpty) {
      int cameraIndex = 0;
      if (selectedName != null) {
        cameraIndex = cameras.indexWhere((element) => element.name == selectedName);
      }
      if (cameraIndex >= 0) {
        if (selectedName == null || selectedName != _selectedCamera?.name) {
          final prefs = await SharedPreferences.getInstance();
          prefs.setString('camera1', cameras[cameraIndex].name);
        }
      }
      // 如果查找成功则显示相机信息
      if (cameraIndex >= 0) {
        setState(() {
          _cameras = cameras;
          _selectedCamera = cameras[cameraIndex];
          _cameraInfo = _selectedCamera!.getName;
        });
        return Future.value();
      }
    }

    // 没有选择相机，或者选择的相机不在 _cameras 中，则显示未知相机信息
    setState(() {
      _cameras = cameras;
      _selectedCamera = null;
      _cameraInfo = cameraInfo;
    });
  }

  /// Initializes the camera on the device.
  Future<void> _initializeCamera() async {
    assert(!_initialized);

    if (_cameras.isEmpty || _selectedCamera == null) {
      return;
    }
    int cameraId = -1;
    try {
      cameraId = await CameraPlatform.instance.createCamera(
        _selectedCamera!,
        _resolutionPreset,
        enableAudio: false,
      );

      unawaited(_errorStreamSubscription?.cancel());
      _errorStreamSubscription = CameraPlatform.instance.onCameraError(cameraId).listen(_onCameraError);

      unawaited(_cameraClosingStreamSubscription?.cancel());
      _cameraClosingStreamSubscription = CameraPlatform.instance.onCameraClosing(cameraId).listen(_onCameraClosing);

      final Future<CameraInitializedEvent> initialized = CameraPlatform.instance.onCameraInitialized(cameraId).first;

      await CameraPlatform.instance.initializeCamera(
        cameraId,
      );

      // final CameraInitializedEvent event = await initialized;
      // _previewSize = Size(
      //   event.previewWidth,
      //   event.previewHeight,
      // );

      if (mounted) {
        setState(() {
          _initialized = true;
          _cameraId = cameraId;
          _cameraInfo = 'Capturing camera: ${_selectedCamera!.name}';
        });
      }
    } on CameraException catch (e) {
      try {
        if (cameraId >= 0) {
          await CameraPlatform.instance.dispose(cameraId);
        }
      } on CameraException catch (e) {
        debugPrint('Failed to dispose camera: ${e.code}: ${e.description}');
      }

      // Reset state.
      if (mounted) {
        setState(() {
          _initialized = false;
          _cameraId = -1;
          _imageSize = null;
          _cameraInfo = 'Failed to initialize camera: ${e.code}: ${e.description}';
        });
      }
    }
  }

  Future<void> _disposeCurrentCamera() async {
    if (_cameraId >= 0 && _initialized) {
      try {
        await CameraPlatform.instance.dispose(_cameraId);

        if (mounted) {
          setState(() {
            _initialized = false;
            _cameraId = -1;
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

  Widget _buildPreview() {
    return SizedBox(
      width: 100,
      height: 100,
      child: CameraPlatform.instance.buildPreview(_cameraId),
    );
  }

  Future<void> _takePicture() async {
    if (!_initialized) return;

    // 读取摄像头图像，并显示到 _image
    final XFile file = await CameraPlatform.instance.takePicture(_cameraId);
    _showInSnackBar('Picture captured to: ${file.path}');

    var fs = FaceLib.getInstance().detectFaces(file.path);
    print(fs);

    // 将 file 显示到界面上
    final bytes = await file.readAsBytes();
    final memoryImageSize = ImageSizeGetter.getSize(MemoryInput(bytes));
    final image = MemoryImage(bytes);
    setState(() {
      _cameraInfo = 'Picture captured to: ${file.path}';
      // _previewSize = const Size(100, 100);
      _image = image;
      _imageSize = Size(memoryImageSize.width, memoryImageSize.height);
      faces = fs;
    });

    // 删除 file.path 路径指向的文件
    final f = File(file.path);
    if (f.existsSync()) {
      await f.delete();
    }
  }

  Future<void> _onResolutionChange(ResolutionPreset newValue) async {
    setState(() {
      _resolutionPreset = newValue;
    });
    if (_initialized && _cameraId >= 0) {
      // Re-inits camera with new resolution preset.
      await _disposeCurrentCamera();
      await _initializeCamera();
    }
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
            if (_initialized && _cameraId > 0 && _imageSize != null && _image != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                ),
                child: Align(
                  child: SizedBox(
                    width: 400,
                    child: AspectRatio(
                      aspectRatio: _imageSize!.width / _imageSize!.height,
                      // child: _buildPreview(),
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
