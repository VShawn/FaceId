import 'dart:ffi';
import 'dart:io';
import 'package:face_locker/model/face_box.dart';
import 'package:face_locker/utils/log_util.dart' as LOG;
import 'package:ffi/ffi.dart';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';

// 定义 C 函数签名
typedef Native_FaceDetectFile = Void Function(
  Pointer<Utf8> filePath,
  Pointer<Float> x1,
  Pointer<Float> y1,
  Pointer<Float> x2,
  Pointer<Float> y2,
  Pointer<Float> f1x,
  Pointer<Float> f1y,
  Pointer<Float> f2x,
  Pointer<Float> f2y,
  Pointer<Float> f3x,
  Pointer<Float> f3y,
  Pointer<Float> f4x,
  Pointer<Float> f4y,
  Pointer<Float> f5x,
  Pointer<Float> f5y,
  Pointer<Int32> count,
);
typedef FFI_FaceDetectFile = void Function(
  Pointer<Utf8> filePath,
  Pointer<Float> x1,
  Pointer<Float> y1,
  Pointer<Float> x2,
  Pointer<Float> y2,
  Pointer<Float> f1x,
  Pointer<Float> f1y,
  Pointer<Float> f2x,
  Pointer<Float> f2y,
  Pointer<Float> f3x,
  Pointer<Float> f3y,
  Pointer<Float> f4x,
  Pointer<Float> f4y,
  Pointer<Float> f5x,
  Pointer<Float> f5y,
  Pointer<Int32> count,
);

// 定义 C 函数签名
typedef Native_Init = Int32 Function(Pointer<Utf8> filePath, Int32 size);
typedef FFI_Init = int Function(Pointer<Utf8> filePath, int size);

class FaceLib {
  late String modelPath;
  late int modelSize;
  late DynamicLibrary? nativeApi;
  late FFI_FaceDetectFile? _faceDetectFileC;
  FaceLib({this.modelSize = 640}) {
    //加载库
    // DynamicLibrary nativeApi = Platform.isAndroid
    //     ? DynamicLibrary.open("libnative_ffi.so")
    //     : DynamicLibrary.process();
    // print current path
    // print(Directory.current.path);
    // nativeApi = DynamicLibrary.open(dllPath);
    if (kReleaseMode) {
      modelPath = join(Directory(Platform.resolvedExecutable).parent.path, 'data', 'flutter_assets', 'assets', 'yolov5face-n-640x640.opt.bin');
    } else {
      var path = Directory.current.path;
      modelPath = '$path/assets/yolov5face-n-640x640.opt.bin';
    }
    try {
      if (kReleaseMode) {
        // I'm on release mode, absolute linking
        final String localLib = join('data', 'flutter_assets', 'assets', 'flib.dll');
        String pathToLib = join(Directory(Platform.resolvedExecutable).parent.path, localLib);
        nativeApi = DynamicLibrary.open(pathToLib);
      } else {
        // I'm on debug mode, local linking
        var path = Directory.current.path;
        nativeApi = DynamicLibrary.open('$path/assets/flib.dll');
      }
    } catch (e) {
      LOG.LogE(e.toString());
      nativeApi = null;
    }
    _faceDetectFileC = nativeApi?.lookupFunction<Native_FaceDetectFile, FFI_FaceDetectFile>("FaceDetectFile");
    init();
  }

  bool init() {
    LOG.LogD("init with modelPath: $modelPath");
    if (_faceDetectFileC == null) {
      LOG.LogE("_initC is null, dll not loaded!");
      return false;
    }

    final pathC = modelPath.toNativeUtf8();
    var result = -1;
    try {
      final initC = nativeApi?.lookupFunction<Native_Init, FFI_Init>("Init");
      result = initC!(pathC, modelSize);
    } catch (e) {
      LOG.LogE(e.toString());
    }
    calloc.free(pathC);
    return result == 0;
  }

