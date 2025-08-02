import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// Toast 提示服务
/// 提供统一的消息提示功能
class ToastService {
  /// 显示成功提示
  static void success(String message) {
    show(message, backgroundColor: Colors.green);
  }

  /// 显示错误提示
  static void error(String message) {
    show(
      message,
      length: Toast.LENGTH_LONG,
      backgroundColor: Colors.red,
    );
  }

  /// 显示警告提示
  static void warning(String message) {
    show(message, backgroundColor: Colors.orange);
  }

  /// 显示信息提示
  static void info(String message) {
    show(message, backgroundColor: Colors.blue);
  }

  /// 通用提示方法
  static void show(
    String message, {
    Toast length = Toast.LENGTH_SHORT,
    ToastGravity gravity = ToastGravity.BOTTOM,
    Color backgroundColor = Colors.grey,
    Color textColor = Colors.white,
    double fontSize = 16.0,
  }) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: length,
      gravity: gravity,
      backgroundColor: backgroundColor,
      textColor: textColor,
      fontSize: fontSize,
    );
  }
}