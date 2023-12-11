import 'package:logger/logger.dart';

const String _tag = "face_ui";

var _logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
  ),
);

logTrace(String msg) {
  _logger.t("${DateTime.now().toString()} $_tag :: $msg");
}

LogD(String msg) {
  _logger.d("${DateTime.now().toString()} $_tag :: $msg");
}

logInfo(String msg) {
  _logger.i("${DateTime.now().toString()} $_tag :: $msg");
}

logWarning(String msg) {
  _logger.w("${DateTime.now().toString()} $_tag :: $msg");
}

logError(String msg) {
  _logger.e("${DateTime.now().toString()} $_tag :: $msg");
}

logFatal(String msg) {
  _logger.f("${DateTime.now().toString()} $_tag :: $msg");
}
