#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <cmath>
#ifdef __ANDROID__
    #include <android/log.h>
#endif

#ifndef M_PI
#define M_PI 3.1415926535
#endif

#ifdef _WIN32
#define FFI extern "C" __declspec(dllexport)
#pragma warning ( disable : 4310 )
#else
#define FFI extern "C" __attribute__((visibility("default"))) __attribute__((used))
#endif

#define BYTES_PER_PIXEL 4
#define RGBA32_HEADER_SIZE 122

#ifdef __ANDROID__
#define  LOGE(TAG, ...)  __android_log_print(ANDROID_LOG_ERROR, TAG, __VA_ARGS__)
#define  LOGW(TAG, ...)  __android_log_print(ANDROID_LOG_WARN,  TAG, __VA_ARGS__)
#define  LOGD(TAG, ...)  __android_log_print(ANDROID_LOG_DEBUG, TAG, __VA_ARGS__)
#define  LOGI(TAG, ...)  __android_log_print(ANDROID_LOG_INFO,  TAG, __VA_ARGS__)
#endif

int32_t imgWidth  = 0;
int32_t imgHeight = 0;
uint8_t *img = nullptr;
int32_t subImgWidth  = 0;
int32_t subImgHeight = 0;
uint8_t *subImg = nullptr;
char bmpHeader[RGBA32_HEADER_SIZE];
int32_t *shiftingMatX = nullptr;
int32_t *shiftingMatY = nullptr;
double distortionPower = 1.0;
double magnification = 1.0;

// TODO width=height => use only ie 'diameter'


double myAtan2(const double y, const double x)
{
    if (y == 0)
    {
        if (x >= 0)
        {
            return 0.0;
        }
        else
        {
            return M_PI;
        }
    }
    else if (y < 0)
    {
        return (atan2(y, x) + 2 * M_PI);
    }
    else
    {
        return atan2(y, x);
    }
}

FFI void setParameters(double distortion, double mag) {
    distortionPower = distortion;
    magnification = mag;
}

/**
 *
 * @param distortion  about in the range -1.0 ~ 1.0
 */
FFI void setShiftMat(double distortion = 1.0, double mag = 1.0) {
    if (subImgWidth == 0 || subImgHeight == 0) return;
    int32_t center = subImgWidth >> 1; // and lens radius
    double distance;
    double newDistance;

    distortionPower = distortion;
    magnification = mag;
    distortion /= 10000.0;

    // initialize shifting x and y matrices
    if (shiftingMatX != nullptr) {
        free(shiftingMatX);
    }
    if (shiftingMatY != nullptr) {
        free(shiftingMatY);
    }
    shiftingMatX = (int32_t*)calloc(subImgWidth * subImgHeight, sizeof(int32_t));
    shiftingMatY = (int32_t*)calloc(subImgWidth * subImgHeight, sizeof(int32_t));

    int dx, dy;
    double angle;
    for (int_fast32_t y = 0; y < subImgHeight; y++) {
        for (int_fast32_t x = 0; x < subImgWidth; x++) {
            dx = center - x;
            dy = center - y;
            distance = sqrt(dx * dx + dy * dy);
            // calculate distortion only in the lens surface
            if (distance > center) {
                shiftingMatX[y * subImgWidth + x] = 0;
                shiftingMatY[y * subImgWidth + x] = 0;
                continue;
            }

            newDistance = distance * (1 - distortion * distance * distance) * magnification;
            angle = myAtan2(y - center, x - center);

            // test random [-5, 5] pixel shift
            // shiftingMatX[y * subImgWidth + x] = ((rand() % 2)*2 - 1) * 5;
            // shiftingMatY[y * subImgWidth + x] = ((rand() % 2)*2 - 1) * 5;
            shiftingMatX[y * subImgWidth + x] = (int32_t)(dx + (cos(angle) * newDistance));
            shiftingMatY[y * subImgWidth + x] = (int32_t)(dy + (sin(angle) * newDistance));
        }
    }
}

