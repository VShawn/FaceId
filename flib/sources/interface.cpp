#include "head.h"
#include <iostream>
#include "loghelper.h"
#include "./sources/ncnn_yolo5face.h"

static YOLO5Face* g_ptr_yolo;

static void InitNcnn(int size)
{
	std::string param_path = "yolov5face-n-640x640.opt.param"; // yolov5n-face
	std::string bin_path = "yolov5face-n-640x640.opt.bin";
	std::string test_img_path = "1.jpg";
	std::string save_img_path = "2.jpg";

	g_ptr_yolo = new YOLO5Face(param_path, bin_path, 1, size, size);

	//delete yolov5face;
}

API_EXPORT void Init(int size)
{
	log_helper::log.init("cpp.log", log_helper::enum_level::debug);
	InitNcnn(size);
}

std::vector<BoxfWithLandmarks> FaceDetectInner(cv::Mat img)
{
	log_helper::log.timer_start("yolov5f");
	std::vector<BoxfWithLandmarks> detected_boxes;
	g_ptr_yolo->detect(img, detected_boxes);
	log_helper::log.timer_output("yolov5f");

	std::vector<BoxfWithLandmarks> results;
	for (const auto& box : detected_boxes)
	{
		if (box.flag && box.landmarks.flag && box.landmarks.points.size() == 5)
		{
			results.emplace_back(box);
		}
	}
	return results;
}

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
)
{
	//vector<uint8_t> buffer(rawBytes, rawBytes + inBytesCount);
	//Mat img = imdecode(buffer, IMREAD_COLOR);

	log_helper::log.timer_start("yolov5f");
	cv::Mat src = cv::Mat(height, width, CV_8UC3, p_data);
	if (isBgr == false) {
		cv::cvtColor(src, src, cv::COLOR_RGB2BGR);
	}
	std::vector<BoxfWithLandmarks> detected_boxes = FaceDetectInner(src);
	int c = std::min((int)detected_boxes.size(), 100);
	*count = c;
	for (size_t i = 0; i < c; i++)
	{
		x1[i] = detected_boxes[i].box.x1;
		y1[i] = detected_boxes[i].box.y1;
		x2[i] = detected_boxes[i].box.x2;
		y2[i] = detected_boxes[i].box.y2;
		f1x[i] = detected_boxes[i].landmarks.points[0].x;
		f1y[i] = detected_boxes[i].landmarks.points[0].y;
		f2x[i] = detected_boxes[i].landmarks.points[1].x;
		f2y[i] = detected_boxes[i].landmarks.points[1].y;
		f3x[i] = detected_boxes[i].landmarks.points[2].x;
		f3y[i] = detected_boxes[i].landmarks.points[2].y;
		f4x[i] = detected_boxes[i].landmarks.points[3].x;
		f4y[i] = detected_boxes[i].landmarks.points[3].y;
		f5x[i] = detected_boxes[i].landmarks.points[4].x;
		f5y[i] = detected_boxes[i].landmarks.points[4].y;
	}
}