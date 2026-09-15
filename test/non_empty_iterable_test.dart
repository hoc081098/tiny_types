import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:tiny_types/tiny_types.dart';

String describe(NonEmptyIterable<int> collection) =>
    '${collection.head} of ${collection.length}';

Iterable<int> remaining(NonEmptyIterable<int> collection) => collection.tail;

void main() {
  group('NonEmptyIterable', () {
    test('abstracts over both implementations', () {
      expect(describe(NonEmptyList.of(1, tail: const [2])), '1 of 2');
      expect(describe(NonEmptySet.of(1, tail: const [2, 1])), '1 of 2');
      expect(remaining(NonEmptyList.of(1, tail: const [2])), [2]);
      expect(remaining(NonEmptySet.of(1, tail: const [2, 1])), [2]);
    });

    test('tail may be empty for either implementation', () {
      final values = <NonEmptyIterable<int>>[
        NonEmptyList.of(1),
        NonEmptySet.of(1),
      ];

      for (final value in values) {
        expect(value.tail, isEmpty);
      }
    });

    test('zip accepts either implementation', () {
      final result = NonEmptyList.of(1, tail: const [2])
          .zip(NonEmptySet.of('a', tail: const ['b']));

      expect(result, [(1, 'a'), (2, 'b')]);
    });

    test('flatMapToNonEmptyList accepts either implementation', () {
      final result = NonEmptySet.of(1, tail: const [2]).flatMapToNonEmptyList(
        (value) => NonEmptyList.of(value, tail: [value]),
      );

      expect(result, [1, 1, 2, 2]);
    });

    test('package:collection mapIndexed remains lazy', () {
      var callCount = 0;
      final result = NonEmptyList.of('a', tail: const ['b']).mapIndexed(
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

    test('delegates standard Iterable operations', () {
      final values = <NonEmptyIterable<int>>[
        NonEmptyList.of(1, tail: const [2]),
        NonEmptySet.of(1, tail: const [2]),
      ];

      for (final value in values) {
        expect(value.where((element) => element.isEven), [2]);
        expect(value.whereType<num>(), [1, 2]);
        expect(value.expand((element) => [element, -element]), [1, -1, 2, -2]);

        final visited = <int>[];
        value.forEach(visited.add);
        expect(visited, [1, 2]);

        expect(value.reduce((sum, element) => sum + element), 3);
        expect(value.fold(10, (sum, element) => sum + element), 13);
        expect(value.followedBy([3]), [1, 2, 3]);
        expect(value.every((element) => element > 0), isTrue);
        expect(value.any((element) => element.isEven), isTrue);
        expect(value.join(','), '1,2');
        expect(value.take(1), [1]);
        expect(value.takeWhile((element) => element < 2), [1]);
        expect(value.skip(1), [2]);
        expect(value.skipWhile((element) => element < 2), [2]);
        expect(value.firstWhere((element) => element.isEven), 2);
        expect(value.lastWhere((element) => element > 0), 2);
        expect(value.singleWhere((element) => element.isEven), 2);
        expect(value.elementAt(1), 2);

        final cast = value.cast<num>();
        expect(cast, [1, 2]);
        expect(cast, isNot(isA<List<num>>()));
        expect(cast, isNot(isA<Set<num>>()));
      }

      expect(NonEmptyList.of(1).single, 1);
      expect(NonEmptySet.of(1).single, 1);
    });

    test('flatten accepts mixed nesting', () {
      final nested = NonEmptyList<NonEmptyIterable<int>>.of(
        NonEmptyList.of(1, tail: const [2]),
        tail: [NonEmptySet.of(3)],
      );

      expect(nested.flatten(), [1, 2, 3]);
    });

    test('conversions round-trip between implementations', () {
      final list = NonEmptyList.of(1, tail: const [2, 1]);

      expect(list.toNonEmptySet().toNonEmptyList(), [1, 2]);
      expect(list.toNonEmptySet().toNonEmptySet(), {1, 2});
    });

    test('castToNonEmptyList makes a widened element type usable', () {
      final NonEmptyIterable<num> widened = NonEmptyList<int>.of(1);

      expect(() => widened.plus(1.5), throwsA(isA<TypeError>()));
      expect(() => widened.plusAll(<num>[1.5]), throwsA(isA<TypeError>()));

      final result = widened.castToNonEmptyList<num>();

      expect(identical(result, widened), isFalse);
      expect(result, isA<NonEmptyList<num>>());
      expect(result.plus(1.5), [1, 1.5]);
      expect(result.plusAll(<num>[2.5]), [1, 2.5]);
      expect(widened, [1]);
    });

    test('castToNonEmptySet makes a widened element type usable', () {
      final NonEmptyIterable<num> widened = NonEmptySet<int>.of(1);

      expect(() => widened.plus(1.5), throwsA(isA<TypeError>()));
      expect(() => widened.plusAll(<num>[1.5]), throwsA(isA<TypeError>()));

      final result = widened.castToNonEmptySet<num>();

      expect(identical(result, widened), isFalse);
      expect(result, isA<NonEmptySet<num>>());
      expect(result.plus(1.5), {1, 1.5});
      expect(result.plusAll(<num>[2.5]), {1, 2.5});
      expect(widened, {1});
    });

    test('cast-copy conversions preserve order and set uniqueness', () {
      final list = NonEmptyList.of(2, tail: const [1, 2]);
      final set = NonEmptySet.of(2, tail: const [1]);

      expect(list.castToNonEmptySet<num>().toList(), [2, 1]);
      expect(set.castToNonEmptyList<num>(), [2, 1]);
      expect(identical(list.castToNonEmptyList<int>(), list), isFalse);
      expect(identical(set.castToNonEmptySet<int>(), set), isFalse);
    });

    test('cast-copy conversions reject incompatible elements eagerly', () {
      final NonEmptyIterable<Object> values =
          NonEmptyList<Object>.of(1, tail: const ['not a number']);

      expect(() => values.castToNonEmptyList<num>(), throwsA(isA<TypeError>()));
      expect(() => values.castToNonEmptySet<num>(), throwsA(isA<TypeError>()));
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
