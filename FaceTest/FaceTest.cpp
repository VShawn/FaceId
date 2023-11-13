#include <iostream>
#include "./interface.h"
#include <opencv2/opencv.hpp>

int main()
{
	Init(640);
	float x1[100];
	float y1[100];
	float x2[100];
	float y2[100];
	float f1x[100];
	float f1y[100];
	float f2x[100];
	float f2y[100];
	float f3x[100];
	float f3y[100];
	float f4x[100];
	float f4y[100];
	float f5x[100];
	float f5y[100];
	int count = 0;

	std::string test_img_path = "1.jpg";
	cv::Mat img_bgr = cv::imread(test_img_path);

	uchar* camData = new uchar[img_bgr.total() * 3];
	FaceDetect(camData, img_bgr.size().width, img_bgr.size().height);
}