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