#include <iostream>
#include "./interface.h"
#include <opencv2/opencv.hpp>

void draw_boxes_with_landmarks_inplace(cv::Mat& mat_inplace,
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
	const int count)
{
	if (count <= 0) return;
	for (int i = 0; i < count; i++)
	{
		auto x = 100 * (i + 1);
		cv::rectangle(mat_inplace, cv::Rect(x1[i], y1[i], x2[i] - x1[i] + 1, y2[i] - y1[i] + 1), cv::Scalar(x, x, 0), 2);
		cv::circle(mat_inplace, cv::Point2f(f1x[i], f1y[i]), 2, cv::Scalar(0, x, 0), -1);
		cv::circle(mat_inplace, cv::Point2f(f2x[i], f2y[i]), 2, cv::Scalar(0, x, 0), -1);
		cv::circle(mat_inplace, cv::Point2f(f3x[i], f3y[i]), 2, cv::Scalar(0, x, 0), -1);
		cv::circle(mat_inplace, cv::Point2f(f4x[i], f4y[i]), 2, cv::Scalar(0, x, 0), -1);
		cv::circle(mat_inplace, cv::Point2f(f5x[i], f5y[i]), 2, cv::Scalar(0, x, 0), -1);
		std::cout << x1[i] << " " << y1[i] << " " << x2[i] << " " << y2[i] << std::endl;
		std::cout << f1x[i] << ", " << f1y[i] << std::endl;
		std::cout << f2x[i] << ", " << f2y[i] << std::endl;
		std::cout << f3x[i] << ", " << f3y[i] << std::endl;
		std::cout << f4x[i] << ", " << f4y[i] << std::endl;
		std::cout << f5x[i] << ", " << f5y[i] << std::endl;
	}
}

int main()
{
	std::string test_img_path = "1.jpg";
	std::string save_img_path = "2.jpg";

	Init(320);

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

	cv::Mat img_bgr = cv::imread(test_img_path);

	uchar* arr = img_bgr.isContinuous() ? img_bgr.data : img_bgr.clone().data;
	uint length = img_bgr.total() * img_bgr.channels();
	FaceDetect(arr, img_bgr.size().width, img_bgr.size().height, true,
		x1, y1,
		x2, y2,
		f1x, f1y,
		f2x, f2y,
		f3x, f3y,
		f4x, f4y,
		f5x, f5y,
		&count);

	std::cout << "NCNN Version Done! Detected Face Num: " << count << std::endl;

	draw_boxes_with_landmarks_inplace(img_bgr,
		x1, y1,
		x2, y2,
		f1x, f1y,
		f2x, f2y,
		f3x, f3y,
		f4x, f4y,
		f5x, f5y,
		count);
	cv::imwrite(save_img_path, img_bgr);
}