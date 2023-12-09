#include <iostream>
#include "./sources/ncnn_yolo5face.h"
#include "./sources/loghelper.h"
#include "./sources/interface.h"
#include "./sources/utils.h"

std::vector<BoxfWithLandmarks> FaceDetectInner(cv::Mat img);


int main()
{
	Init("yolov5face-n-640x640.opt.bin", 640);
	std::string test_img_path = "1.jpg";
	std::string save_img_path = "2.jpg";
	cv::Mat img_bgr = cv::imread(test_img_path);
	auto boxes = FaceDetectInner(img_bgr);
	draw_boxes_with_landmarks_inplace(img_bgr, boxes);
	log_helper::log.timer_output("yolov5f");
	cv::imwrite(save_img_path, img_bgr);
	std::cout << "NCNN Version Done! Detected Face Num: " << boxes.size() << std::endl;
}