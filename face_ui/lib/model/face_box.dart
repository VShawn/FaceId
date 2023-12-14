class FaceBox {
  final double x1;
  final double y1;

  final double x2;
  final double y2;

  double get width => x2 - x1;
  double get height => y2 - y1;
  double get area => width * height;

  final double eye1X;
  final double eye1Y;

  final double eye2X;
  final double eye2Y;

  final double noseX;
  final double noseY;

  final double mouth1X;
  final double mouth1Y;

  final double mouth2X;
  final double mouth2Y;

  final int faceId;

  FaceBox(
      {required this.x1,
      required this.y1,
      required this.x2,
      required this.y2,
      required this.eye1X,
      required this.eye1Y,
      required this.eye2X,
      required this.eye2Y,
      required this.noseX,
      required this.noseY,
      required this.mouth1X,
      required this.mouth1Y,
      required this.mouth2X,
      required this.mouth2Y,
      required this.faceId});

  // 实现打印方法
  @override
  String toString() {
    return 'FaceResult{x1: $x1, y1: $y1, x2: $x2, y2: $y2, faceId: $faceId},  width = $width, height = $height, area = $area';
  }
}
