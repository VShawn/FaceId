import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

typedef Native_reverseString = Void Function(Pointer<Int8>);
typedef FFI_reverseString = void Function(Pointer<Int8>);

typedef Native_freeString = Void Function(Pointer<Int8>);
typedef FFI_freeString = void Function(Pointer<Int8>);

//加载库
// DynamicLibrary nativeApi = Platform.isAndroid
//     ? DynamicLibrary.open("libnative_ffi.so")
//     : DynamicLibrary.process();

DynamicLibrary nativeApi = DynamicLibrary.open("flib.dll");

//查找目标函数 - reverse_string
FFI_reverseString faceDetectFileC = nativeApi.lookupFunction<Native_reverseString, FFI_reverseString>("FaceDetectFile");

//查找目标函数 - free_string
FFI_freeString freeFunc = nativeApi.lookupFunction<Native_freeString, FFI_freeString>("free_string");

void main(List<String> args) {
//调用函数
  String value = "1.jpg";
  // toNativeUtf8() 是由 ffi 库提供的API，调用该函数时会在 Native 中分配内存，因此使用完后也需要释放内存。也可以使用 calloc.free() 来释放由 malloc 分配的内存；
  Pointer<Int8> nativeValue = value.toNativeUtf8().cast<Int8>();
  faceDetectFileC(nativeValue);
  calloc.free(nativeValue);

  // print("original.value=$value");
  // print("reverse.value=${reverseValue.cast<Utf8>().toDartString()}");

  // //释放字符串所占用的内存
  // freeFunc(nativeValue); //或者调用 calloc.free(nativeValue);
  // //freeFunc(reverseValue); 或者调用 calloc.free(reverseValue);
  // calloc.free(nativeValue);
}
