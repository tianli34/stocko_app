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
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        height: 48,
        child: IntrinsicWidth(
          child: DropdownButtonFormField2<String>(
            value: value,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
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
            buttonStyleData: const ButtonStyleData(
              padding: EdgeInsets.only(right: 4),
            ),
            iconStyleData: const IconStyleData(
              icon: Icon(Icons.arrow_drop_down),
              iconSize: 24,
            ),
            dropdownStyleData: DropdownStyleData(
              maxHeight: 200,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
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
