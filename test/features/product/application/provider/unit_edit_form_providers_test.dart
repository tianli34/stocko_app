import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stocko_app/features/product/application/provider/unit_edit_form_providers.dart';
import 'package:stocko_app/features/product/domain/model/auxiliary_unit_data.dart';

void main() {
  group('UnitEditFormNotifier 持久化功能', () {
    late ProviderContainer container;
    late UnitEditFormNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(unitEditFormProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('添加、编辑、删除辅单位后状态应正确持久化', () {
      // 添加辅单位
      notifier.addAuxiliaryUnit();
      expect(notifier.state.auxiliaryUnits.length, 1);

      // 编辑辅单位名称
      notifier.updateAuxiliaryUnitName(1, '箱', unitId: 'u1');
      expect(notifier.state.auxiliaryUnits[0].unitName, '箱');
      expect(notifier.state.auxiliaryUnits[0].unitId, 'u1');

      // 编辑换算率
      notifier.updateAuxiliaryUnitConversionRate(1, 12.0);
      expect(notifier.state.auxiliaryUnits[0].conversionRate, 12.0);

      // 编辑条码
      notifier.updateAuxiliaryUnitBarcode(1, '123456');
      expect(notifier.state.auxiliaryUnits[0].barcode, '123456');

      // 编辑建议零售价
      notifier.updateAuxiliaryUnitRetailPrice(1, '99.99');
      expect(notifier.state.auxiliaryUnits[0].retailPrice, '99.99');

      // 删除辅单位
      notifier.removeAuxiliaryUnit(1);
      expect(notifier.state.auxiliaryUnits.isEmpty, true);
    });

    test('setAuxiliaryUnits 可批量初始化并持久化', () {
      final units = [
        AuxiliaryUnitData(
          id: 1,
          unitId: 'u1',
          unitName: '箱',
          conversionRate: 12,
          barcode: '123',
          retailPrice: '10',
        ),
        AuxiliaryUnitData(
          id: 2,
          unitId: 'u2',
          unitName: '包',
          conversionRate: 24,
          barcode: '456',
          retailPrice: '20',
        ),
      ];
      notifier.setAuxiliaryUnits(units, counter: 3);
      expect(notifier.state.auxiliaryUnits.length, 2);
      expect(notifier.state.auxiliaryCounter, 3);
      expect(notifier.state.auxiliaryUnits[1].unitName, '包');
    });

    test('clearAll 可清空所有数据', () {
      notifier.addAuxiliaryUnit();
      notifier.resetUnitEditForm();
      expect(notifier.state.auxiliaryUnits.isEmpty, true);
      expect(notifier.state.auxiliaryCounter, 1);
    });
  });
}
