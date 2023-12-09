#include <iostream>
#include "utils.h"

void draw_boxes_with_landmarks_inplace(cv::Mat& mat_inplace, const std::vector<BoxfWithLandmarks>& boxes_kps, bool text)
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