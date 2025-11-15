# Implementation Plan

- [x] 1. 创建核心脚本文件





  - 在项目根目录创建 `copyright_extractor.js`
  - 导入 Node.js 模块（fs, path）
  - 定义基本配置常量（输出目录、每页行数等）
  - _Requirements: 1.1, 1.2_

- [x] 2. 实现文件扫描和选择功能





  - 递归扫描 lib 目录下所有 .dart 文件
  - 排除 .g.dart 和 .freezed.dart 生成文件
  - 按优先级排序（入口文件 > 核心模块 > 业务模块 > UI组件）
  - 计算每个文件的行数
  - _Requirements: 2.1, 2.2, 2.3, 2.5_

- [x] 3. 实现代码提取和格式化





  - 读取选中的源文件内容（UTF-8编码）
  - 为每个文件添加路径标识注释
  - 合并所有代码内容
  - 添加错误处理（跳过无法读取的文件）
  - _Requirements: 1.3, 1.4, 3.1, 3.2, 3.3_

- [x] 4. 生成前30页和后30页文档






  - 将合并的代码分为前1500行和后1500行
  - 如果总代码不足3000行则全部包含
  - 添加文档标题和分隔符
  - 保存到 soft_copyright_temp/source_code_copyright.txt
  - _Requirements: 1.1, 3.1, 3.2, 3.3, 3.4, 4.1, 4.2, 4.3, 4.4_

- [ ] 5. 生成处理报告
  - 统计扫描文件数、选择文件数、总行数
  - 列出所有提取的文件及其行数
  - 记录输出文件路径
  - 保存到 soft_copyright_temp/extraction_report.txt
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

- [ ] 6. 运行和验证
  - 执行 `node copyright_extractor.js`
  - 检查输出文件格式和内容
  - 验证前后各1500行代码连续完整
  - 确认报告信息准确
  - _Requirements: 3.1, 3.2, 3.3, 3.6, 5.1, 5.2, 5.3, 5.4, 5.5_
