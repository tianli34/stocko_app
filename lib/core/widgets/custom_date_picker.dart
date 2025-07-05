import 'package:flutter/material.dart';

/// 自定义日期选择器
/// 提供更方便的年月日选择体验
class CustomDatePicker {
  /// 显示自定义日期选择器
  static Future<DateTime?> show({
    required BuildContext context,
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    String title = '选择日期',
  }) {
    return showDialog<DateTime>(
      context: context,
      builder: (context) => _CustomDatePickerDialog(
        initialDate: initialDate ?? DateTime.now(),
        firstDate: firstDate ?? DateTime(2023),
        lastDate: lastDate ?? DateTime.now(),
        title: title,
      ),
    );
  }
}

class _CustomDatePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final String title;

  const _CustomDatePickerDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.title,
  });

  @override
  State<_CustomDatePickerDialog> createState() =>
      _CustomDatePickerDialogState();
}

class _CustomDatePickerDialogState extends State<_CustomDatePickerDialog> {
  late int selectedYear;
  late int selectedMonth;
  late int selectedDay;

  @override
  void initState() {
    super.initState();
    selectedYear = widget.initialDate.year;
    selectedMonth = widget.initialDate.month;
    selectedDay = widget.initialDate.day;
  }

  List<int> get availableYears {
    return List.generate(
      widget.lastDate.year - widget.firstDate.year + 1,
      (index) => widget.firstDate.year + index,
    ).reversed.toList();
  }

  List<int> get availableMonths {
    if (selectedYear == widget.firstDate.year &&
        selectedYear == widget.lastDate.year) {
      return List.generate(
        widget.lastDate.month - widget.firstDate.month + 1,
        (index) => widget.firstDate.month + index,
      );
    } else if (selectedYear == widget.firstDate.year) {
      return List.generate(
        12 - widget.firstDate.month + 1,
        (index) => widget.firstDate.month + index,
      );
    } else if (selectedYear == widget.lastDate.year) {
      return List.generate(widget.lastDate.month, (index) => index + 1);
    }
    return List.generate(12, (index) => index + 1);
  }

  List<int> get availableDays {
    final daysInMonth = DateTime(selectedYear, selectedMonth + 1, 0).day;
    final maxDay =
        selectedYear == widget.lastDate.year &&
            selectedMonth == widget.lastDate.month
        ? widget.lastDate.day
        : daysInMonth;
    final minDay =
        selectedYear == widget.firstDate.year &&
            selectedMonth == widget.firstDate.month
        ? widget.firstDate.day
        : 1;

    print(
      'Available Days - Year: $selectedYear, Month: $selectedMonth, '
      'DaysInMonth: $daysInMonth, MaxDay: $maxDay, MinDay: $minDay',
    );

    return List.generate(maxDay - minDay + 1, (index) => minDay + index);
  }

  void _updateDay() {
    final availableDays = this.availableDays;
    if (!availableDays.contains(selectedDay)) {
      selectedDay = availableDays.last;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 300,
        height: 250,
        child: Row(
          children: [
            // 年份选择
            Expanded(
              child: Column(
                children: [
                  const Text(
                    '年',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: availableYears.length,
                      itemBuilder: (context, index) {
                        final year = availableYears[index];
                        final isSelected = year == selectedYear;
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                selectedYear = year;
                                if (!availableMonths.contains(selectedMonth)) {
                                  selectedMonth = availableMonths.first;
                                }
                                _updateDay();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : null,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '$year',
                                style: TextStyle(
                                  color: isSelected ? Colors.white : null,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : null,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // 月份选择
            Expanded(
              child: Column(
                children: [
                  const Text(
                    '月',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: availableMonths.length,
                      itemBuilder: (context, index) {
                        final month = availableMonths[index];
                        final isSelected = month == selectedMonth;
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                selectedMonth = month;
                                _updateDay();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : null,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '$month',
                                style: TextStyle(
                                  color: isSelected ? Colors.white : null,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : null,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // 日期选择
            Expanded(
              child: Column(
                children: [
                  const Text(
                    '日',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: availableDays.length,
                      itemBuilder: (context, index) {
                        final day = availableDays[index];
                        final isSelected = day == selectedDay;
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                selectedDay = day;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : null,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '$day',
                                style: TextStyle(
                                  color: isSelected ? Colors.white : null,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : null,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            final selectedDate = DateTime(
              selectedYear,
              selectedMonth,
              selectedDay,
            );
            Navigator.of(context).pop(selectedDate);
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}
