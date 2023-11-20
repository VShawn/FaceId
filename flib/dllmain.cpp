#include <iostream>
#include "./sources/ncnn_yolo5face.h"
#include "./sources/loghelper.h"
#include "./sources/interface.h"

std::vector<BoxfWithLandmarks> FaceDetectInner(cv::Mat img);

void draw_boxes_with_landmarks_inplace(cv::Mat& mat_inplace, const std::vector<BoxfWithLandmarks>& boxes_kps, bool text = false)
{
	if (boxes_kps.empty()) return;
	for (const auto& box_kps : boxes_kps)
	{
		if (box_kps.flag)
		{
			// box
			if (box_kps.box.flag)
			{
				cv::rectangle(mat_inplace, box_kps.box.rect(), cv::Scalar(255, 255, 0), 2);
				std::cout << box_kps.box.rect() << std::endl;
				if (box_kps.box.label_text && text)
				{
					std::string label_text(box_kps.box.label_text);
					label_text = label_text + ":" + std::to_string(box_kps.box.score).substr(0, 4);
					cv::putText(mat_inplace, label_text, box_kps.box.tl(), cv::FONT_HERSHEY_SIMPLEX,
						0.6f, cv::Scalar(0, 255, 0), 2);

				}
			}
			// landmarks
			if (box_kps.landmarks.flag && !box_kps.landmarks.points.empty())
			{
				for (const auto& point : box_kps.landmarks.points)
				{
					cv::circle(mat_inplace, point, 2, cv::Scalar(0, 255, 0), -1);
					std::cout << point << std::endl;
				}
			}
		}
	}
}


//static void test_ncnn()
//{
//	std::string param_path = "yolov5face-n-640x640.opt.param"; // yolov5n-face
//	std::string bin_path = "yolov5face-n-640x640.opt.bin";
//	std::string test_img_path = "1.jpg";
//	std::string save_img_path = "2.jpg";
//
//	auto* yolov5face = new YOLO5Face(param_path, bin_path, 1, 320, 320);
//	std::vector<BoxfWithLandmarks> detected_boxes;
//	cv::Mat img_bgr = cv::imread(test_img_path);
//	// 启动计时
//	log_helper::log.timer_start("yolov5f");
//	yolov5face->detect(img_bgr, detected_boxes);
//	draw_boxes_with_landmarks_inplace(img_bgr, detected_boxes);
//	log_helper::log.timer_output("yolov5f");
//	cv::imwrite(save_img_path, img_bgr);
//	std::cout << "NCNN Version Done! Detected Face Num: " << detected_boxes.size() << std::endl;
//
//	delete yolov5face;
//}

int main()
{
	Init(640);
	std::string test_img_path = "1.jpg";
	std::string save_img_path = "2.jpg";
	cv::Mat img_bgr = cv::imread(test_img_path);
	auto boxes = FaceDetectInner(img_bgr);
	draw_boxes_with_landmarks_inplace(img_bgr, boxes);
	log_helper::log.timer_output("yolov5f");
	cv::imwrite(save_img_path, img_bgr);
	std::cout << "NCNN Version Done! Detected Face Num: " << boxes.size() << std::endl;
}