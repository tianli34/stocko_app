# Design Document

## Overview

本设计文档描述了软件著作权源代码材料准备系统的技术实现方案。该系统将从Flutter项目中提取源代码，并生成符合软件著作权登记要求的程序鉴别材料。

根据项目分析，当前项目包含约397个Dart源文件，代码量充足。系统将采用基于Node.js的脚本方案，使用内置模块实现自动化的源代码提取、格式化和文档生成，无需安装额外依赖。

## Architecture

### System Components

```
┌─────────────────────────────────────────────────────────┐
│                   Main Controller                        │
│              (copyright_extractor.py)                    │
└────────────┬────────────────────────────────────────────┘
             │
             ├──────────────┬──────────────┬──────────────┐
             │              │              │              │
             ▼              ▼              ▼              ▼
    ┌────────────┐  ┌────────────┐ ┌────────────┐ ┌────────────┐
    │   File     │  │   Code     │ │  Document  │ │  Report    │
    │  Scanner   │  │ Formatter  │ │ Generator  │ │ Generator  │
    └────────────┘  └────────────┘ └────────────┘ └────────────┘
             │              │              │              │
             └──────────────┴──────────────┴──────────────┘
                            │
                            ▼
                  ┌──────────────────┐
                  │  Output Files    │
                  │  (soft_copyright │
                  │      _temp/)     │
                  └──────────────────┘
```

### Technology Stack

- **Language**: Node.js / JavaScript
- **Output Format**: Plain text (.txt) with UTF-8 encoding
- **File Processing**: Node.js built-in modules (fs, path)
- **No External Dependencies**: Pure Node.js implementation using built-in modules

## Components and Interfaces

### 1. File Scanner Component

**Purpose**: 扫描项目目录，识别和选择需要提取的源代码文件

**Interface**:
```javascript
class FileScanner {
    constructor(projectRoot, libPath = "lib")
    scanFiles() // Returns Promise<FileInfo[]>
    filterFiles(files) // Returns FileInfo[]
    sortByImportance(files) // Returns FileInfo[]
}
```

**Selection Strategy**:
1. **Priority 1 - Core Entry Points** (权重: 10)
   - `lib/main.dart`
   - `lib/app.dart`
   - `lib/main_*.dart`

2. **Priority 2 - Core Infrastructure** (权重: 8)
   - `lib/core/database/*.dart`
   - `lib/core/services/*.dart`
   - `lib/core/router/*.dart`
   - `lib/core/models/*.dart`

3. **Priority 3 - Feature Modules** (权重: 6)
   - `lib/features/*/domain/*.dart` (业务逻辑)
   - `lib/features/*/application/*.dart` (应用服务)
   - `lib/features/*/data/*.dart` (数据层)

4. **Priority 4 - UI Components** (权重: 4)
   - `lib/features/*/presentation/screens/*.dart`
   - `lib/features/*/presentation/widgets/*.dart`

**Exclusion Rules**:
- 排除 `.g.dart` (生成文件)
- 排除 `.freezed.dart` (生成文件)
- 排除 `test/` 目录
- 排除 `*_test.dart` 文件

### 2. Code Formatter Component

**Purpose**: 格式化源代码，确保每页至少50行

**Interface**:
```javascript
class CodeFormatter {
    constructor(linesPerPage = 50)
    formatFile(filePath, fileContent) // Returns FormattedCode
    addHeader(filePath) // Returns string
    ensureLineCount(lines) // Returns string[]
}
```

**Formatting Rules**:
1. 每个文件开头添加文件路径注释
2. 保留原始代码格式和缩进
3. 保留空行和注释
4. 如果文件少于50行，保持原样（多个文件可以合并到一页）
5. 使用UTF-8编码处理中文注释

**Header Format**:
```
// ============================================================
// 文件: lib/features/product/domain/product_model.dart
// ============================================================
```

### 3. Document Generator Component

**Purpose**: 生成符合著作权登记要求的最终文档

**Interface**:
```javascript
class DocumentGenerator {
    constructor(outputDir = "soft_copyright_temp")
    generateDocument(formattedFiles) // Returns Promise<Document>
    splitIntoSections(allCode) // Returns {front: string, back: string}
    saveDocument(document) // Returns Promise<string>
}
```

**Document Structure**:
```
铺得清库存管理系统 - 源程序
软件著作权登记材料

========================================
前30页源程序（连续1500行）
========================================

// ============================================================
// 文件: lib/main.dart
// ============================================================
[源代码内容...]

// ============================================================
// 文件: lib/app.dart
// ============================================================
[源代码内容继续...]

...

========================================
后30页源程序（连续1500行）
========================================

// ============================================================
// 文件: lib/features/sale/data/sale_repository.dart
// ============================================================
[源代码内容...]

...
```

