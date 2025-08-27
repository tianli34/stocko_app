import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';

/// 保质期单位下拉
class ShelfLifeUnitDropdown extends StatelessWidget {
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const ShelfLifeUnitDropdown({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return DropdownButtonFormField2<String>(
          value: value,
          decoration: InputDecoration(
            hintText: '保质期单位',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 0,
            ),
            filled: true,
            fillColor: Theme.of(context).inputDecorationTheme.fillColor,
            border: Theme.of(context).inputDecorationTheme.border,
            enabledBorder: Theme.of(context).inputDecorationTheme.enabledBorder,
            focusedBorder: Theme.of(context).inputDecorationTheme.focusedBorder,
            hintStyle: Theme.of(context).inputDecorationTheme.hintStyle,
          ),
          items: options.map((unit) {
            return DropdownMenuItem(
              value: unit,
              child: Text(
                _displayName(unit),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
          dropdownStyleData: DropdownStyleData(
            width: constraints.maxWidth * 0.75,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
    );
  }

  String _displayName(String unit) {
    switch (unit) {
      case 'days':
        return '天';
      case 'months':
        return '个月';
      case 'years':
        return '年';
      default:
        return unit;
    }
  }
}
