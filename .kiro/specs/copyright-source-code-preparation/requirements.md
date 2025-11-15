# Requirements Document

## Introduction

本文档定义了为软件著作权登记准备程序鉴别材料的需求。根据软件著作权登记要求，需要提交源程序连续的前30页和连续的后30页，每页不少于50行。本系统将自动化地从现有项目中提取、整理和格式化源代码材料，确保符合登记要求且不影响原项目文件。

## Glossary

- **Source Code Extractor**: 从项目中提取源代码的系统组件
- **Copyright Material Generator**: 生成符合著作权登记要求的材料文档的系统
- **Original Project**: 当前Flutter应用项目的源代码库
- **Output Document**: 最终生成的用于提交的源代码文档

## Requirements

### Requirement 1

**User Story:** 作为软件著作权申请人，我希望系统能够安全地提取源代码，以便原项目文件不受任何影响

#### Acceptance Criteria

1. THE Source Code Extractor SHALL create all output files in a separate directory named 'soft_copyright_temp'
2. THE Source Code Extractor SHALL read source files without modifying any original project files
3. THE Source Code Extractor SHALL preserve the original file encoding and format during extraction
4. IF any error occurs during extraction, THEN THE Source Code Extractor SHALL log the error and continue processing remaining files

### Requirement 2

**User Story:** 作为软件著作权申请人，我希望系统能够选择最具代表性的源代码文件，以便展示软件的核心功能和技术实现

#### Acceptance Criteria

1. THE Source Code Extractor SHALL prioritize core business logic files from the 'lib/features' directory
2. THE Source Code Extractor SHALL include essential framework files such as main entry points and routing configuration
3. THE Source Code Extractor SHALL include data model and service layer implementations
4. THE Source Code Extractor SHALL exclude test files, generated files, and third-party dependencies
5. THE Source Code Extractor SHALL select files based on development timeline or functional importance

### Requirement 3

**User Story:** 作为软件著作权申请人，我希望生成的文档符合登记格式要求，以便顺利通过审核

#### Acceptance Criteria

1. THE Copyright Material Generator SHALL format each page with at least 50 lines of code
2. THE Copyright Material Generator SHALL generate exactly 30 continuous pages for the front section
3. THE Copyright Material Generator SHALL generate exactly 30 continuous pages for the back section
4. IF the total source code is less than 60 pages, THEN THE Copyright Material Generator SHALL include all available source code
5. THE Copyright Material Generator SHALL add page numbers to each page
6. THE Copyright Material Generator SHALL maintain code continuity within each section

### Requirement 4

**User Story:** 作为软件著作权申请人，我希望文档包含必要的标识信息，以便与申请材料对应

#### Acceptance Criteria

1. THE Copyright Material Generator SHALL include the software name at the top of the document
2. THE Copyright Material Generator SHALL include file path information for each code section
3. THE Copyright Material Generator SHALL use consistent formatting throughout the document
4. THE Copyright Material Generator SHALL generate the output in a format suitable for printing (e.g., TXT or formatted document)

### Requirement 5

**User Story:** 作为软件著作权申请人，我希望系统能够生成清晰的处理报告，以便了解提取了哪些文件和统计信息

#### Acceptance Criteria

1. WHEN extraction completes, THE Copyright Material Generator SHALL generate a summary report
2. THE Copyright Material Generator SHALL list all extracted files with their line counts
3. THE Copyright Material Generator SHALL report the total number of pages generated
4. THE Copyright Material Generator SHALL indicate whether the 60-page requirement was met
5. THE Copyright Material Generator SHALL provide the output file location
