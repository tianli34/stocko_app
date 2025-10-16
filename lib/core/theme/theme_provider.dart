import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // 主色调
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color secondaryColor = Color(0xFF03DAC6);
  static const Color errorColor = Color(0xFFB00020);

  // 字体
  static const String fontFamily = 'Roboto';

  // 更新系统UI样式（用于移除底部黑色遮罩）
  static void updateSystemUIOverlay(Brightness brightness) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: brightness == Brightness.light 
            ? Colors.white 
            : const Color(0xFF121212),
        systemNavigationBarIconBrightness: brightness == Brightness.light 
            ? Brightness.dark 
            : Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: brightness == Brightness.light 
            ? Brightness.dark 
            : Brightness.light,
      ),
    );
  }

  // 亮色主题
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
    ),
    fontFamily: fontFamily,

    appBarTheme: const AppBarTheme(
      // backgroundColor: Color.fromARGB(255, 33, 243, 44),
      foregroundColor: Color.fromARGB(255, 33, 124, 243), // 文字和图标颜色
      elevation: 8.0,
      toolbarHeight: 37,

      titleTextStyle: TextStyle(
        color: Color.fromARGB(255, 0, 0, 0), // 显式设置颜色
        fontSize: 19,
      ),
    ),

    // NavigationBar 样式
    navigationBarTheme: NavigationBarThemeData(
      height: 64,
      indicatorColor: primaryColor.withOpacity(0.12),
      backgroundColor: Colors.transparent,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 12, color: Colors.grey.shade700),
      ),
      iconTheme: const WidgetStatePropertyAll(
        IconThemeData(size: 24),
      ),
      surfaceTintColor: Colors.transparent,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: Colors.grey.shade50, // 淡灰色背景
      border: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: errorColor),
      ),
      focusedErrorBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: errorColor, width: 2),
      ),
      floatingLabelBehavior: FloatingLabelBehavior.never,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      constraints: const BoxConstraints(minHeight: 48, maxHeight: 48),
      hintStyle: TextStyle(color: Colors.grey.shade600),
      labelStyle: TextStyle(color: Colors.grey.shade700),
      helperStyle: TextStyle(color: Colors.grey.shade600, fontSize: 12),
      errorStyle: TextStyle(color: errorColor, fontSize: 12),
      suffixIconColor: Colors.grey.shade600,
    ),
  );

  // 暗色主题
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
    ),
    fontFamily: fontFamily,

    navigationBarTheme: NavigationBarThemeData(
      height: 64,
      indicatorColor: primaryColor.withOpacity(0.24),
      backgroundColor: Colors.transparent,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 12, color: Colors.grey.shade300),
      ),
      iconTheme: const WidgetStatePropertyAll(
        IconThemeData(size: 24),
      ),
      surfaceTintColor: Colors.transparent,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: Colors.grey.shade800, // 暗色主题的淡背景
      border: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.shade600),
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.shade600),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: errorColor),
      ),
      focusedErrorBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: errorColor, width: 2),
      ),
      floatingLabelBehavior: FloatingLabelBehavior.never,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      hintStyle: TextStyle(color: Colors.grey.shade400),
      labelStyle: TextStyle(color: Colors.grey.shade300),
      helperStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
      errorStyle: TextStyle(color: errorColor, fontSize: 12),
      suffixIconColor: Colors.grey.shade400,
    ),
  );
}
