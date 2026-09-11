import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:tiny_types/tiny_types.dart';

String describe(NonEmptyIterable<int> collection) =>
    '${collection.head} of ${collection.length}';

void main() {
  group('NonEmptyIterable', () {
    test('abstracts over both implementations', () {
      expect(describe(NonEmptyList.of(1, const [2])), '1 of 2');
      expect(describe(NonEmptySet.of(1, const [2, 1])), '1 of 2');
    });

    test('zip accepts either implementation', () {
      final result =
          NonEmptyList.of(1, const [2]).zip(NonEmptySet.of('a', const ['b']));

      expect(result, [(1, 'a'), (2, 'b')]);
    });

    test('flatMap accepts either implementation', () {
      final result = NonEmptySet.of(1, const [2]).flatMap(
        (value) => NonEmptyList.of(value, [value]),
      );

      expect(result, [1, 1, 2, 2]);
    });

    test('package:collection mapIndexed remains lazy', () {
      var callCount = 0;
      final result = NonEmptyList.of('a', const ['b']).mapIndexed(
        (index, letter) {
          callCount++;
          return '$index$letter';
        },
      );

      expect(callCount, 0);
      expect(result.first, '0a');
      expect(callCount, 1);
      expect(result, ['0a', '1b']);
      expect(callCount, 3);
    });

    test('flatten accepts mixed nesting', () {
      final nested = NonEmptyList<NonEmptyIterable<int>>.of(
        NonEmptyList.of(1, const [2]),
        [NonEmptySet.of(3)],
      );

      expect(nested.flatten(), [1, 2, 3]);
    });

    test('conversions round-trip between implementations', () {
      final list = NonEmptyList.of(1, const [2, 1]);

      expect(list.toNonEmptySet().toNonEmptyList(), [1, 2]);
      expect(list.toNonEmptySet().toNonEmptySet(), {1, 2});
    });

    test('is a sealed hierarchy of exactly two kinds', () {
      String kindOf(NonEmptyIterable<int> collection) => switch (collection) {
            NonEmptyList<int>() => 'list',
            NonEmptySet<int>() => 'set',
          };

      expect(kindOf(NonEmptyList.of(1)), 'list');
      expect(kindOf(NonEmptySet.of(1)), 'set');
    });
  });
}
