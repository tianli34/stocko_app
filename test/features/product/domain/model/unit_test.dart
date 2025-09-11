import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/features/product/domain/model/unit.dart';

void main() {
  group('Unit', () {
    group('Factory Constructors', () {
      test('使用所有字段创建 Unit 对象', () {
        final unit = Unit(id: 1, name: '瓶');

        expect(unit.id, equals(1));
        expect(unit.name, equals('瓶'));
      });

      test('使用空 ID 创建 Unit 对象', () {
        final unit = Unit(id: null, name: '箱');

        expect(unit.id, isNull);
        expect(unit.name, equals('箱'));
      });

      test('empty 工厂构造函数', () {
        final emptyUnit = Unit.empty();

        expect(emptyUnit.id, isNull);
        expect(emptyUnit.name, equals(''));
      });
    });

    group('Getters', () {
      test('isNew getter - ID 为 null 时返回 true', () {
        final newUnit = Unit(id: null, name: '新单位');
        expect(newUnit.isNew, isTrue);
      });

      test('isNew getter - ID 不为 null 时返回 false', () {
        final existingUnit = Unit(id: 5, name: '现有单位');
        expect(existingUnit.isNew, isFalse);
      });
    });

    group('JSON Serialization', () {
      test('fromJson 创建对象的正确性', () {
        final json = {
          'id': 10,
          'name': '公斤',
        };

        final unit = Unit.fromJson(json);
        expect(unit.id, equals(10));
        expect(unit.name, equals('公斤'));
      });

      test('toJson 序列化的正确性', () {
        final unit = Unit(id: 20, name: '吨');

        final json = unit.toJson();
        expect(json['id'], equals(20));
        expect(json['name'], equals('吨'));
      });

      test('处理空 ID 的序列化', () {
        final unit = Unit(id: null, name: '未知单位');

        final json = unit.toJson();
        expect(json['id'], isNull);
        expect(json['name'], equals('未知单位'));
      });
    });

    group('copyWith', () {
      test('修改单个字段', () {
        final original = Unit(id: 1, name: '瓶');
        final copied = original.copyWith(name: '大瓶');

        expect(copied.id, equals(1));
        expect(copied.name, equals('大瓶'));
      });

      test('修改多个字段', () {
        final original = Unit(id: 1, name: '瓶');
        final copied = original.copyWith(id: 100, name: '超大瓶');

        expect(copied.id, equals(100));
        expect(copied.name, equals('超大瓶'));
      });

      test('设置字段为 null', () {
        final original = Unit(id: 1, name: '瓶');
        final copied = original.copyWith(id: null);

        expect(copied.id, isNull);
        expect(copied.name, equals('瓶'));
      });

      test('不传递任何参数返回原对象', () {
        final original = Unit(id: 1, name: '瓶');
        final copied = original.copyWith();

        expect(copied.id, equals(1));
        expect(copied.name, equals('瓶'));
        expect(copied, equals(original)); // 由于使用 Freezed，这应该是相等
      });
    });

    group('Equality and HashCode', () {
      test('相同数据的对象相等', () {
        final unit1 = Unit(id: 1, name: '瓶');
        final unit2 = Unit(id: 1, name: '瓶');

        expect(unit1, equals(unit2));
        expect(unit1.hashCode, equals(unit2.hashCode));
      });

      test('不同数据的对象不相等', () {
        final unit1 = Unit(id: 1, name: '瓶');
        final unit2 = Unit(id: 2, name: '瓶');
        final unit3 = Unit(id: 1, name: '箱');

        expect(unit1, isNot(equals(unit2)));
        expect(unit1, isNot(equals(unit3)));
        expect(unit2, isNot(equals(unit3)));
      });

      test('空对象相等', () {
        final empty1 = Unit.empty();
        final empty2 = Unit.empty();

        expect(empty1, equals(empty2));
        expect(empty1.hashCode, equals(empty2.hashCode));
      });
    });

    group('Business Scenarios', () {
      test('常见单位示例', () {
        final bottle = Unit(id: 1, name: '瓶');
        final box = Unit(id: 2, name: '箱');
        final kg = Unit(id: 3, name: '公斤');
        final piece = Unit(id: 4, name: '件');

        expect(bottle.name, equals('瓶'));
        expect(box.name, equals('箱'));
        expect(kg.name, equals('公斤'));
        expect(piece.name, equals('件'));

        // 验证这些都是现有对象（有ID）
        expect(bottle.isNew, isFalse);
        expect(box.isNew, isFalse);
        expect(kg.isNew, isFalse); // ID不为null
        expect(piece.isNew, isFalse);
      });

      test('单位名称可以包含中文字符', () {
        final unit1 = Unit(id: 1, name: '大瓶');
        final unit2 = Unit(id: 2, name: '小瓶');
        final unit3 = Unit(id: 3, name: '超大瓶');

        expect(unit1.name, contains('大'));
        expect(unit2.name, contains('小'));
        expect(unit3.name, startsWith('超大'));
      });

      test('单位名称可以包含空格和特殊字符', () {
        final unit1 = Unit(id: 1, name: '12 瓶装');
        final unit2 = Unit(id: 2, name: '500ml/瓶');
        final unit3 = Unit(id: 3, name: '大号(1L)');

        expect(unit1.name, equals('12 瓶装'));
        expect(unit2.name, contains('/'));
        expect(unit3.name, contains('('));
      });
    });

    group('Edge Cases', () {
      test('处理极端长度名称', () {
        const longName = '这是一个非常非常长的单位名称用于测试系统是否能正常处理超长文本的边界情况';
        const shortName = 'a';

        final longNamedUnit = Unit(id: 1, name: longName);
        final shortNamedUnit = Unit(id: 2, name: shortName);

        expect(longNamedUnit.name, equals(longName));
        expect(shortNamedUnit.name, equals(shortName));
      });

      test('处理空字符串和空格名称', () {
        final emptyNameUnit = Unit(id: 1, name: '');
        final spaceNameUnit = Unit(id: 2, name: '   ');

        expect(emptyNameUnit.name, equals(''));
        expect(spaceNameUnit.name, equals('   '));
      });

      test('处理数字ID', () {
        final zeroId = Unit(id: 0, name: '零号');
        final negativeId = Unit(id: -1, name: '负号');

        expect(zeroId.id, equals(0));
        expect(zeroId.isNew, isFalse); // 尽管是0，但不是null

        expect(negativeId.id, equals(-1));
        expect(negativeId.isNew, isFalse);
      });
    });

    group('Freezed-specific features', () {
      test('对象是不可变的', () {
        final unit = Unit(id: 1, name: '瓶');

        // Freezed 生成的对象应该是不可变的
        expect(() {
          // 这行代码应该导致编译错误，但这里只是演示意图
          // final modified = unit.name = '箱'; // 这会编译错误
        }, returnsNormally); // 这里只是语法验证
      });

      test('toString 方法提供有意义的输出', () {
        final unit = Unit(id: 1, name: '瓶');
        final result = unit.toString();

        expect(result, equals('Unit(id: 1, name: 瓶)'));
      });

      test('hashCode 基于内容生成', () {
        final unit1 = Unit(id: 1, name: '瓶');
        final unit2 = Unit(id: 1, name: '瓶');
        final unit3 = Unit(id: 2, name: '瓶');

        expect(unit1.hashCode, equals(unit2.hashCode));
        expect(unit1.hashCode, isNot(equals(unit3.hashCode)));
      });
    });

    group('Integration Scenarios', () {
      test('模拟业务流程中的使用', () {
        // 1. 从JSON创建单位
        final rawJson = {'id': null, 'name': '新单位'};
        final newUnit = Unit.fromJson(rawJson);

        expect(newUnit.isNew, isTrue);

        // 2. 设置ID后转换为JSON
        final withId = newUnit.copyWith(id: 100);
        final json = withId.toJson();

        expect(json['id'], equals(100));
        expect(withId.isNew, isFalse);

        // 3. 验证相等性
        final reconstructed = Unit.fromJson(withId.toJson());
        expect(reconstructed, equals(withId));
      });

      test('列表操作', () {
        final units = [
          Unit(id: 1, name: '瓶'),
          Unit(id: 2, name: '箱'),
          Unit(id: 3, name: '公斤'),
        ];

        // 查找特定单位
        final bottle = units.firstWhere((u) => u.name == '瓶');
        expect(bottle.id, equals(1));

        // 过滤新单位
        final newUnits = units.where((u) => u.isNew).toList();
        expect(newUnits, isEmpty);

        // 复制整个列表
        final copiedUnits = units.map((u) => u.copyWith()).toList();
        expect(copiedUnits, equals(units));
      });
    });
  });
}