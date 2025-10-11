void main() {
  print('=== 重现实际问题 ===\n');
  
  // 手动计算
  final productionDate = DateTime(2025, 8, 23);
  print('生产日期: $productionDate');
  
  // 加9个月
  final expiryDate = DateTime(
    productionDate.year,
    productionDate.month + 9,
    productionDate.day,
  );
  print('过期日期 (生产日期 + 9个月): $expiryDate');
  
  final now = DateTime.now();
  print('当前时间: $now');
  
  final today = DateTime(now.year, now.month, now.day);
  final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
  
  print('今天(归零): $today');
  print('过期日期(归零): $expiry');
  
  final remainingDays = expiry.difference(today).inDays;
  print('剩余天数: $remainingDays');
  
  if (remainingDays < 0) {
    print('显示: 已过期${-remainingDays}天');
  } else if (remainingDays == 0) {
    print('显示: 今天过期');
  } else {
    print('显示: 剩余$remainingDays天');
  }
  
  print('\n如果你看到的是"已过期39天"，那说明：');
  print('1. 数据库中的数据可能不是你想的那样');
  print('2. 或者有缓存问题，代码没有重新加载');
  print('3. 请检查数据库中实际存储的 productionDate, shelfLifeDays, shelfLifeUnit 值');
}
