# Stocko App - 库存管理系统

一个使用 Flutter 构建的现代化库存管理应用，支持产品管理、库存追踪和报表功能。

## 功能特性

- 📦 **产品管理**: 添加、编辑、删除和查看产品信息
- 📊 **库存追踪**: 实时监控库存数量和状态
- 🏷️ **分类管理**: 灵活的产品分类系统
- 📱 **响应式设计**: 支持手机、平板和桌面端
- 🌙 **深色模式**: 自动适配系统主题
- 💾 **本地存储**: 使用 SQLite 本地数据库

## 技术栈

- **框架**: Flutter 3.8+
- **状态管理**: Riverpod 2.6+
- **数据库**: Drift (SQLite)
- **路由**: Go Router
- **UI**: Material Design 3

## 项目结构

```
lib/
├── core/                   # 核心功能
│   ├── constants/         # 常量定义
│   ├── database/          # 数据库配置
│   ├── router/            # 路由配置
│   ├── theme/             # 主题配置
│   └── shared_widgets/    # 共享组件
├── features/              # 功能模块
│   └── product/           # 产品管理模块
│       ├── application/   # 业务逻辑层
│       ├── data/         # 数据访问层
│       ├── domain/       # 领域模型层
│       └── presentation/ # 表现层
├── app.dart              # 应用入口配置
└── main.dart             # 应用启动入口
```

## 快速开始

### 环境要求

- Flutter SDK 3.8.0 或更高版本
- Dart SDK 3.8.0 或更高版本

### 安装依赖

```bash
flutter pub get
```

### 生成代码

```bash
flutter packages pub run build_runner build
```

### 运行应用

```bash
flutter run
```

### 运行测试

```bash
flutter test
```

## 开发指南

### 添加新功能

1. 在 `features/` 目录下创建新的功能模块
2. 遵循 Clean Architecture 分层结构
3. 使用 Riverpod 进行状态管理
4. 编写相应的测试用例

### 数据库变更

1. 修改 `core/database/` 中的表定义
2. 运行 `flutter packages pub run build_runner build` 生成代码
3. 更新数据库版本号

## 贡献指南

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开 Pull Request

## 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。
