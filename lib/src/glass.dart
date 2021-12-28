import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'dart:ui' as ui;

import '../magnifying_glass.dart';
import 'interface.dart';

class GlassHandle extends StatefulWidget {
  // where the widget image is stored
  final CapturedWidget capturedWidget;

  // glass parameters
  final GlassParams params;

  // glass position
  final GlassPosition glassPosition;

  const GlassHandle({
    Key? key,
    required this.capturedWidget,
    required this.params,
    this.glassPosition = GlassPosition.touchPosition,
  }) : super(key: key);

  @override
  State<GlassHandle> createState() => GlassHandleState();
}

class GlassHandleState extends State<GlassHandle> {
  // list of uchar to store image under the glass
  late Uint8List subImg;

  // computed Image widget
  ValueNotifier<Image>? img;

  // testing compute time
  // late Stopwatch stopwatch;

  // starting position to grab [subImg]
  late Offset startPos;

  // position of the glass when it is not moved by finger
  late Offset stickyPos;

  // screen size used to place glass when not using GlassPosition.touchPosition
  late Size screenSize;

  @override
  void initState() {
    super.initState();

    // stopwatch = Stopwatch();
    startPos = Offset.zero;

    Interface().storeImg(
      widget.capturedWidget.size!.width.toInt(),
      widget.capturedWidget.size!.height.toInt(),
        widget.capturedWidget.byteData!.buffer.asUint8List());

    Interface().setBmpHeaderSize(
        widget.params.diameter,
        widget.params.diameter);
  }

  @override
  void dispose() {
    Interface().freeImg();
    super.dispose();
  }

  /// refresh computed image. Used ie when changing parameters
  refreshImage() {
    img!.value = Image.memory(
      Interface().getSubImage(
          (widget.params.startingPosition!.dx.toInt() - (widget.params.diameter/2)).toInt(),
          (widget.params.startingPosition!.dy.toInt() - (widget.params.diameter/2)).toInt(),
          widget.params.diameter),
      fit: BoxFit.fill,
      gaplessPlayback: true,);
  }

  @override
  Widget build(BuildContext context) {

    // test frame compute time.
    // No more tests. It is fast enough (usually <20 ms)
    // WidgetsBinding.instance?.addPersistentFrameCallback((timeStamp) {
    //   stopwatch.stop();
    //   print('************** ${stopwatch.elapsedMilliseconds}');
    //   stopwatch.reset();
    // });

    screenSize = MediaQuery.of(context).size;
    widget.params.startingPosition ??=
        Offset(screenSize.width / 2.0, screenSize.height / 2.0);
    if (img == null) {
      subImg = Interface().getSubImage(
          (widget.params.startingPosition!.dx - (widget.params.diameter/2)).toInt(),
          (widget.params.startingPosition!.dy - (widget.params.diameter/2)).toInt(),
          widget.params.diameter);
      img = ValueNotifier<Image>(Image.memory(
          subImg,
          fit: BoxFit.fill));
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
            screenSize.width - widget.params.diameter - widget.params.padding.right*2,
            0);
        break;
      case GlassPosition.bottomLeft:
        stickyPos = Offset(
            0,
            screenSize.height - widget.params.diameter - widget.params.padding.bottom*2);
        break;
      case GlassPosition.bottomRight:
        stickyPos = Offset(
            screenSize.width - widget.params.diameter - widget.params.padding.right*2,
            screenSize.height - widget.params.diameter - widget.params.padding.bottom*2);
        break;
    }

    return ValueListenableBuilder<Image>(
        valueListenable: img!,
        builder: (_, _img, __) {

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
                // stopwatch.start();
                img!.value = Image.memory(
                    Interface().getSubImage(
                        startPos.dx.toInt(),
                        startPos.dy.toInt(),
                        widget.params.diameter),
                    fit: BoxFit.fill,
                    gaplessPlayback: true,);
              },
              child: Padding(
                padding: widget.params.padding,
                child: CustomPaint(
                  painter: GlassShadow(),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(widget.params.diameter.toDouble()),
                    child: _img
                  ),
                ),
              ),
          ));
      }
    );
  }

}


/// Painter class to drop shadow under the glass
class GlassShadow extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var path = Path();
    path.addOval(ui.Rect.fromPoints(Offset.zero, Offset(size.width, size.height)));
    canvas.drawShadow(path, const Color(0xFF000000), 8, false);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

}