// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stocko_app/app.dart';

void main() {
  // 1. 确保 Flutter 引擎的绑定已经初始化。
  // 这对于在 runApp() 之前调用原生代码或进行异步操作是必需的。
  WidgetsFlutterBinding.ensureInitialized();

  // 2. 运行应用，并使用 ProviderScope 将整个应用包裹起来。
  // ProviderScope 是 Riverpod 的核心，它存储了所有 Provider 的状态。
  // 任何在 ProviderScope 下的小部件都可以访问这些 Provider。
  runApp(const ProviderScope(child: StockoApp()));
}
