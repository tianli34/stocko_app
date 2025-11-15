/**
 * 软件著作权源代码提取工具
 * 
 * 功能：从Flutter项目中提取源代码，生成符合软件著作权登记要求的程序鉴别材料
 * 要求：前30页和后30页，每页不少于50行
 */

const fs = require('fs');
const path = require('path');

// ============================================================
// 配置常量
// ============================================================

// 输出目录配置
const CONFIG = {
    // 输出目录名称
    OUTPUT_DIR: 'soft_copyright_temp',
    
    // 源代码目录
    SOURCE_DIR: 'lib',
    
    // 每页行数（软著要求每页不少于50行）
    LINES_PER_PAGE: 50,
    
    // 需要的页数
    PAGES_FRONT: 30,  // 前30页
    PAGES_BACK: 30,   // 后30页
    
    // 输出文件名
    OUTPUT_FILE: 'source_code_copyright.txt',
    REPORT_FILE: 'extraction_report.txt',
    
    // 项目信息
    PROJECT_NAME: '铺得清库存管理系统',
    
    // 文件编码
    ENCODING: 'utf8',
    
    // 文件过滤规则
    INCLUDE_EXTENSIONS: ['.dart'],
    EXCLUDE_PATTERNS: [
        '.g.dart',           // 生成文件
        '.freezed.dart',     // Freezed生成文件
        '_test.dart',        // 测试文件
        'test/',             // 测试目录
    ],
    
    // 文件优先级权重
    PRIORITY_WEIGHTS: {
        ENTRY: 10,      // 入口文件
        CORE: 8,        // 核心基础设施
        FEATURE: 6,     // 功能模块
        UI: 4,          // UI组件
    }
};

// ============================================================
// 文件扫描和选择功能
// ============================================================

/**
 * 递归扫描目录下的所有文件
 * @param {string} dir - 要扫描的目录路径
 * @param {string} baseDir - 基础目录（用于计算相对路径）
 * @returns {Array<{path: string, fullPath: string}>} 文件信息数组
 */
function scanDirectory(dir, baseDir = dir) {
    const files = [];
    
    try {
        const entries = fs.readdirSync(dir, { withFileTypes: true });
        
        for (const entry of entries) {
            const fullPath = path.join(dir, entry.name);
            
            if (entry.isDirectory()) {
                // 递归扫描子目录
                files.push(...scanDirectory(fullPath, baseDir));
            } else if (entry.isFile()) {
                // 添加文件信息
                const relativePath = path.relative(baseDir, fullPath);
                files.push({
                    path: relativePath,
                    fullPath: fullPath
                });
            }
        }
    } catch (error) {
        console.error(`[ERROR] 无法扫描目录 ${dir}: ${error.message}`);
    }
    
    return files;
}

/**
 * 过滤文件：只保留.dart文件，排除生成文件和测试文件
 * @param {Array} files - 文件信息数组
 * @returns {Array} 过滤后的文件数组
 */
function filterFiles(files) {
    return files.filter(file => {
        const filePath = file.path;
        
        // 检查文件扩展名
        const hasValidExtension = CONFIG.INCLUDE_EXTENSIONS.some(ext => 
            filePath.endsWith(ext)
        );
        
        if (!hasValidExtension) {
            return false;
        }
        
        // 检查排除模式
        const shouldExclude = CONFIG.EXCLUDE_PATTERNS.some(pattern => 
            filePath.includes(pattern)
        );
        
        return !shouldExclude;
    });
}

/**
 * 计算文件的行数
 * @param {string} filePath - 文件路径
 * @returns {number} 文件行数
 */
function countFileLines(filePath) {
    try {
        const content = fs.readFileSync(filePath, CONFIG.ENCODING);
        const lines = content.split('\n');
        return lines.length;
    } catch (error) {
        console.error(`[ERROR] 无法读取文件 ${filePath}: ${error.message}`);
        return 0;
    }
}

/**
 * 确定文件的优先级类别
 * @param {string} filePath - 文件相对路径
 * @returns {string} 类别名称
 */
