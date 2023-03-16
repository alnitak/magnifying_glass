import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

/// Bind C functions to Dart
class Interface {
  static Interface? _instance;
  Pointer<Void> Function(double, double)? _setParameter;
  Pointer<Void> Function(int, int)? _setBmpHeaderSize;
  Pointer<Void> Function(double, double)? _setDistortion;
  Pointer<Void> Function(int, int, Pointer<Uint8>)? _storeImg;
  Pointer<Uint8> Function(int, int, int)? _getSubImage;
  Pointer<Void> Function()? _freeImg;

  DynamicLibrary nativeLib = Platform.isAndroid
      ? DynamicLibrary.open("libmagnifying_glass_plugin.so")
      : (Platform.isWindows
          ? DynamicLibrary.open("magnifying_glass_plugin.dll")
          : DynamicLibrary.process());

  Interface._internal() {
    _setBmpHeaderSize = nativeLib
        .lookup<
            NativeFunction<
                Pointer<Void> Function(
                    Int32 width, Int32 height)>>('setBmpHeaderSize')
        .asFunction<Pointer<Void> Function(int width, int height)>();

    _setParameter = nativeLib
        .lookup<
            NativeFunction<
                Pointer<Void> Function(
                    Double distortion, Double magnification)>>('setParameters')
        .asFunction<
            Pointer<Void> Function(double distortion, double magnification)>();

    _setDistortion = nativeLib
        .lookup<
            NativeFunction<
                Pointer<Void> Function(
                    Double distortion, Double magnification)>>('setShiftMat')
        .asFunction<
            Pointer<Void> Function(double distortion, double magnification)>();

    _storeImg = nativeLib
        .lookup<
            NativeFunction<
                Pointer<Void> Function(Int32 width, Int32 height,
                    Pointer<Uint8> imgBuffer)>>('storeImg')
        .asFunction<
            Pointer<Void> Function(
                int width, int height, Pointer<Uint8> imgBuffer)>();

    _getSubImage = nativeLib
        .lookup<
            NativeFunction<
                Pointer<Uint8> Function(Int32 topLeftX, Int32 topLeftY,
                    Int32 width)>>('getSubImage')
        .asFunction<
            Pointer<Uint8> Function(int topLeftX, int topLeftY, int width)>();

    _freeImg = nativeLib
        .lookup<NativeFunction<Pointer<Void> Function()>>('freeImg')
        .asFunction<Pointer<Void> Function()>();
  }

  factory Interface() {
    _instance ??= Interface._internal();
    return _instance!;
  }

  /// this will store the header for a bmp image
  setBmpHeaderSize(int width, int height) {
    _setBmpHeaderSize!(width, height);
  }

  /// just set distortion and magnification parameters
  setParameter(double distortion, double magnification) {
    _setParameter!(distortion, magnification);
  }

  /// set distortion and magnification parameters, and
  /// compute shifting matrices
  setShiftMat(double distortion, double magnification) {
    _setDistortion!(distortion, magnification);
  }

  /// Store the captured widget
  /// [imgBuffer] uncompressed rawRgba image
  storeImg(int width, int height, Uint8List imgBuffer) {
    Pointer<Uint8> buffer = calloc<Uint8>(imgBuffer.length);
    for (var i = 0; i < imgBuffer.length; i++) {
      buffer.elementAt(i).value = imgBuffer[i];
    }
    _storeImg!(width, height, buffer);
  }

  /// get glass image to display with current parameters
  Uint8List getSubImage(int topLeftX, int topLeftY, int width) {
    Pointer<Uint8> buffer = _getSubImage!(topLeftX, topLeftY, width);
    return buffer.asTypedList(width * width * 4 + 122);
  }

  /// free memory
  freeImg() {
    _freeImg!();
  }
}
