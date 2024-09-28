import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../magnifying_glass.dart';
import 'pinch_barrel.dart';

class GlassHandle extends StatefulWidget {
  /// where the widget image is stored
  final CapturedWidget capturedWidget;

  /// glass parameters
  final GlassParams params;

  /// glass position
  final GlassPosition glassPosition;

  /// border thickness
  final double borderThickness;

  /// border color
  final Color borderColor;

  /// Shadow elevation
  final double elevation;

  /// Shadow offset
  final Offset shadowOffset;

  const GlassHandle({
    super.key,
    required this.capturedWidget,
    required this.params,
    this.glassPosition = GlassPosition.touchPosition,
    required this.borderThickness,
    required this.borderColor,
    required this.elevation,
    required this.shadowOffset,
  });

  @override
  State<GlassHandle> createState() => GlassHandleState();
}

class GlassHandleState extends State<GlassHandle> {
  /// list of uchar to store image under the glass
  late Uint8List subImg;

  /// computed Image widget
  ValueNotifier<Image>? img;

  /// testing compute time
  /// late Stopwatch stopwatch;

  /// starting position to grab [subImg]
  late Offset startPos;

  /// position of the glass when it is not moved by finger
  late Offset stickyPos;

  /// screen size used to place glass when not using GlassPosition.touchPosition
  late Size screenSize;

  @override
  void initState() {
    super.initState();

    /// stopwatch = Stopwatch();
    startPos = Offset.zero;

    PinchBarrel().storeImg(
        widget.capturedWidget.size!.width.toInt(),
        widget.capturedWidget.size!.height.toInt(),
        widget.capturedWidget.byteData!.buffer.asUint8List());

    PinchBarrel()
        .setBmpHeaderSize(widget.params.diameter, widget.params.diameter);
  }

  /// refresh computed image. Used ie when changing parameters
  refreshImage() {
    img!.value = Image.memory(
      PinchBarrel()
          .getSubImage(
              (widget.params.startingPosition!.dx.toInt() -
                      (widget.params.diameter / 2))
                  .toInt(),
              (widget.params.startingPosition!.dy.toInt() -
                      (widget.params.diameter / 2))
                  .toInt(),
              widget.params.diameter)!
          .bmp
          .buffer
          .asUint8List(),
      fit: BoxFit.fill,
      gaplessPlayback: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    /// test frame compute time.
    /// No more tests needed? It is fast enough (usually <20 ms)
    /// WidgetsBinding.instance?.addPersistentFrameCallback((timeStamp) {
    ///   stopwatch.stop();
    ///   print('************** ${stopwatch.elapsedMilliseconds}');
    ///   stopwatch.reset();
    /// });

    screenSize = MediaQuery.sizeOf(context);
    widget.params.startingPosition ??=
        Offset(screenSize.width / 2.0, screenSize.height / 2.0);
    if (img == null) {
      subImg = PinchBarrel()
          .getSubImage(
              (widget.params.startingPosition!.dx -
                      (widget.params.diameter / 2))
                  .toInt(),
              (widget.params.startingPosition!.dy -
                      (widget.params.diameter / 2))
                  .toInt(),
              widget.params.diameter)!
          .bmp;
      img = ValueNotifier<Image>(Image.memory(
        subImg,
        fit: BoxFit.fill,
        gaplessPlayback: true,
      ));
    }

    switch (widget.glassPosition) {
      case GlassPosition.touchPosition:
        startPos = Offset(
            widget.params.startingPosition!.dx - (widget.params.diameter / 2),
            widget.params.startingPosition!.dy - (widget.params.diameter / 2));
        break;
      case GlassPosition.topLeft:
        stickyPos = Offset.zero;
        break;
      case GlassPosition.topRight:
        stickyPos = Offset(
            screenSize.width -
                widget.params.diameter -
                widget.params.padding.right * 2,
            0);
        break;
      case GlassPosition.bottomLeft:
        stickyPos = Offset(
            0,
            screenSize.height -
                widget.params.diameter -
                widget.params.padding.bottom * 2);
        break;
      case GlassPosition.bottomRight:
        stickyPos = Offset(
            screenSize.width -
                widget.params.diameter -
                widget.params.padding.right * 2,
            screenSize.height -
                widget.params.diameter -
                widget.params.padding.bottom * 2);
        break;
    }

    return ValueListenableBuilder<Image>(
        valueListenable: img!,
        builder: (_, image, __) {
          return Transform.translate(
              transformHitTests: true,
              offset: widget.glassPosition == GlassPosition.touchPosition
                  ? startPos
                  : stickyPos,
              child: Listener(
                onPointerDown: (PointerDownEvent e) {
                  if (widget.glassPosition != GlassPosition.touchPosition) {
                    startPos = Offset(
                        e.position.dx - (widget.params.diameter / 2),
                        e.position.dy - (widget.params.diameter / 2));
                  }
                },
                onPointerMove: (PointerMoveEvent e) async {
                  widget.params.startingPosition = e.position;
                  startPos = startPos + e.localDelta;
                  if (!mounted) return;

                  /// stopwatch.start();
                  img!.value = Image.memory(
                    PinchBarrel()
                        .getSubImage(
                          startPos.dx.toInt(),
                          startPos.dy.toInt(),
                          widget.params.diameter,
                        )!
                        .bmp
                        .buffer
                        .asUint8List(),
                    fit: BoxFit.fill,
                    gaplessPlayback: true,
                  );
                },
                child: Padding(
                  padding: widget.params.padding,
                  child: CustomPaint(
                    painter: GlassShadow(
                      borderColor: widget.borderColor,
                      borderThickness: widget.borderThickness,
                      elevation: widget.elevation,
                      shadowOffset: widget.shadowOffset,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        widget.params.diameter.toDouble(),
                      ),
                      child: image,
                    ),
                  ),
                ),
              ));
        });
  }
}

/// Painter class to drop shadow under the glass
class GlassShadow extends CustomPainter {
  /// border thickness
  final double borderThickness;

  /// border color
  final Color borderColor;

  /// Shadow elevation
  final double elevation;

  /// Shadow offset
  final Offset shadowOffset;

  GlassShadow({
    required this.borderThickness,
    required this.borderColor,
    required this.elevation,
    required this.shadowOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    var path = Path();

    path.addOval(
        ui.Rect.fromPoints(Offset.zero, Offset(size.width, size.height)));
    path = path.shift(shadowOffset);

    canvas.drawShadow(path, const Color(0xFF000000), elevation, true);

    canvas.drawOval(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()
          ..strokeWidth = borderThickness
          ..color = borderColor
          ..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
