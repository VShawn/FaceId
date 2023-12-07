//
// Created by DefTruth on 2022/1/16.
//

#ifndef LITE_AI_TOOLKIT_NCNN_CV_NCNN_YOLO5FACE_H
#define LITE_AI_TOOLKIT_NCNN_CV_NCNN_YOLO5FACE_H

#include "net.h"
#include <opencv2/opencv.hpp>
#include <unordered_map>

template<typename _T1 = float, typename _T2 = float>
static inline void __assert_type()
{
	static_assert(std::is_pod<_T1>::value && std::is_pod<_T2>::value
		&& std::is_floating_point<_T2>::value
		&& (std::is_integral<_T1>::value || std::is_floating_point<_T1>::value),
		"not support type.");
} // only support for some specific types. check at compile-time.

	// bounding box.
template<typename T1 = float, typename T2 = float>
struct BoundingBoxType
{
	typedef T1 value_type;
	typedef T2 score_type;
	value_type x1;
	value_type y1;
	value_type x2;
	value_type y2;
	score_type score;
	const char* label_text;
	unsigned int label; // for general object detection.
	bool flag; // future use.
	// convert type.
	template<typename O1, typename O2 = score_type>
	BoundingBoxType<O1, O2> convert_type() const;

	template<typename O1, typename O2 = score_type>
	value_type iou_of(const BoundingBoxType<O1, O2>& other) const;

	value_type width() const;

	value_type height() const;

	value_type area() const;

	::cv::Rect rect() const;

	::cv::Point2i tl() const;

	::cv::Point2i rb() const;

	BoundingBoxType() :
		x1(static_cast<value_type>(0)), y1(static_cast<value_type>(0)),
		x2(static_cast<value_type>(0)), y2(static_cast<value_type>(0)),
		score(static_cast<score_type>(0)), label_text(nullptr), label(0),
		flag(false)
	{
		__assert_type<value_type, score_type>();
	}
}; // End BoundingBox.

template class BoundingBoxType<int, float>;
template class BoundingBoxType<float, float>;
template class BoundingBoxType<double, double>;
typedef BoundingBoxType<int, float> Boxi;
typedef BoundingBoxType<float, float> Boxf;
typedef BoundingBoxType<double, double> Boxd;

template<typename T1, typename T2>
inline ::cv::Rect BoundingBoxType<T1, T2>::rect() const
{
	__assert_type<value_type, score_type>();
	auto boxi = this->template convert_type<int>();
	return ::cv::Rect(boxi.x1, boxi.y1, boxi.width(), boxi.height());
}

template<typename T1, typename T2>
inline ::cv::Point2i BoundingBoxType<T1, T2>::tl() const
{
	__assert_type<value_type, score_type>();
	auto boxi = this->template convert_type<int>();
	return ::cv::Point2i(boxi.x1, boxi.y1);
}

template<typename T1, typename T2>
inline ::cv::Point2i BoundingBoxType<T1, T2>::rb() const
{
	__assert_type<value_type, score_type>();
	auto boxi = this->template convert_type<int>();
	return ::cv::Point2i(boxi.x2, boxi.y2);
}

template<typename T1, typename T2>
inline typename BoundingBoxType<T1, T2>::value_type
BoundingBoxType<T1, T2>::width() const
{
	__assert_type<value_type, score_type>();
	return (x2 - x1 + static_cast<value_type>(1));
}

template<typename T1, typename T2>
inline typename BoundingBoxType<T1, T2>::value_type
BoundingBoxType<T1, T2>::height() const
{
	__assert_type<value_type, score_type>();
	return (y2 - y1 + static_cast<value_type>(1));
}

// The effect of instantiating the template std::complex for any type other than float, double, 
// or long double is unspecified.You can define _SILENCE_NONFLOATING_COMPLEX_DEPRECATION_WARNING 
// to suppress this warning
template<typename T1, typename T2>
inline typename BoundingBoxType<T1, T2>::value_type
BoundingBoxType<T1, T2>::area() const
{
	__assert_type<value_type, score_type>();
	return std::abs<value_type>(width() * height());
}

template<typename T1, typename T2>
template<typename O1, typename O2>
inline BoundingBoxType<O1, O2> BoundingBoxType<T1, T2>::convert_type() const
{
	typedef O1 other_value_type;
	typedef O2 other_score_type;
	__assert_type<other_value_type, other_score_type>();
	__assert_type<value_type, score_type>();
	BoundingBoxType<other_value_type, other_score_type> other;
	other.x1 = static_cast<other_value_type>(x1);
	other.y1 = static_cast<other_value_type>(y1);
	other.x2 = static_cast<other_value_type>(x2);
	other.y2 = static_cast<other_value_type>(y2);
	other.score = static_cast<other_score_type>(score);
	other.label_text = label_text;
	other.label = label;
	other.flag = flag;
	return other;
}

