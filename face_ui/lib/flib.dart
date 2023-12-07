import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

import 'dart:ffi';
import 'package:ffi/ffi.dart';

class FaceResult {
  final double x1;
  final double y1;

  final double x2;
  final double y2;

  double get width => x2 - x1;
  double get height => y2 - y1;

  final double eye1X;
  final double eye1Y;

  final double eye2X;
  final double eye2Y;

  final double noseX;
  final double noseY;

  final double mouth1X;
  final double mouth1Y;

  final double mouth2X;
  final double mouth2Y;

  final int faceId;

  FaceResult(
      {required this.x1,
      required this.y1,
      required this.x2,
      required this.y2,
      required this.eye1X,
      required this.eye1Y,
      required this.eye2X,
      required this.eye2Y,
      required this.noseX,
      required this.noseY,
      required this.mouth1X,
      required this.mouth1Y,
      required this.mouth2X,
      required this.mouth2Y,
      required this.faceId});

  // 实现打印方法
  @override
  String toString() {
    return 'FaceResult{x1: $x1, y1: $y1, x2: $x2, y2: $y2, eye1X: $eye1X, eye1Y: $eye1Y, eye2X: $eye2X, eye2Y: $eye2Y, noseX: $noseX, noseY: $noseY, mouth1X: $mouth1X, mouth1Y: $mouth1Y, mouth2X: $mouth2X, mouth2Y: $mouth2Y, faceId: $faceId}';
  }
}

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

class FaceLib {
  final String dllPath;
  late DynamicLibrary nativeApi;
  late FFI_FaceDetectFile faceDetectFileC;
  FaceLib({this.dllPath = "flib.dll"}) {
    //加载库
    // DynamicLibrary nativeApi = Platform.isAndroid
    //     ? DynamicLibrary.open("libnative_ffi.so")
    //     : DynamicLibrary.process();
    nativeApi = DynamicLibrary.open(dllPath);
    faceDetectFileC = nativeApi.lookupFunction<Native_FaceDetectFile, FFI_FaceDetectFile>("FaceDetectFile");
  }

  List<FaceResult> detectFaces(String imagePath) {
    // toNativeUtf8() 是由 ffi 库提供的API，调用该函数时会在 Native 中分配内存，因此使用完后也需要释放内存。也可以使用 calloc.free() 来释放由 malloc 分配的内存；
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
    faceDetectFileC(
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
    List<FaceResult> results = [];
    for (int i = 0; i < countDart; i++) {
      results.add(FaceResult(
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

  static late FaceLib? _instance;
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
