#include "ncnn_yolo5face.h"
#include "loghelper.h"
#include "interface.h"

void draw_boxes_with_landmarks_inplace(cv::Mat& mat_inplace, const std::vector<BoxfWithLandmarks>& boxes_kps, bool text = false);