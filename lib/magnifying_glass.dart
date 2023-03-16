library magnifying_glass;

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'src/glass.dart';
import 'src/interface.dart';

/// Controller to access glass state and parameters
class MagnifyingGlassController {
  VoidCallback? _openGlass;
  VoidCallback? _closeGlass;
  Function(double distortion, double magnification)? _setDistortion;
  Function(int diameter)? _setDiameter;

  _setController(
    VoidCallback openGlass,
    VoidCallback closeGlass,
    Function(double distortion, double magnification) setDistortion,
    Function(int diameter) setDiameter,
  ) {
    _openGlass = openGlass;
    _closeGlass = closeGlass;
    _setDistortion = setDistortion;
    _setDiameter = setDiameter;
  }

  /// call to open  the glass
  openGlass() {
    if (_openGlass != null) _openGlass!();
  }

  /// call to close the glass
  closeGlass() {
    if (_closeGlass != null) _closeGlass!();
  }

  /// set distortion and magnification
  setDistortion(double distortion, double magnification) {
    if (_setDistortion != null) _setDistortion!(distortion, magnification);
  }

  /// set the diameter
  setDiameter(int diameter) {
    if (_setDiameter != null) _setDiameter!(diameter);
  }
}

/// class to store captured widget
class CapturedWidget {
  ByteData? byteData; // uncompressed 32bit RGBA image data
  Size? size;
}

/// enum to define glass beavior
/// [touchPosition] the glass moves under the finger
/// [topLeft] the glass is sticky in the top left of the child
/// [topRight] the glass is sticky in the top right of the child
/// [bottomLeft] the glass is sticky in the bottom left of the child
/// [bottomRight] the glass is sticky in the bottom right of the child
enum GlassPosition {
  touchPosition,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

/// Glass parameter
class GlassParams {
  /// start position where the glass is positioned
  Offset? startingPosition;

  /// glass diameter
  int diameter;

  /// glass magnification.
  /// 1 means no magnification
  /// >1 means magnification
  /// <1 means shrinking
  double magnification;

  /// Barrel/Pincushion distortion power
  /// 0 means no distortion
  double distortion;

  /// Padding surrounding the glass to enlarge touching area
  final EdgeInsets padding;

  GlassParams(
      {this.startingPosition,
      required this.diameter,
      this.magnification = 1.0,
      this.distortion = 1.0,
      this.padding = EdgeInsets.zero})
      : assert(diameter >= 10, 'Glass diameter should be almost 10');
}

/// main widget
class MagnifyingGlass extends StatefulWidget {
  /// child that will be used by the glass
  final Widget child;

  /// glass parameters
  final GlassParams glassParams;

  /// glass controller
  final MagnifyingGlassController controller;

  /// glass position
  final GlassPosition? glassPosition;

  /// border thickness
  final double borderThickness;

  /// border color
  final Color borderColor;

  const MagnifyingGlass({
    Key? key,
    required this.controller,
    required this.glassParams,
    required this.child,
    this.glassPosition = GlassPosition.touchPosition,
    this.borderThickness = 0.0,
    this.borderColor = Colors.transparent,
  }) : super(key: key);

  @override
  State<MagnifyingGlass> createState() => _MagnifyingGlassState();
}

class _MagnifyingGlassState extends State<MagnifyingGlass> {
  /// key used to grab the image
  late GlobalKey _childKey;

  /// key used to refresh GlassHandle
  late GlobalKey<GlassHandleState> _glassHandle;

  /// used to capture widget image
  final Completer<bool> completer = Completer<bool>();

  /// where the widget image is stored
  late CapturedWidget _captured;

  /// capture image retry counter
  int _captureRetry = 0;

  /// state of the glass
  bool _isGlassVisible = false;

  @override
  Widget build(BuildContext context) {
    widget.controller
        ._setController(_openGlass, _closeGlass, _setDistortion, _setDiameter);
    Interface().setParameter(
        widget.glassParams.distortion, widget.glassParams.magnification);
    Widget child;
    if (_isGlassVisible) {
      child = Stack(children: [
        widget.child,
        GlassHandle(
          key: _glassHandle,
          capturedWidget: _captured,
          params: widget.glassParams,
          glassPosition: widget.glassPosition!,
          borderColor: widget.borderColor,
          borderThickness: widget.borderThickness,
        ),
      ]);
    } else {
      child = widget.child;
    }

    return RepaintBoundary(
      key: _childKey,
      child: child,
    );
  }

  @override
  void initState() {
    super.initState();
    widget.controller
        ._setController(_openGlass, _closeGlass, _setDistortion, _setDiameter);
    _captured = CapturedWidget();
    _childKey = GlobalKey();
    _glassHandle = GlobalKey();
  }

  /// TODO: find a better way to capture the widget when the issue will
  /// be fixed? https://github.com/flutter/flutter/issues/22308
  Future<bool> _captureWidget(GlobalKey widgetKey) async {
    ui.Image? image;

    try {
      RenderRepaintBoundary? boundary =
          widgetKey.currentContext?.findRenderObject() as RenderRepaintBoundary;
      if (_captureRetry > 15) completer.complete(false);

      image = await boundary.toImage();

      _captured.byteData =
          await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      _captured.size = Size(image.width.toDouble(), image.height.toDouble());

      if (_captureRetry > 1) {
        completer.complete(true);
      } else {
        Timer(const Duration(milliseconds: 20), () {
          if (!completer.isCompleted) {
            _captureWidget(widgetKey);
          }
        });
        _captureRetry++;
      }
    } catch (exception) {
      _captureRetry++;
      if (_captureRetry > 15) completer.complete(false);
      //Delay is required. See Issue https://github.com/flutter/flutter/issues/22308
      Timer(const Duration(milliseconds: 20), () {
        if (!completer.isCompleted) {
          _captureWidget(widgetKey);
        }
      });
    }
    return completer.future;
  }

  /// sets glass distorion and magnification
  _setDistortion(double distortion, double magnification) {
    Interface().setShiftMat(distortion, magnification);
    widget.glassParams.distortion = distortion;
    widget.glassParams.magnification = magnification;
    _glassHandle.currentState?.refreshImage();
  }

  /// sets glass diameter
  _setDiameter(int diameter) {
    widget.glassParams.diameter = diameter;
    Interface().setBmpHeaderSize(
        widget.glassParams.diameter, widget.glassParams.diameter);
    _glassHandle.currentState?.refreshImage();
    setState(() {});
  }

  /// open the glass. If already visible then close it
  _openGlass() {
    if (_isGlassVisible) {
      _closeGlass();
      setState(() {});
      return;
    }
    _captureRetry = 0;
    _captureWidget(_childKey).then((_) {
      if (!_) {
        _captured.size = null;
        _captured.byteData = null;
      } else {
        setState(() {
          _isGlassVisible = true;
        });
      }
    });
  }

  /// close the glass
  _closeGlass() {
    if (!_isGlassVisible) return;
    setState(() {
      _isGlassVisible = false;
    });
  }
}