  List<FaceBox> detectFaces(String imagePath) {
    // toNativeUtf8() 是由 ffi 库提供的API，调用该函数时会在 Native 中分配内存，因此使用完后也需要释放内存。也可以使用 calloc.free() 来释放由 malloc 分配的内存；

    if (_faceDetectFileC == null) {
      LOG.LogE("faceDetectFileC is null, dll not loaded!");
      return [];
    }

    final filePath = imagePath.toNativeUtf8();
    // 创建长度为100的数组
    // 创建参数变量
    final x1 = calloc<Float>(100);
    final y1 = calloc<Float>(100);
    final x2 = calloc<Float>(100);
    final y2 = calloc<Float>(100);
    final f1x = calloc<Float>(100);
    final f1y = calloc<Float>(100);
    final f2x = calloc<Float>(100);
    final f2y = calloc<Float>(100);
    final f3x = calloc<Float>(100);
    final f3y = calloc<Float>(100);
    final f4x = calloc<Float>(100);
    final f4y = calloc<Float>(100);
    final f5x = calloc<Float>(100);
    final f5y = calloc<Float>(100);
    final ccount = calloc<Int32>();
    _faceDetectFileC!(
      filePath,
      x1,
      y1,
      x2,
      y2,
      f1x,
      f1y,
      f2x,
      f2y,
      f3x,
      f3y,
      f4x,
      f4y,
      f5x,
      f5y,
      ccount,
    );

    // // 打印数组的值
    // for (int i = 0; i < 100; i++) {
    //   print(x1[i]);
    // }

    List<double> x1array = x1.asTypedList(100);
    List<double> y1array = y1.asTypedList(100);
    List<double> x2array = x2.asTypedList(100);
    List<double> y2array = y2.asTypedList(100);
    List<double> f1xarray = f1x.asTypedList(100);
    List<double> f1yarray = f1y.asTypedList(100);
    List<double> f2xarray = f2x.asTypedList(100);
    List<double> f2yarray = f2y.asTypedList(100);
    List<double> f3xarray = f3x.asTypedList(100);
    List<double> f3yarray = f3y.asTypedList(100);
    List<double> f4xarray = f4x.asTypedList(100);
    List<double> f4yarray = f4y.asTypedList(100);
    List<double> f5xarray = f5x.asTypedList(100);
    List<double> f5yarray = f5y.asTypedList(100);
    int countDart = ccount.value;

    // deep clone dartArray
    x1array = List.from(x1array);
    y1array = List.from(y1array);
    x2array = List.from(x2array);
    y2array = List.from(y2array);
    f1xarray = List.from(f1xarray);
    f1yarray = List.from(f1yarray);
    f2xarray = List.from(f2xarray);
    f2yarray = List.from(f2yarray);
    f3xarray = List.from(f3xarray);
    f3yarray = List.from(f3yarray);
    f4xarray = List.from(f4xarray);
    f4yarray = List.from(f4yarray);
    f5xarray = List.from(f5xarray);
    f5yarray = List.from(f5yarray);

    // 释放字符串所占用的内存
    calloc.free(filePath);
    // 释放数组所占用的内存
    calloc.free(x1);
    calloc.free(y1);
    calloc.free(x2);
    calloc.free(y2);
    calloc.free(f1x);
    calloc.free(f1y);
    calloc.free(f2x);
    calloc.free(f2y);
    calloc.free(f3x);
    calloc.free(f3y);
    calloc.free(f4x);
    calloc.free(f4y);
    calloc.free(f5x);
    calloc.free(f5y);
    calloc.free(ccount);

    // print(x1array);
    // print(countDart);

    // 准备返回值
    List<FaceBox> results = [];
    for (int i = 0; i < countDart; i++) {
      results.add(FaceBox(
          x1: x1array[i],
          y1: y1array[i],
          x2: x2array[i],
          y2: y2array[i],
          eye1X: f1xarray[i],
          eye1Y: f1yarray[i],
          eye2X: f2xarray[i],
          eye2Y: f2yarray[i],
          noseX: f3xarray[i],
          noseY: f3yarray[i],
          mouth1X: f4xarray[i],
          mouth1Y: f4yarray[i],
          mouth2X: f5xarray[i],
          mouth2Y: f5yarray[i],
          faceId: i));
    }
    return results;
  }

  static FaceLib? _instance;
  // 静态 FaceLib 对象初始化
  static FaceLib getInstance() {
    _instance ??= FaceLib();
    return _instance!;
  }
}

// void main(List<String> args) {
//   final lib = FaceLib(dllPath: "flib.dll");
// //调用函数
//   String value = "1.jpg";
//   var fs = lib.detectFaces(value);
//   print(fs);
// }
