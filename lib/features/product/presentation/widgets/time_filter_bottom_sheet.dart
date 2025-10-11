import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../analytics/application/provider/ranking_providers.dart';

class TimeFilterBottomSheet extends ConsumerStatefulWidget {
  const TimeFilterBottomSheet({super.key});

  @override
  ConsumerState<TimeFilterBottomSheet> createState() => _TimeFilterBottomSheetState();
}

class _TimeFilterBottomSheetState extends ConsumerState<TimeFilterBottomSheet> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // 顶部指示条
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 16),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 标题与关闭区
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '选择时间范围',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: colorScheme.onSurface),
                ),
              ],
            ),
          ),

          const Divider(),

          // 模式切换区
          _ModeSelector(),

          const Divider(),

          // 日期选择区
          Expanded(
            child: _DateSelector(),
          ),

          const Divider(),

          // 操作按钮区
          _ActionButtons(),
        ],
      ),
    );
  }
}

// 模式切换控件
class _ModeSelector extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(timeFilterModeProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: TimeFilterMode.values.map((mode) {
          final isSelected = currentMode == mode;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () => ref.read(timeFilterModeProvider.notifier).state = mode,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  child: Text(
                    mode.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// 日期选择区
class _DateSelector extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(timeFilterModeProvider);

    switch (mode) {
      case TimeFilterMode.daily:
        return _DailySelector();
      case TimeFilterMode.weekly:
        return _WeeklySelector();
      case TimeFilterMode.monthly:
        return _MonthlySelector();
    }
  }
}

// 每日选择器
class _DailySelector extends ConsumerStatefulWidget {
  @override
  ConsumerState<_DailySelector> createState() => _DailySelectorState();
}

class _DailySelectorState extends ConsumerState<_DailySelector> {
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    final selectedDate = ref.read(selectedDateProvider);
    _displayedMonth = DateTime(selectedDate.year, selectedDate.month);
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 月份导航
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1);
                    });
                  },
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  '${_displayedMonth.year}年${_displayedMonth.month}月',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1);
                    });
                  },
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          // 日历网格
          _buildCalendarGrid(selectedDate, colorScheme),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(DateTime selectedDate, ColorScheme colorScheme) {
    final firstDayOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final lastDayOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;
    final totalCells = ((daysInMonth + firstWeekday - 1) / 7).ceil() * 7;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1.2,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: totalCells,
        itemBuilder: (context, index) {
          final dayNumber = index - firstWeekday + 2;
          
          if (dayNumber <= 0 || dayNumber > daysInMonth) {
            return const SizedBox();
          }

          final date = DateTime(_displayedMonth.year, _displayedMonth.month, dayNumber);
          final isSelected = date.year == selectedDate.year && 
                            date.month == selectedDate.month && 
                            date.day == selectedDate.day;
          final isToday = date.year == DateTime.now().year && 
                         date.month == DateTime.now().month && 
                         date.day == DateTime.now().day;

          return GestureDetector(
            onTap: () {
              ref.read(selectedDateProvider.notifier).state = date;
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary
                    : isToday
                        ? colorScheme.primaryContainer.withValues(alpha: 0.6)
                        : null,
                borderRadius: BorderRadius.circular(8),
                border: isToday && !isSelected
                    ? Border.all(color: colorScheme.primary, width: 2)
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  '$dayNumber',
                  style: TextStyle(
                    color: isSelected 
                        ? colorScheme.onPrimary 
                        : isToday 
                            ? colorScheme.onPrimaryContainer 
                            : colorScheme.onSurface,
                    fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// 每周选择器
class _WeeklySelector extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);

    return Column(
      children: [
        // 年份显示
        Padding(
          padding: const EdgeInsets.all(0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  final newDate = DateTime(selectedDate.year - 1, selectedDate.month, selectedDate.day);
                  ref.read(selectedDateProvider.notifier).state = newDate;
                },
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                '${selectedDate.year}年',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () {
                  final newDate = DateTime(selectedDate.year + 1, selectedDate.month, selectedDate.day);
                  ref.read(selectedDateProvider.notifier).state = newDate;
                },
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        Expanded(
          child: _WeeklyWheelPicker(
            selectedDate: selectedDate,
            onDateChanged: (date) {
              ref.read(selectedDateProvider.notifier).state = date;
            },
          ),
        ),
      ],
    );
  }

}

// 自定义每周滚轮选择器
class _WeeklyWheelPicker extends StatefulWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  const _WeeklyWheelPicker({
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  State<_WeeklyWheelPicker> createState() => _WeeklyWheelPickerState();
}

class _WeeklyWheelPickerState extends State<_WeeklyWheelPicker> {
  late FixedExtentScrollController _yearController;
  late FixedExtentScrollController _weekController;
  late int _selectedYear;
  late int _selectedWeek;

  @override
  void initState() {
    super.initState();
    final now = widget.selectedDate ?? DateTime.now();
    _selectedYear = now.year;
    _selectedWeek = _getWeekOfYear(now);

    _yearController = FixedExtentScrollController(initialItem: _selectedYear - 2020);
    _weekController = FixedExtentScrollController(initialItem: _selectedWeek - 1);
  }

  @override
  void didUpdateWidget(_WeeklyWheelPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != oldWidget.selectedDate) {
      final now = widget.selectedDate ?? DateTime.now();
      final newYear = now.year;
      final newWeek = _getWeekOfYear(now);
      
      if (newYear != _selectedYear) {
        setState(() {
          _selectedYear = newYear;
          _selectedWeek = newWeek;
        });
        _weekController.animateToItem(
          _selectedWeek - 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _yearController.dispose();
    _weekController.dispose();
    super.dispose();
  }

  int _getWeekOfYear(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return ((daysSinceFirstDay + firstDayOfYear.weekday - 1) ~/ 7) + 1;
  }

  int _getTotalWeeksInYear(int year) {
    final lastDayOfYear = DateTime(year, 12, 31);
    return _getWeekOfYear(lastDayOfYear);
  }

  DateTime _getDateFromWeek(int year, int week) {
    final firstDayOfYear = DateTime(year, 1, 1);
    final daysToAdd = (week - 1) * 7 - (firstDayOfYear.weekday - 1);
    return firstDayOfYear.add(Duration(days: daysToAdd));
  }

  void _updateSelectedDate() {
    final selectedDate = _getDateFromWeek(_selectedYear, _selectedWeek);
    widget.onDateChanged(selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListWheelScrollView.useDelegate(
          controller: _weekController,
          itemExtent: 60,
          physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: (index) {
            final totalWeeks = _getTotalWeeksInYear(_selectedYear);
            final weekInYear = index + 1;
            
            if (weekInYear <= totalWeeks) {
              setState(() {
                _selectedWeek = weekInYear;
                _updateSelectedDate();
              });
            }
          },
          childDelegate: ListWheelChildBuilderDelegate(
            builder: (context, index) {
              final weekInYear = index + 1;
              final totalWeeks = _getTotalWeeksInYear(_selectedYear);
              
              if (weekInYear > totalWeeks) {
                return const SizedBox();
              }
              
              final isSelected = weekInYear == _selectedWeek;
              final weekDate = _getDateFromWeek(_selectedYear, weekInYear);
              final endDate = weekDate.add(const Duration(days: 6));

              return Container(
                height: 60,
                alignment: Alignment.center,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary
                        : null,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  child: Text(
                    '${weekDate.month}月${weekDate.day}日 - ${endDate.month}月${endDate.day}日',
                    style: TextStyle(
                      color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
            childCount: 53,
          ),
        ),
      ),
    );
  }
}

// 每月选择器
class _MonthlySelector extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final colorScheme = Theme.of(context).colorScheme;



    return Column(
      children: [
        // 年份选择器
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  final newMonth = DateTime(selectedMonth.year - 1, selectedMonth.month);
                  ref.read(selectedMonthProvider.notifier).state = newMonth;
                },
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                '${selectedMonth.year}年',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () {
                  final newMonth = DateTime(selectedMonth.year + 1, selectedMonth.month);
                  ref.read(selectedMonthProvider.notifier).state = newMonth;
                },
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),

        // 月份网格
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 8,
                childAspectRatio: 1.5,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final month = index + 1;
                final isSelected = selectedMonth.month == month && selectedMonth.year == selectedMonth.year;
                final isCurrentMonth = DateTime.now().month == month && DateTime.now().year == selectedMonth.year;

                return GestureDetector(
                  onTap: () {
                    final newMonth = DateTime(selectedMonth.year, month);
                    ref.read(selectedMonthProvider.notifier).state = newMonth;
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary
                          : isCurrentMonth
                              ? colorScheme.primaryContainer.withValues(alpha: 0.4)
                              : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(color: colorScheme.primary.withValues(alpha: 0.5), width: 3)
                          : isCurrentMonth && !isSelected
                              ? Border.all(color: colorScheme.primary, width: 2)
                              : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: colorScheme.primary.withValues(alpha: 0.5),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : null,
                    ),
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimary
                              : isCurrentMonth
                                  ? Theme.of(context).colorScheme.onPrimaryContainer
                                  : Theme.of(context).colorScheme.onSurface,
                          fontWeight: isSelected || isCurrentMonth ? FontWeight.bold : FontWeight.w600,
                          fontSize: isSelected || isCurrentMonth ? 15 : 14,
                        ),
                        child: Text('$month月'),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// 操作按钮区
class _ActionButtons extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 全部按钮
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // 设置为全部时间
                final now = DateTime.now();
                final endOpen = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
                final start = DateTime(2000, 1, 1);
                ref.read(rankingRangeProvider.notifier).state = RankingRange(start, endOpen);
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.all_inclusive),
              label: const Text('全部'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // 重置按钮
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // 重置到默认状态
                    ref.read(timeFilterModeProvider.notifier).state = TimeFilterMode.daily;
                    ref.read(selectedDateProvider.notifier).state = DateTime.now();
                    ref.read(selectedMonthProvider.notifier).state = DateTime.now();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('重置'),
                ),
              ),

              const SizedBox(width: 16),

              // 确定按钮
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    _applyTimeFilter(ref);
                    Navigator.of(context).pop();
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('确定'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _applyTimeFilter(WidgetRef ref) {
    final mode = ref.read(timeFilterModeProvider);
    late RankingRange range;

    switch (mode) {
      case TimeFilterMode.daily:
        final date = ref.read(selectedDateProvider);
        final start = DateTime(date.year, date.month, date.day);
        final endOpen = start.add(const Duration(days: 1));
        range = RankingRange(start, endOpen);
        break;

      case TimeFilterMode.weekly:
        final date = ref.read(selectedDateProvider);
        // 计算本周的开始和结束
        final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 7));
        range = RankingRange(startOfWeek, endOfWeek);
        break;

      case TimeFilterMode.monthly:
        final date = ref.read(selectedMonthProvider);
        final start = DateTime(date.year, date.month, 1);
        final end = DateTime(date.year, date.month + 1, 1);
        range = RankingRange(start, end);
        break;
    }

    ref.read(rankingRangeProvider.notifier).state = range;
  }
}