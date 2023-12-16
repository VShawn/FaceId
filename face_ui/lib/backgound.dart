import 'dart:async';
import 'dart:io';
import 'dart:isolate';

class IoslatePortSync {
  final SendPort port;

  IoslatePortSync({required this.port});
}

class BackgroundWorker {
  Isolate? _isolate;
  SendPort? _receivePortOfIsolate;

  void _doWork(SendPort mainPort) {
    String msg = "";

    Timer.periodic(const Duration(seconds: 1), (timer) {
      print(DateTime.now().toString() + " " + msg);
    });

    // 这里是 Isolate 内部
    print("new isolate start");
    ReceivePort port = ReceivePort();

    port.listen((message) {
      print("isolate get message: $message");
    });

    mainPort.send(IoslatePortSync(port: port.sendPort));
    sleep(const Duration(seconds: 5));
    mainPort.send("doWork 任务完成");
    print("new isolate end");
  }

  void createIsolate() async {
    // 这里是主线程
    ReceivePort rp = ReceivePort();
    _isolate = await Isolate.spawn(_doWork, rp.sendPort);
    rp.listen((message) {
      print("主线程收到消息：: $message");
      if (message is IoslatePortSync) {
        _receivePortOfIsolate = message.port;
      }
    });
  }

  void killIsolate() async {
    _isolate?.kill(priority: Isolate.immediate);
  }

  void sendToMe(Object object) async {
    _receivePortOfIsolate?.send(object);
  }
}

// void main() {
//   BackgroundWorker worker = BackgroundWorker();
//   worker.createIsolate();
//   // Do other tasks
//   worker.killIsolate();
// }