**Section Calculation Logic**:
- 每页固定50行代码，30页共1500行
- 如果总代码不足3000行（60页），则全部包含
- 前30页：连续的前1500行代码
- 后30页：连续的后1500行代码
- 不添加页码标记，避免与最终打印页数不符
- 使用文件路径分隔符标识代码来源

### 4. Report Generator Component

**Purpose**: 生成处理报告，记录提取的文件和统计信息

**Interface**:
```javascript
class ReportGenerator {
    generateReport(files, document) // Returns string
    saveReport(report, outputDir) // Returns Promise<string>
}
```

**Report Content**:
```
软件著作权源代码提取报告
生成时间: 2025-11-13 14:30:00

项目信息:
- 项目名称: 铺得清库存管理系统
- 项目路径: E:\stocko_app
- 源代码语言: Dart (Flutter)

提取统计:
- 扫描文件总数: 397
- 选择文件数量: 85
- 总代码行数: 12,450
- 生成页数: 60 (前30页 + 后30页)

文件清单:
1. lib/main.dart (52行)
2. lib/app.dart (38行)
3. lib/core/database/database.dart (245行)
...

输出文件:
- 源程序文档: soft_copyright_temp/source_code_copyright.txt
- 提取报告: soft_copyright_temp/extraction_report.txt
```

## Data Models

### FileInfo
```javascript
// Plain JavaScript object
{
    path: string,          // 相对路径
    fullPath: string,      // 绝对路径
    lineCount: number,     // 行数
    priority: number,      // 优先级权重
    category: string       // 分类 (entry/core/feature/ui)
}
```

### FormattedCode
```javascript
// Plain JavaScript object
{
    filePath: string,      // 文件路径
    content: string,       // 格式化后的内容
    lineCount: number      // 行数
}
```

### Document
```javascript
// Plain JavaScript object
{
    title: string,         // 文档标题
    frontSection: string,  // 前30页内容
    backSection: string,   // 后30页内容
    totalPages: number,    // 总页数
    totalLines: number     // 总行数
}
```

## Error Handling

### Error Categories

1. **File Access Errors**
   - 文件不存在
   - 文件读取权限不足
   - 编码错误

   **Handling**: 记录错误日志，跳过该文件，继续处理其他文件

2. **Encoding Errors**
   - 非UTF-8编码文件
   - 特殊字符处理

   **Handling**: 尝试多种编码（UTF-8, GBK, Latin-1），失败则跳过

3. **Insufficient Code**
   - 选择的文件总行数不足3000行

   **Handling**: 降低优先级阈值，包含更多文件

4. **Output Directory Errors**
   - 输出目录创建失败
   - 磁盘空间不足

   **Handling**: 抛出异常，终止程序

### Error Logging

```javascript
// 错误日志格式
[ERROR] 2025-11-13 14:30:00 - FileScanner: 无法读取文件 lib/test.dart - Error: ENOENT
[WARN]  2025-11-13 14:30:01 - CodeFormatter: 文件 lib/small.dart 仅有15行，将与其他文件合并
[INFO]  2025-11-13 14:30:02 - DocumentGenerator: 成功生成60页源程序文档
```

## Testing Strategy

### Unit Testing

1. **FileScanner Tests**
   - 测试文件扫描功能
   - 测试优先级排序
   - 测试文件过滤规则

2. **CodeFormatter Tests**
   - 测试文件头部添加
   - 测试编码处理
   - 测试行数计算

3. **DocumentGenerator Tests**
   - 测试文档分割（前30页/后30页）
   - 测试页码添加
   - 测试总行数不足60页的情况

### Integration Testing

1. **End-to-End Test**
   - 使用测试项目运行完整流程
   - 验证输出文档格式
   - 验证页数和行数要求

2. **Edge Cases**
   - 项目代码少于3000行
   - 所有文件都是生成文件
   - 包含特殊字符的文件名

### Manual Verification

1. **Output Document Review**
   - 检查前30页内容连续性
   - 检查后30页内容连续性
   - 验证每页至少50行
   - 确认文件路径标识清晰

2. **Report Accuracy**
   - 验证文件清单准确性
   - 验证统计数据正确性

## Implementation Notes

### Performance Considerations

- 文件扫描使用生成器模式，避免一次性加载所有文件
- 大文件分块读取，避免内存溢出
- 预计处理时间：< 10秒（对于400个文件）

### Portability

- 使用Node.js内置模块，无需安装额外依赖
- 跨平台兼容（Windows/Linux/macOS）
- 使用path模块处理路径，确保跨平台兼容性
- 可直接使用 `node copyright_extractor.js` 运行

### Maintainability

- 模块化设计，每个组件职责单一
- 详细的代码注释
- 配置参数可调整（行数、优先级权重等）

### Security

- 只读取源文件，不修改原始项目
- 输出到独立目录，避免覆盖原文件
- 不执行任何代码，仅文本处理
