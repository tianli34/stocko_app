/// 数据恢复模式
enum RestoreMode {
  /// 完全替换现有数据
  replace,
  
  /// 合并数据（保留现有数据，添加新数据）
  merge,
  
  /// 仅添加不存在的数据
  addOnly,
}