template<typename T1, typename T2>
template<typename O1, typename O2>
inline typename BoundingBoxType<T1, T2>::value_type
BoundingBoxType<T1, T2>::iou_of(const BoundingBoxType<O1, O2>& other) const
{
	BoundingBoxType<value_type, score_type> tbox = \
		other.template convert_type<value_type, score_type>();
	value_type inner_x1 = x1 > tbox.x1 ? x1 : tbox.x1;
	value_type inner_y1 = y1 > tbox.y1 ? y1 : tbox.y1;
	value_type inner_x2 = x2 < tbox.x2 ? x2 : tbox.x2;
	value_type inner_y2 = y2 < tbox.y2 ? y2 : tbox.y2;
	value_type inner_h = inner_y2 - inner_y1 + static_cast<value_type>(1.0f);
	value_type inner_w = inner_x2 - inner_x1 + static_cast<value_type>(1.0f);
	if (inner_h <= static_cast<value_type>(0.f) || inner_w <= static_cast<value_type>(0.f))
		return std::numeric_limits<value_type>::min();
	value_type inner_area = inner_h * inner_w;
	return static_cast<value_type>(inner_area / (area() + tbox.area() - inner_area));
}

typedef struct LandmarksType
{
	std::vector<cv::Point2f> points; // x,y
	bool flag;

	LandmarksType() : flag(false)
	{};
} Landmarks;

typedef struct BoxfWithLandmarksType
{
	Boxf box;
	Landmarks landmarks;
	bool flag;

	BoxfWithLandmarksType() : flag(false)
	{};
} BoxfWithLandmarks;



class YOLO5Face
{
private:
	ncnn::Net* net = nullptr;
	const char* log_id = nullptr;
	const char* param_path = nullptr;
	const char* bin_path = nullptr;
	std::vector<const char*> input_names;
	std::vector<const char*> output_names;
	std::vector<int> input_indexes;
	std::vector<int> output_indexes;

private:
	// nested classes
	typedef struct
	{
		int grid0;
		int grid1;
		int stride;
		float width;
		float height;
	} YOLO5FaceAnchor;

	typedef struct
	{
		float ratio;
		int dw;
		int dh;
		bool flag;
	} YOLO5FaceScaleParams;

public:
	explicit YOLO5Face(const std::string& _param_path,
		const std::string& _bin_path,
		unsigned int _num_threads = 1,
		int _input_height = 640,
		int _input_width = 640); //
	~YOLO5Face();

private:
	const unsigned int num_threads; // initialize at runtime.
	// target image size after resize
	const int input_height; // 640
	const int input_width; // 640

	const float mean_vals[3] = { 0.f, 0.f, 0.f }; // RGB
	const float norm_vals[3] = { 1.0f / 255.f, 1.0f / 255.f, 1.0f / 255.f };
	static constexpr const unsigned int nms_pre = 1000;
	static constexpr const unsigned int max_nms = 30000;

	std::vector<unsigned int> strides = { 8, 16, 32 };
	std::unordered_map<unsigned int, std::vector<YOLO5FaceAnchor>> center_anchors;
	bool center_anchors_is_update = false;

protected:
	YOLO5Face(const YOLO5Face&) = delete; //
	YOLO5Face(YOLO5Face&&) = delete; //
	YOLO5Face& operator=(const YOLO5Face&) = delete; //
	YOLO5Face& operator=(YOLO5Face&&) = delete; //

private:
	void print_debug_string();

	void transform(const cv::Mat& mat_rs, ncnn::Mat& in);

	void resize_unscale(const cv::Mat& mat,
		cv::Mat& mat_rs,
		int target_height,
		int target_width,
		YOLO5FaceScaleParams& scale_params);

	// only generate once
	void generate_anchors(unsigned int target_height, unsigned int target_width);

	void generate_bboxes_kps_single_stride(const YOLO5FaceScaleParams& scale_params,
		ncnn::Mat& det_pred,
		unsigned int stride,
		float score_threshold,
		float img_height,
		float img_width,
		std::vector<BoxfWithLandmarks>& bbox_kps_collection);

	void generate_bboxes_kps(const YOLO5FaceScaleParams& scale_params,
		std::vector<BoxfWithLandmarks>& bbox_kps_collection,
		ncnn::Extractor& extractor,
		float score_threshold, float img_height,
		float img_width);

	void nms_bboxes_kps(std::vector<BoxfWithLandmarks>& input,
		std::vector<BoxfWithLandmarks>& output,
		float iou_threshold, unsigned int topk);

public:
	void detect(const cv::Mat& mat, std::vector<BoxfWithLandmarks>& detected_boxes_kps,
		float score_threshold = 0.25f, float iou_threshold = 0.45f,
		unsigned int topk = 400);

};

#endif //LITE_AI_TOOLKIT_NCNN_CV_NCNN_YOLO5FACE_H
