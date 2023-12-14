import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:system_tray/system_tray.dart';

/// https://pub.dev/packages/system_tray
class TrayHelper {
  final String iconWinPath;
  final String iconOtherPngPath;
  final SystemTray systemTray = SystemTray();

  /// timer for flash
  Timer? _timer;

  void dispose() async {
    _timer?.cancel();
    await systemTray.destroy();
  }

  /// 'assets/images/null.ico'
  TrayHelper({required this.iconWinPath, required this.iconOtherPngPath});

  /// 输入鼠标左键点击后要干啥（一般是显示窗口），右键默认为弹出菜单
  void createTray(Function? leftClickCallBack) async {
    await systemTray.initSystemTray(title: "", iconPath: Platform.isWindows ? iconWinPath : iconOtherPngPath, toolTip: null);
    // handle system tray event
    systemTray.registerSystemTrayEventHandler((eventName) {
      debugPrint("eventName: $eventName");
      if (eventName == kSystemTrayEventClick) {
        Platform.isWindows ? leftClickCallBack?.call() : systemTray.popUpContextMenu();
      } else if (eventName == kSystemTrayEventRightClick) {
        Platform.isWindows ? systemTray.popUpContextMenu() : leftClickCallBack?.call();
      }
    });
  }

  /// demo
  /// ```// create context menu
  /// final Menu menu = Menu();
  /// await menu.buildFrom([
  ///   MenuItemLabel(label: 'Show', onClicked: (menuItem) => appWindow.show()),
  ///   MenuItemLabel(label: 'Hide', onClicked: (menuItem) => appWindow.hide()),
  ///   MenuItemLabel(label: 'Exit', onClicked: (menuItem) => appWindow.close()),
  /// ]);```
  void setMenu(Menu menu) async {
    await systemTray.setContextMenu(menu);
  }

  void setToolTip(String title, String tooltip) async {
    await systemTray.setTitle(title);
    await systemTray.setToolTip(tooltip);
  }

  void flash(String title, String content) async {}
  void stopFlash() async {}
}
