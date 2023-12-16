#include "head.h"
#include <iostream>
#include "loghelper.h"
#include "ncnn_yolo5face.h"
#include "utils.h"

static YOLO5Face* g_ptr_yolo = nullptr;

// 初始化模型，返回成功失败
static bool InitNcnn(std::string path, int size)
{
	if (g_ptr_yolo != nullptr)
		delete g_ptr_yolo;

	// 如果 path 以 .bin 或 .param 结尾，则去掉后缀
	if (path.size() > 4 && path.substr(path.size() - 4) == ".bin")
		path = path.substr(0, path.size() - 4);
	else if (path.size() > 6 && path.substr(path.size() - 6) == ".param")
		path = path.substr(0, path.size() - 6);

	std::string param_path = path + ".param"; // yolov5n-face
	std::string bin_path = path + ".bin";

	LOG_DEBUG("YOLO5Face INIT");
	g_ptr_yolo = new YOLO5Face(param_path, bin_path, 1, size, size);
	LOG_DEBUG("YOLO5Face INIT END");
}

static void ReleaseNcnn()
{
	if (g_ptr_yolo != nullptr)
		delete g_ptr_yolo;
}

// 初始化，返回成功失败，输入模型路径和检测尺寸
API_EXPORT int Init(const char* const filePath, int size)
{
	log_helper::log.init("cpp.log", log_helper::enum_level::debug);
	return InitNcnn(std::string(filePath), size);
}

API_EXPORT void Release()
{
	ReleaseNcnn();
}

std::vector<BoxfWithLandmarks> FaceDetectInner(cv::Mat img)
{
	std::vector<BoxfWithLandmarks> results;
	log_helper::log.timer_start("yolov5f");
	std::vector<BoxfWithLandmarks> detected_boxes;
	g_ptr_yolo->detect(img, detected_boxes);
	log_helper::log.timer_output("yolov5f");

	for (const auto& box : detected_boxes)
	{
		if (box.flag && box.landmarks.flag && box.landmarks.points.size() == 5)
		{
			results.emplace_back(box);
		}
	}
	return results;
}

// 人脸检测, 传入图片的 RGB 二进制数据，返回人脸框坐标和5个关键点坐标
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
	if (g_ptr_yolo == nullptr)
	{
		LOG_FATAL("NOT INIT!!!!");
		return;
	}

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




API_EXPORT void FaceDetectFile(const char* const filePath,
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
	int* const count)
{
	if (g_ptr_yolo == nullptr)
	{
		LOG_FATAL("NOT INIT!!!!");
		return;
	}

	LOG_DEBUG("FaceDetectFile");
	//vector<uint8_t> buffer(rawBytes, rawBytes + inBytesCount);
	//Mat img = imdecode(buffer, IMREAD_COLOR);

	cv::Mat src = cv::imread(filePath);
	LOG_DEBUG("src = %d, %d", src.cols, src.rows);
	if (src.rows != g_ptr_yolo->input_height || src.cols != g_ptr_yolo->input_width)
	{
		float w_r = (float)g_ptr_yolo->input_width / (float)src.cols;
		float h_r = (float)g_ptr_yolo->input_height / (float)src.rows;
		float r = std::min(w_r, h_r);
		int new_unpad_w = static_cast<int>((float)src.cols * r); // floor
		int new_unpad_h = static_cast<int>((float)src.rows * r); // floor
		cv::resize(src, src, cv::Size(new_unpad_w, new_unpad_h));
		LOG_DEBUG("src resize -> %d, %d", src.cols, src.rows);
	}
	std::vector<BoxfWithLandmarks> detected_boxes = FaceDetectInner(src);
	draw_boxes_with_landmarks_inplace(src, detected_boxes);
	cv::imwrite(filePath, src);

	int c = std::min((int)detected_boxes.size(), 100);
	LOG_DEBUG("count = %d", c);
	for (size_t i = 0; i < c; i++)
	{
		x1[i] = detected_boxes[i].box.x1;
		LOG_DEBUG("x1[%d] = %f", i, x1[i]);
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
	*count = c;
}