function categorizeFile(filePath) {
    const normalizedPath = filePath.replace(/\\/g, '/');
    
    // 入口文件
    if (normalizedPath.match(/^(main\.dart|app\.dart|main_.*\.dart)$/)) {
        return 'ENTRY';
    }
    
    // 核心基础设施
    if (normalizedPath.match(/^core\/(database|services|router|models)\//)) {
        return 'CORE';
    }
    
    // 功能模块（业务逻辑层）
    if (normalizedPath.match(/^features\/.*\/(domain|application|data)\//)) {
        return 'FEATURE';
    }
    
    // UI组件
    if (normalizedPath.match(/^features\/.*\/presentation\/(screens|widgets)\//)) {
        return 'UI';
    }
    
    // 默认为UI级别
    return 'UI';
}

/**
 * 为文件添加优先级和行数信息
 * @param {Array} files - 文件信息数组
 * @returns {Array} 包含完整信息的文件数组
 */
function enrichFileInfo(files) {
    return files.map(file => {
        const category = categorizeFile(file.path);
        const priority = CONFIG.PRIORITY_WEIGHTS[category];
        const lineCount = countFileLines(file.fullPath);
        
        return {
            ...file,
            category: category,
            priority: priority,
            lineCount: lineCount
        };
    });
}

/**
 * 按优先级排序文件
 * @param {Array} files - 文件信息数组
 * @returns {Array} 排序后的文件数组
 */
function sortByPriority(files) {
    return files.sort((a, b) => {
        // 首先按优先级降序排序
        if (b.priority !== a.priority) {
            return b.priority - a.priority;
        }
        
        // 优先级相同时，按行数降序排序（更重要的文件通常更长）
        if (b.lineCount !== a.lineCount) {
            return b.lineCount - a.lineCount;
        }
        
        // 最后按路径字母顺序排序
        return a.path.localeCompare(b.path);
    });
}

/**
 * 扫描并选择源代码文件
 * @returns {Array} 选择的文件信息数组
 */
function scanAndSelectFiles() {
    console.log('开始扫描源代码文件...\n');
    
    const sourceDir = path.join(process.cwd(), CONFIG.SOURCE_DIR);
    
    // 检查源代码目录是否存在
    if (!fs.existsSync(sourceDir)) {
        throw new Error(`源代码目录不存在: ${CONFIG.SOURCE_DIR}`);
    }
    
    // 1. 递归扫描所有文件
    console.log(`✓ 扫描目录: ${CONFIG.SOURCE_DIR}`);
    const allFiles = scanDirectory(sourceDir, sourceDir);
    console.log(`  发现 ${allFiles.length} 个文件\n`);
    
    // 2. 过滤文件（只保留.dart文件，排除生成文件）
    console.log('✓ 过滤文件...');
    const dartFiles = filterFiles(allFiles);
    console.log(`  保留 ${dartFiles.length} 个 .dart 文件`);
    console.log(`  排除 ${allFiles.length - dartFiles.length} 个文件（生成文件、测试文件等）\n`);
    
    // 3. 添加优先级和行数信息
    console.log('✓ 分析文件信息...');
    const enrichedFiles = enrichFileInfo(dartFiles);
    
    // 统计各类别文件数量
    const categoryCounts = {};
    enrichedFiles.forEach(file => {
        categoryCounts[file.category] = (categoryCounts[file.category] || 0) + 1;
    });
    
    console.log('  文件分类统计:');
    console.log(`    - 入口文件 (ENTRY): ${categoryCounts.ENTRY || 0} 个`);
    console.log(`    - 核心模块 (CORE): ${categoryCounts.CORE || 0} 个`);
    console.log(`    - 业务模块 (FEATURE): ${categoryCounts.FEATURE || 0} 个`);
    console.log(`    - UI组件 (UI): ${categoryCounts.UI || 0} 个\n`);
    
    // 4. 按优先级排序
    console.log('✓ 按优先级排序文件...');
    const sortedFiles = sortByPriority(enrichedFiles);
    
    // 计算总行数
    const totalLines = sortedFiles.reduce((sum, file) => sum + file.lineCount, 0);
    console.log(`  总代码行数: ${totalLines.toLocaleString()} 行\n`);
    
    // 显示前10个优先级最高的文件
    console.log('优先级最高的文件（前10个）:');
    sortedFiles.slice(0, 10).forEach((file, index) => {
        console.log(`  ${index + 1}. [${file.category}] ${file.path} (${file.lineCount} 行)`);
    });
    console.log('');
    
    return sortedFiles;
}

// ============================================================
// 代码提取和格式化功能
// ============================================================

/**
 * 为文件添加路径标识注释头部
 * @param {string} filePath - 文件相对路径
 * @returns {string} 格式化的文件头部
 */
function formatFileHeader(filePath) {
    const separator = '='.repeat(60);
    return `// ${separator}\n// 文件: ${filePath}\n// ${separator}\n`;
}

/**
 * 读取单个文件内容并格式化
 * @param {Object} fileInfo - 文件信息对象
 * @returns {Object|null} 格式化后的代码对象，失败返回null
 */
function extractAndFormatFile(fileInfo) {
    try {
        // 读取文件内容（UTF-8编码）
        const content = fs.readFileSync(fileInfo.fullPath, CONFIG.ENCODING);
        
        // 添加文件路径标识注释
        const header = formatFileHeader(fileInfo.path);
        const formattedContent = header + content;
        
        // 计算实际行数（包括头部）
        const lines = formattedContent.split('\n');
        
        return {
            filePath: fileInfo.path,
            content: formattedContent,
            lineCount: lines.length,
            originalLineCount: fileInfo.lineCount
        };
        
    } catch (error) {
        // 错误处理：记录错误并跳过该文件
        console.error(`[ERROR] 无法读取文件 ${fileInfo.path}: ${error.message}`);
        return null;
    }
}

/**
 * 提取并合并所有选中文件的代码
 * @param {Array} selectedFiles - 选中的文件信息数组
 * @returns {Object} 合并后的代码信息
 */
function extractAndMergeCode(selectedFiles) {
    console.log('开始提取和格式化代码...\n');
    
    const formattedFiles = [];
    let successCount = 0;
    let errorCount = 0;
    
    // 逐个处理文件
    for (const fileInfo of selectedFiles) {
        const formatted = extractAndFormatFile(fileInfo);
        
        if (formatted) {
            formattedFiles.push(formatted);
            successCount++;
        } else {
            errorCount++;
        }
    }
    
    console.log(`✓ 代码提取完成:`);
    console.log(`  - 成功: ${successCount} 个文件`);
    if (errorCount > 0) {
        console.log(`  - 失败: ${errorCount} 个文件（已跳过）`);
    }
    console.log('');
    
    // 合并所有代码内容
    const mergedContent = formattedFiles.map(f => f.content).join('\n\n');
    const totalLines = mergedContent.split('\n').length;
    
    console.log(`✓ 代码合并完成:`);
    console.log(`  - 总行数: ${totalLines.toLocaleString()} 行`);
    console.log(`  - 包含文件: ${formattedFiles.length} 个\n`);
    
    return {
        formattedFiles: formattedFiles,
        mergedContent: mergedContent,
        totalLines: totalLines,
        successCount: successCount,
        errorCount: errorCount
    };
}

// ============================================================
// 文档生成功能
// ============================================================

/**
 * 生成前30页和后30页文档
 * @param {string} mergedContent - 合并后的代码内容
 * @param {number} totalLines - 总行数
 * @returns {string} 格式化的文档内容
 */
function generateCopyrightDocument(mergedContent, totalLines) {
    console.log('开始生成软著文档...\n');
    
    const lines = mergedContent.split('\n');
    const requiredLines = CONFIG.LINES_PER_PAGE * (CONFIG.PAGES_FRONT + CONFIG.PAGES_BACK);
    
    let frontLines = [];
    let backLines = [];
    
    // 计算需要提取的行数
    const frontLineCount = CONFIG.LINES_PER_PAGE * CONFIG.PAGES_FRONT; // 1500行
    const backLineCount = CONFIG.LINES_PER_PAGE * CONFIG.PAGES_BACK;   // 1500行
    
    if (totalLines <= requiredLines) {
        // 如果总代码不足3000行，全部包含
        console.log(`✓ 代码总行数 (${totalLines}) 少于要求 (${requiredLines})，将包含全部代码\n`);
        frontLines = lines;
        backLines = [];
    } else {
        // 分为前1500行和后1500行
        console.log(`✓ 代码总行数 (${totalLines}) 足够，提取前${frontLineCount}行和后${backLineCount}行\n`);
        frontLines = lines.slice(0, frontLineCount);
        backLines = lines.slice(-backLineCount);
    }
    
    // 构建文档内容
    const documentParts = [];
    
    // 添加文档标题
    const title = [
        '=' .repeat(80),
        `${CONFIG.PROJECT_NAME} - 程序鉴别材料`,
        '软件著作权登记申请文档',
        '=' .repeat(80),
        '',
        `文档生成时间: ${new Date().toLocaleString('zh-CN')}`,
        `源代码总行数: ${totalLines.toLocaleString()} 行`,
        `文档包含行数: ${(frontLines.length + backLines.length).toLocaleString()} 行`,
        '',
        '=' .repeat(80),
        ''
    ].join('\n');
    
    documentParts.push(title);
    
    // 添加前30页内容
    if (frontLines.length > 0) {
        const frontSection = [
            '',
            '/' .repeat(80),
            `前 ${CONFIG.PAGES_FRONT} 页 (第 1 - ${frontLineCount} 行)`,
            '/' .repeat(80),
            '',
            frontLines.join('\n')
        ].join('\n');
        
        documentParts.push(frontSection);
    }
    
    // 添加分隔符和后30页内容
    if (backLines.length > 0) {
        const backSection = [
            '',
            '',
            '/' .repeat(80),
            `后 ${CONFIG.PAGES_BACK} 页 (第 ${totalLines - backLineCount + 1} - ${totalLines} 行)`,
            '/' .repeat(80),
            '',
            backLines.join('\n')
        ].join('\n');
        
        documentParts.push(backSection);
    }
    
    const documentContent = documentParts.join('\n');
    
    console.log('✓ 文档生成完成:');
    console.log(`  - 前${CONFIG.PAGES_FRONT}页: ${frontLines.length.toLocaleString()} 行`);
    if (backLines.length > 0) {
        console.log(`  - 后${CONFIG.PAGES_BACK}页: ${backLines.length.toLocaleString()} 行`);
    }
    console.log(`  - 文档总行数: ${documentContent.split('\n').length.toLocaleString()} 行\n`);
    
    return documentContent;
}

/**
 * 保存文档到文件
 * @param {string} content - 文档内容
 * @param {string} filename - 文件名
 */
function saveDocument(content, filename) {
    const outputPath = path.join(process.cwd(), CONFIG.OUTPUT_DIR, filename);
    
    try {
        fs.writeFileSync(outputPath, content, CONFIG.ENCODING);
        console.log(`✓ 文档已保存: ${CONFIG.OUTPUT_DIR}/${filename}`);
        
        // 显示文件大小
        const stats = fs.statSync(outputPath);
        const fileSizeKB = (stats.size / 1024).toFixed(2);
        console.log(`  文件大小: ${fileSizeKB} KB\n`);
        
    } catch (error) {
        throw new Error(`保存文档失败: ${error.message}`);
    }
}

// ============================================================
// 主程序入口
// ============================================================

async function main() {
    console.log('========================================');
    console.log('软件著作权源代码提取工具');
    console.log('========================================\n');
    
    try {
        // 确保输出目录存在
        ensureOutputDirectory();
        
        console.log(`配置信息:`);
        console.log(`- 项目名称: ${CONFIG.PROJECT_NAME}`);
        console.log(`- 源代码目录: ${CONFIG.SOURCE_DIR}`);
        console.log(`- 输出目录: ${CONFIG.OUTPUT_DIR}`);
        console.log(`- 每页行数: ${CONFIG.LINES_PER_PAGE}`);
        console.log(`- 需要页数: 前${CONFIG.PAGES_FRONT}页 + 后${CONFIG.PAGES_BACK}页\n`);
        
        // 扫描并选择文件
        const selectedFiles = scanAndSelectFiles();
        
        // 提取和格式化代码
        const codeData = extractAndMergeCode(selectedFiles);
        
        // 生成前30页和后30页文档
        const copyrightDocument = generateCopyrightDocument(
            codeData.mergedContent, 
            codeData.totalLines
        );
        
        // 保存文档
        saveDocument(copyrightDocument, CONFIG.OUTPUT_FILE);
        
        console.log('========================================');
        console.log('✓ 所有任务完成！');
        console.log('========================================\n');
        
    } catch (error) {
        console.error('错误:', error.message);
        process.exit(1);
    }
}

// ============================================================
// 工具函数
// ============================================================

/**
 * 确保输出目录存在
 */
function ensureOutputDirectory() {
    const outputPath = path.join(process.cwd(), CONFIG.OUTPUT_DIR);
    
    if (!fs.existsSync(outputPath)) {
        fs.mkdirSync(outputPath, { recursive: true });
        console.log(`✓ 创建输出目录: ${CONFIG.OUTPUT_DIR}\n`);
    } else {
        console.log(`✓ 输出目录已存在: ${CONFIG.OUTPUT_DIR}\n`);
    }
}

// 运行主程序
if (require.main === module) {
    main();
}

module.exports = {
    CONFIG,
    main,
    scanDirectory,
    filterFiles,
    countFileLines,
    categorizeFile,
    enrichFileInfo,
    sortByPriority,
    scanAndSelectFiles,
    formatFileHeader,
    extractAndFormatFile,
    extractAndMergeCode,
    generateCopyrightDocument,
    saveDocument
};
