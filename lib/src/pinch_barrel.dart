import 'dart:math';
import 'dart:typed_data';

import 'package:magnifying_glass/src/bmp_header.dart';

/// Class to manage lens effect with PinchBarrel
class PinchBarrel {
  static PinchBarrel? _instance;
  int imgWidth = 0;
  int imgHeight = 0;
  Int32List shiftingMatX = Int32List(0);
  Int32List shiftingMatY = Int32List(0);
  int subImgWidth = 0;
  int subImgHeight = 0;
  double distortionPower = 1.0;
  double magnification = 1.0;
  Bmp32Header? img;
  Bmp32Header? subImg;

  PinchBarrel._internal();

  factory PinchBarrel() {
    _instance ??= PinchBarrel._internal();
    return _instance!;
  }

  /// just set distortion and magnification parameters
  setParameters(double distortion, double mag) {
    distortionPower = distortion;
    magnification = mag;
  }

  /// set distortion and magnification parameters, and
  /// compute shifting matrices
  setShiftMat(double distortion, double mag) {
    if (subImgWidth == 0 || subImgHeight == 0) return;
    int center = subImgWidth >> 1; // and lens radius
    double distance;
    double newDistance;

    distortionPower = distortion;
    magnification = mag;
    distortion /= 10000.0;

    // initialize shifting x and y matrices
    shiftingMatX = Int32List(subImgWidth * subImgHeight);
    shiftingMatY = Int32List(subImgWidth * subImgHeight);

    int dx, dy;
    double angle;
    int pos;
    for (int y = 0; y < subImgHeight; y++) {
      for (int x = 0; x < subImgWidth; x++) {
        pos = y * subImgWidth + x;
        dx = center - x;
        dy = center - y;
        distance = sqrt(dx * dx + dy * dy);
        // calculate distortion only in the lens surface
        if (distance > center) {
          shiftingMatX[pos] = 0;
          shiftingMatY[pos] = 0;
          continue;
        }

        newDistance =
            distance * (1 - distortion * distance * distance) * magnification;
        angle = atan2(y - center, x - center);

        shiftingMatX[pos] = (dx + (cos(angle) * newDistance)).toInt();
        shiftingMatY[pos] = (dy + (sin(angle) * newDistance)).toInt();
      }
    }
  }

  /// this will store the header for a lens bmp image
  setBmpHeaderSize(int width, int height) {
    subImgWidth = width;
    subImgHeight = height;
    subImg = Bmp32Header.setHeader(width, height);
    setShiftMat(distortionPower, magnification);
  }

  // store background image
  void storeImg(int width, int height, Uint8List imgBuffer) {
    imgWidth = width;
    imgHeight = height;
    img = Bmp32Header.setHeader(width, height);
    img!.storeBitmap(imgBuffer);
  }

  Bmp32Header? getSubImage(int topLeftX, int topLeftY, int width) {
    if (img == null) return null;

    subImg!.clearBitmap();
    int toX =
        topLeftX + subImgWidth < imgWidth ? topLeftX + subImgWidth : imgWidth;
    int toY =
        topLeftY + subImgWidth < imgHeight ? topLeftY + subImgWidth : imgHeight;
    int subImgX;
    int subImgY;
    int imgX;
    int imgY;
    int pxSrc;
    int pxDest;
    for (int y = topLeftY; y < toY; y++) {
      for (int x = topLeftX; x < toX; x++) {
        subImgX = x - topLeftX;
        subImgY = y - topLeftY;
        imgX = x - shiftingMatX[subImgY * subImgWidth + subImgX];
        imgY = y - shiftingMatY[subImgY * subImgWidth + subImgX];
        pxSrc = 122 + ((imgY * imgWidth + imgX) << 2);
        pxDest = 122 + ((subImgY * subImgWidth + subImgX) << 2);
        if (pxSrc < 0 || pxSrc > img!.bmp.length - 4) continue;

        subImg!.bmp[pxDest] = img!.bmp[pxSrc];
        subImg!.bmp[pxDest + 1] = img!.bmp[pxSrc + 1];
        subImg!.bmp[pxDest + 2] = img!.bmp[pxSrc + 2];
        subImg!.bmp[pxDest + 3] = img!.bmp[pxSrc + 3];
      }
    }

    return subImg;
  }
}
