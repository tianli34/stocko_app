import 'package:flutter_test/flutter_test.dart';
import 'package:stocko_app/features/sale/domain/model/customer.dart';

void main() {
  test('Customer json roundtrip', () {
    const c = Customer(id: 1, name: 'Alice');
    final json = c.toJson();
    final again = Customer.fromJson(json);
    expect(again, equals(c));
  });
}
