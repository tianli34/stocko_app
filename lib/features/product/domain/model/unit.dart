import 'package:freezed_annotation/freezed_annotation.dart';

part 'unit.freezed.dart';
part 'unit.g.dart';

@freezed
abstract class Unit with _$Unit {
  const Unit._();

  const factory Unit({int? id, required String name}) = _Unit;

  factory Unit.fromJson(Map<String, dynamic> json) => _$UnitFromJson(json);

  factory Unit.empty() => const Unit(id: null, name: '');

  bool get isNew => id == null;
}