/// alloc subImage and set bmpHeader for the given width and height
FFI void setBmpHeaderSize(int32_t width, int32_t height) {
    // alloc subImg
    subImgWidth  = width;
    subImgHeight = height;
    if (subImg != nullptr) {
        free(subImg);
    }
    subImg = (uint8_t*)calloc(
        RGBA32_HEADER_SIZE + width * height * BYTES_PER_PIXEL, sizeof(uint8_t));

    setShiftMat(distortionPower, magnification);

    // define bmp header
    int contentSize = width * height;

    bmpHeader[0x00] = 'B';
    bmpHeader[0x01] = 'M';

    bmpHeader[0x02] = (char)(  (contentSize + RGBA32_HEADER_SIZE));
    bmpHeader[0x03] = (char)(  (contentSize + RGBA32_HEADER_SIZE) >> 8);
    bmpHeader[0x04] = (char)(  (contentSize + RGBA32_HEADER_SIZE) >> 16);
    bmpHeader[0x05] = (char)(  (contentSize + RGBA32_HEADER_SIZE) >> 24);

    bmpHeader[0x0A] = (char)(  RGBA32_HEADER_SIZE);
    bmpHeader[0x0B] = (char)(  RGBA32_HEADER_SIZE >> 8);
    bmpHeader[0x0C] = (char)(  RGBA32_HEADER_SIZE >> 16);
    bmpHeader[0x0D] = (char)(  RGBA32_HEADER_SIZE >> 24);

    bmpHeader[0x0E] = (char)(  108);
    bmpHeader[0x0F] = (char)(  108 >> 8);
    bmpHeader[0x10] = (char)(  108 >> 16);
    bmpHeader[0x11] = (char)(  108 >> 24);

    bmpHeader[0x12] = (char)(  width);
    bmpHeader[0x13] = (char)(  width >> 8);
    bmpHeader[0x14] = (char)(  width >> 16);
    bmpHeader[0x15] = (char)(  width >> 24);

    bmpHeader[0x16] = (char)(  -height);
    bmpHeader[0x17] = (char)(  -height >> 8);
    bmpHeader[0x18] = (char)(  -height >> 16);
    bmpHeader[0x19] = (char)(  -height >> 24);

    bmpHeader[0x1A] = (char)(  1);
    bmpHeader[0x1B] = (char)(  0);

    bmpHeader[0x1C] = (char)(  32);
    bmpHeader[0x1D] = (char)(  32 >> 8);

    bmpHeader[0x1E] = (char)(  3);
    bmpHeader[0x1F] = (char)(  0);
    bmpHeader[0x20] = (char)(  0);
    bmpHeader[0x21] = (char)(  0);

    bmpHeader[0x22] = (char)(  contentSize);
    bmpHeader[0x23] = (char)(  contentSize >> 8);
    bmpHeader[0x24] = (char)(  contentSize >> 16);
    bmpHeader[0x25] = (char)(  contentSize >> 24);

    bmpHeader[0x36] = (char)(  0x000000ff);
    bmpHeader[0x37] = (char)(  0x000000ff >> 8);
    bmpHeader[0x38] = (char)(  0x000000ff >> 16);
    bmpHeader[0x39] = (char)(  0x000000ff >> 24);

    bmpHeader[0x3A] = (char)(  0x0000ff00);
    bmpHeader[0x3B] = (char)(  0x0000ff00 >> 8);
    bmpHeader[0x3C] = (char)(  0x0000ff00 >> 16);
    bmpHeader[0x3D] = (char)(  0x0000ff00 >> 24);

    bmpHeader[0x3E] = (char)(  0x00ff0000);
    bmpHeader[0x3F] = (char)(  0x00ff0000 >> 8);
    bmpHeader[0x40] = (char)(  0x00ff0000 >> 16);
    bmpHeader[0x41] = (char)(  0x00ff0000 >> 24);

    bmpHeader[0x42] = (char)(  0xff000000);
    bmpHeader[0x43] = (char)(  0xff000000 >> 8);
    bmpHeader[0x44] = (char)(  0xff000000 >> 16);
    bmpHeader[0x45] = (char)(  0xff000000 >> 24);

    // copy header at starting memory of subImg
    memcpy(subImg, bmpHeader, RGBA32_HEADER_SIZE);
}

// store image from where subImg will be grabbed
FFI void storeImg(int32_t width, int32_t height, uint8_t *imgBuffer) {
    imgWidth  = width;
    imgHeight = height;
    if (img != nullptr) {
        free(img);
    }
    img = (uint8_t*)malloc(width * height * BYTES_PER_PIXEL);
    memcpy(img, imgBuffer, width * height * BYTES_PER_PIXEL);
}

// get the pixel from the [image]
uint32_t getPixel(int32_t x, int32_t y) {
    // when x or y ==0 the pixel is transparent because:
    // 1 - the distorsion got out of subImg
    // 2 - is always transparent because in the corner the glass circle is transparent :)
    if ( x <= 0 || x > imgWidth || y <= 0 || y > imgHeight) {
//        LOGD("NATIVE", "getPixel OUT OF BOUNDS  %d  %d", x, y);
        return 0x00000000;
    }
    return (uint32_t)((uint32_t *) img)[y * imgWidth + x];
}

// set the pixel into [subImage]
void setPixel(int32_t x, int32_t y, uint32_t color) {
    uint8_t *cPtr = subImg + (y * subImgWidth + x) * BYTES_PER_PIXEL + RGBA32_HEADER_SIZE;
    uint32_t *iPtr = reinterpret_cast<uint32_t*>(cPtr);
    *iPtr = color;
}

// TODO togliere width e usare subImgWidth
FFI uint8_t *getSubImage(int32_t topLeftX, int32_t topLeftY, int32_t width) {
    int_fast32_t subImgX;
    int_fast32_t subImgY;
    for (int_fast32_t y = topLeftY; y < topLeftY + width; y++) {
        for (int_fast32_t x = topLeftX; x < topLeftX + width; x++) {
            subImgX = x - topLeftX;
            subImgY = y - topLeftY;
            uint32_t c = getPixel(
                    x - shiftingMatX[subImgY * subImgWidth + subImgX],
                    y - shiftingMatY[subImgY * subImgWidth + subImgX]);
            setPixel(subImgX, subImgY, c);
        }
    }
    return subImg;
}

FFI void freeImg() {
    if (subImg != nullptr) {
        free(subImg);
        subImg = nullptr;
    }
    if (img != nullptr) {
        free(img);
        img = nullptr;
    }
    if (shiftingMatX != nullptr) {
        free(shiftingMatX);
        shiftingMatX = nullptr;
    }
    if (shiftingMatY != nullptr) {
        free(shiftingMatY);
        shiftingMatY = nullptr;
    }
}