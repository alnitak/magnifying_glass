#include <stdint.h>
#include <iostream>
#include <cstdlib>
#include <string>
#include <memory>
#include <stdio.h>
#include <stdlib.h>

#define FFI extern "C" __attribute__((visibility("default"))) __attribute__((used))
#define BYTES_PER_PIXEL 4
#define RGBA32_HEADER_SIZE = 122

int32_t imgWidth  = 0;
int32_t imgHeight = 0;
uint8_t *img;
int32_t subImgWidth  = 0;
int32_t subImgHeight = 0;
uint8_t *subImg;
uint8_t bmpHeader[RGBA32_HEADER_SIZE];

/// alloc subImage and set bmpHeader for the given width and heigth
FFI setBmpHeaderSize(int32_t width, int32_t height) {
    // alloc subImg
    subImgWidth  = width;
    subImgHeight = height;
    if (subImg != nullptr) {
        free(subImg);
    }
    subImg = (uint8_t*)aligned_alloc(
        RGBA32_HEADER_SIZE + width * height * BYTES_PER_PIXEL, sizeof(uint8_t));

    // define bmp header
    int contentSize = width * height;
    memset(bmpHeader, 0, RGBA32_HEADER_SIZE);
    bmpHeader[ 0] = 'B';
    bmpHeader[ 1] = 'M';
    bmpHeader[ 2] = (uint8_t)(  (contentSize + RGBA32_HEADER_SIZE));
    bmpHeader[ 3] = (uint8_t)(  (contentSize + RGBA32_HEADER_SIZE) >> 8);
    bmpHeader[ 4] = (uint8_t)(  (contentSize + RGBA32_HEADER_SIZE) >> 16);
    bmpHeader[ 5] = (uint8_t)(  (contentSize + RGBA32_HEADER_SIZE) >> 24);

    bmpHeader[10] = (uint8_t)(  RGBA32_HEADER_SIZE);
    bmpHeader[11] = (uint8_t)(  RGBA32_HEADER_SIZE >> 8);
    bmpHeader[12] = (uint8_t)(  RGBA32_HEADER_SIZE >> 16);
    bmpHeader[13] = (uint8_t)(  RGBA32_HEADER_SIZE >> 24);

    bmpHeader[14] = (uint8_t)(  108);
    bmpHeader[15] = (uint8_t)(  0);
    bmpHeader[16] = (uint8_t)(  0);
    bmpHeader[17] = (uint8_t)(  0);

    bmpHeader[18] = (uint8_t)(  width);
    bmpHeader[19] = (uint8_t)(  width >> 8);
    bmpHeader[20] = (uint8_t)(  width >> 16);
    bmpHeader[21] = (uint8_t)(  width >> 24);

    bmpHeader[22] = (uint8_t)(  -height);
    bmpHeader[23] = (uint8_t)(  -height >> 8);
    bmpHeader[24] = (uint8_t)(  -height >> 16);
    bmpHeader[25] = (uint8_t)(  -height >> 24);

    bmpHeader[26] = (uint8_t)(  1);
    bmpHeader[27] = (uint8_t)(  0);

    bmpHeader[28] = (uint8_t)(  32);
    bmpHeader[29] = (uint8_t)(  0);

    bmpHeader[30] = (uint8_t)(  3);
    bmpHeader[31] = (uint8_t)(  0);
    bmpHeader[32] = (uint8_t)(  0);
    bmpHeader[33] = (uint8_t)(  0);

    bmpHeader[34] = (uint8_t)(  contentSize);
    bmpHeader[35] = (uint8_t)(  contentSize >> 8);
    bmpHeader[36] = (uint8_t)(  contentSize >> 16);
    bmpHeader[37] = (uint8_t)(  contentSize >> 24);

    bmpHeader[54] = (uint8_t)(  255);
    bmpHeader[55] = (uint8_t)(  0);
    bmpHeader[56] = (uint8_t)(  0);
    bmpHeader[57] = (uint8_t)(  0);

    bmpHeader[58] = (uint8_t)(  0);
    bmpHeader[59] = (uint8_t)(  255);
    bmpHeader[60] = (uint8_t)(  0);
    bmpHeader[61] = (uint8_t)(  0);

    bmpHeader[62] = (uint8_t)(  0);
    bmpHeader[63] = (uint8_t)(  0);
    bmpHeader[64] = (uint8_t)(  255);
    bmpHeader[65] = (uint8_t)(  0);

    bmpHeader[66] = (uint8_t)(  0);
    bmpHeader[67] = (uint8_t)(  0);
    bmpHeader[68] = (uint8_t)(  0);
    bmpHeader[69] = (uint8_t)(  255);

    // copy header at starting memory of subImg
    memcpy(subImg, bmpHeader, RGBA32_HEADER_SIZE);
}

// store image from where subImg will be grabbed
FFI storeImg(int32_t width, int32_t height, uint8_t *imgBuffer) {
    imgWidth  = width;
    imgHeight = height;
    if (img != nullptr) {
        free(img);
    }
    img = (uint8_t*)aligned_alloc(
        width * height * BYTES_PER_PIXEL, sizeof(uint8_t));
    memcpy(img, imgBuffer, width * height * BYTES_PER_PIXEL);
}

FFI getSubImage(int32_t topLeftX, int32_t topLeftY, int32_t width, uint8_t *imgBuffer) {
    uint8_t *startPtr = subImg + RGBA32_HEADER_SIZE;
    for (int i=topLeftY; i<width+topLeftY; i++) {
        memcpy(startPtr, img, width * BYTES_PER_PIXEL);
    }
    imgBuffer = subImg;
}

FFI freeImg() {
    if (subImg != nullptr) {
        free(subImg);
        subImg = nullptr;
    }
    if (img != nullptr) {
        free(img);
        img = nullptr;
    }
}