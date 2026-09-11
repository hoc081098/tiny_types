import 'package:test/test.dart';
import 'package:tiny_types/tiny_types.dart';

void main() {
  group('Unit', () {
    test('has one shared value', () async {
      const unit1 = Unit.value;
      final unit2 = await Unit.future;

      expect(identical(unit1, unit2), isTrue);
      expect(unit1 == unit2, isTrue);
      expect(unit1.hashCode == unit2.hashCode, isTrue);
    });

    test('exposes one shared completed future', () {
      expect(identical(Unit.future, Unit.future), isTrue);
      expect(Unit.future, completion(same(Unit.value)));
    });

    test('hashCode', () async {
      expect(Unit.value.hashCode, isNot(0));
      expect(Unit.value.hashCode, isNot(const None().hashCode));
      expect((await Unit.future).hashCode, Unit.value.hashCode);
    });

    test('toString', () async {
      expect(Unit.value.toString(), '()');
      expect((await Unit.future).toString(), '()');
    });

    test('compareTo', () async {
      const unit1 = Unit.value;
      final unit2 = await Unit.future;
      expect(unit1.compareTo(unit2), 0);
    });
  });
}
