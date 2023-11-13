#if defined(_MSC_VER) || defined(_WIN32) || defined(_WIN64)
#define _WIN_
#endif

#ifndef API_EXPORT
#ifdef _WIN_
#define API_EXPORT extern "C" _declspec(dllexport)
#define API_IMPORT extern "C" _declspec(dllimport)
#else
#define API_EXPORT extern "C" __attribute__((visibility("default")))
#define API_IMPORT extern "C"
#endif
#endif

API_EXPORT void Init(int size);

API_EXPORT void FaceDetect(unsigned char* const p_data, const int width, const int height, bool isBgr,
	float* const x1,
	float* const y1,
	float* const x2,
	float* const y2,
	float* const f1x,
	float* const f1y,
	float* const f2x,
	float* const f2y,
	float* const f3x,
	float* const f3y,
	float* const f4x,
	float* const f4y,
	float* const f5x,
	float* const f5y,
	int* const count
);