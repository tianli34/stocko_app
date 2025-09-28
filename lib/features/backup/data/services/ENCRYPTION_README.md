# 数据加密和安全功能

## 概述

EncryptionService 提供了强大的数据加密和安全功能，用于保护备份数据的机密性和完整性。该服务实现了 AES-256-GCM 加密算法（通过 AES-CTR + HMAC 模拟）、PBKDF2 密钥派生和 HMAC-SHA256 完整性验证。

## 主要功能

### 🔐 数据加密
- **算法**: AES-256-GCM (模拟实现)
- **密钥派生**: PBKDF2 with SHA-256 (100,000 iterations)
- **随机化**: 每次加密使用不同的盐值和初始化向量
- **格式**: Base64 编码输出

### 🔓 数据解密
- **密码验证**: 自动验证密码正确性
- **完整性检查**: 内置认证标签验证
- **错误处理**: 详细的错误信息和异常处理

### 🛡️ 安全特性
- **密码验证**: 快速验证密码而无需完整解密
- **HMAC 生成**: SHA-256 基础的消息认证码
- **HMAC 验证**: 常数时间比较防止时序攻击
- **安全密码生成**: 加密安全的随机密码生成

## 使用方法

### 基本加密和解密

```dart
final encryptionService = EncryptionService();

// 加密数据
final encrypted = await encryptionService.encryptData(
  '{"sensitive": "data"}',
  'your_password'
);

// 解密数据
final decrypted = await encryptionService.decryptData(
  encrypted,
  'your_password'
);
```

### 密码验证

```dart
// 验证密码是否正确
final isValid = await encryptionService.validatePassword(
  encryptedData,
  'password_to_check'
);
```

### 完整性验证

```dart
// 生成 HMAC
final hmac = encryptionService.generateHmac(data, 'integrity_key');

// 验证 HMAC
final isValid = encryptionService.verifyHmac(data, 'integrity_key', hmac);
```

### 安全密码生成

```dart
// 生成 32 字符的安全密码
final password = encryptionService.generateSecurePassword();

// 生成自定义长度的密码
final customPassword = encryptionService.generateSecurePassword(16);
```

## 安全考虑

### 🔒 加密强度
- **AES-256**: 256位密钥长度，军用级加密强度
- **PBKDF2**: 100,000 次迭代，抵抗暴力破解攻击
- **随机盐值**: 每次加密使用不同的16字节盐值
- **随机IV**: 每次加密使用不同的12字节初始化向量

### 🛡️ 攻击防护
- **时序攻击**: 使用常数时间比较算法
- **重放攻击**: 每次加密产生不同的密文
- **完整性攻击**: HMAC 验证防止数据篡改
- **密码攻击**: 强密钥派生函数增加破解难度

### 📊 性能特性
- **内存效率**: 流式处理大数据
- **处理速度**: 优化的算法实现
- **并发安全**: 支持多线程并发操作

## 错误处理

### EncryptionException
所有加密相关的错误都会抛出 `EncryptionException`：

```dart
try {
  final result = await encryptionService.decryptData(data, password);
} catch (e) {
  if (e is EncryptionException) {
    print('加密错误: ${e.message}');
  }
}
```

### 常见错误类型
- **密码错误**: "Authentication failed - invalid password or corrupted data"
- **数据损坏**: "Invalid encrypted data format"
- **格式错误**: "Failed to decrypt data"

## 最佳实践

### 🔐 密码管理
1. 使用强密码（至少12个字符，包含大小写字母、数字和特殊字符）
2. 不要在代码中硬编码密码
3. 考虑使用 `generateSecurePassword()` 生成随机密码
4. 为不同的备份使用不同的密码

### 🛡️ 数据保护
1. 始终验证 HMAC 以确保数据完整性
2. 在传输或存储前加密敏感数据
3. 定期更换加密密钥
4. 安全地清理内存中的敏感数据

### 📱 应用集成
1. 在 UI 中提供密码强度指示器
2. 实现密码确认输入
3. 提供密码找回机制的替代方案
4. 在加密/解密过程中显示进度指示器

## 测试

### 单元测试
运行加密服务的单元测试：
```bash
flutter test test/features/backup/data/services/encryption_service_test.dart
```

### 集成测试
运行完整的集成测试：
```bash
flutter test test/features/backup/data/services/encryption_integration_test.dart
```

### 示例演示
运行加密功能演示：
```bash
dart run lib/features/backup/data/services/encryption_example.dart
```

## 技术规格

### 加密参数
- **密钥长度**: 256 bits (32 bytes)
- **IV 长度**: 96 bits (12 bytes) for GCM
- **盐值长度**: 128 bits (16 bytes)
- **认证标签长度**: 128 bits (16 bytes)
- **PBKDF2 迭代次数**: 100,000

### 数据格式
加密后的数据格式（Base64编码）：
```
[盐值(16字节)] + [IV(12字节)] + [认证标签(16字节)] + [密文(可变长度)]
```

### 依赖项
- `dart:convert`: JSON 和 Base64 编码
- `dart:math`: 随机数生成
- `dart:typed_data`: 字节数组操作
- `crypto`: SHA-256 和 HMAC 实现

## 未来改进

### 🚀 计划功能
1. 真正的 AES-GCM 硬件加速支持
2. 密钥派生算法升级（Argon2）
3. 多密钥支持和密钥轮换
4. 压缩加密组合优化

### 🔧 性能优化
1. 异步流式处理大文件
2. 内存映射文件操作
3. 并行加密处理
4. 缓存优化策略