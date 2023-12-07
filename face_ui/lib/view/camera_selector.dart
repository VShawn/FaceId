import 'package:flutter/material.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';

class CameraSelector extends StatefulWidget {
  final List<CameraDescription> cameras;
  final CameraDescription? selectedCamera;
  final Function(CameraDescription) onCameraSelected;

  const CameraSelector({required this.cameras, required this.selectedCamera, required this.onCameraSelected});

  @override
  _CameraSelectorState createState() => _CameraSelectorState();
}

class _CameraSelectorState extends State<CameraSelector> {
  CameraDescription? _selectedCamera;
  late List<CameraDescription> _cameras;

  @override
  void initState() {
    super.initState();
    _selectedCamera = widget.selectedCamera;
    _cameras = widget.cameras;
  }

  @override
  void didUpdateWidget(CameraSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedCamera != oldWidget.selectedCamera) {
      setState(() {
        _selectedCamera = widget.selectedCamera;
      });
    }

    if (widget.cameras != oldWidget.cameras) {
      setState(() {
        _cameras = widget.cameras;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<CameraDescription>(
      value: _selectedCamera,
      items: _cameras.map((CameraDescription camera) {
        return DropdownMenuItem<CameraDescription>(
          value: camera,
          child: Text(camera.getName),
        );
      }).toList(),
      onChanged: (CameraDescription? selectedCamera) {
        setState(() {
          _selectedCamera = selectedCamera;
        });
        widget.onCameraSelected(selectedCamera!);
      },
    );
  }
}

// 为 CameraSelector 拓展一个 getname 方法，用于获取相机名称，不同系统返回不同的后缀
extension CameraSelectorExtension on CameraDescription {
  String get getName {
    // if (CameraPlatform.instance is WindowsCameraPlugin) {
    //   return 'Camera ${this.lensDirection.toString().split('.').last}';
    // }
    // TODO: 其他平台的设备名称如何获取？
    // windows 下相机名称为 USB Camere <\\?USB#vid ...>，需要去掉后面的内容
    if (name.indexOf(r'<\\') > 0) return name.substring(0, name.indexOf(r'<\\'));
    return name;
  }
}
