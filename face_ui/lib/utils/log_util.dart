import 'package:logger/logger.dart';

const String _tag = "face_ui";

var _logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
  ),
);

logTrace(dynamic msg) {
  _logger.t("${DateTime.now().toString()} $_tag :: $msg");
}

LogD(dynamic msg) {
  _logger.d("${DateTime.now().toString()} $_tag :: $msg");
}

logInfo(dynamic msg) {
  _logger.i("${DateTime.now().toString()} $_tag :: $msg");
}

logWarning(dynamic msg) {
  _logger.w("${DateTime.now().toString()} $_tag :: $msg");
}

logError(dynamic msg) {
  _logger.e("${DateTime.now().toString()} $_tag :: $msg");
}

logFatal(dynamic msg) {
  _logger.f("${DateTime.now().toString()} $_tag :: $msg");
}
