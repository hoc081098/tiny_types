import 'dart:collection';

import 'package:test/test.dart';
import 'package:tiny_types/tiny_types.dart';

void main() {
  group('NonEmptyList.from', () {
    test('returns some for non-empty inputs and none for empty inputs', () {
      final result = NonEmptyList.from([2, 1, 2]);

      expect(result.getOrNull(), [2, 1, 2]);
      expect(NonEmptyList.from(<int>[]), const None());
    });

    test('preserves null elements rather than treating them as absence', () {
      final result = NonEmptyList.from(<int?>[null, 1, null]);

      expect(result.isSome, isTrue);
      expect(result.getOrNull(), [null, 1, null]);
      expect(NonEmptyList.from(<int?>[null]).getOrNull(), [null]);
    });

    test('copies mutable inputs', () {
      final values = [1, 2];
      final result = NonEmptyList.from(values).getOrNull()!;

      values.clear();

      expect(result, [1, 2]);
      expect(result.asList().clear, throwsUnsupportedError);
    });

    test('reuses an existing list only when its runtime element type is exact',
        () {
      final source = NonEmptyList.of(1);
      final Iterable<int> exact = source;
      final Iterable<num?> widened = source;

      expect(NonEmptyList.from(exact).getOrNull(), same(source));
      final result = NonEmptyList.from(widened).getOrNull()!;
      expect(identical(result, source), isFalse);
      expect(result.plus(2.5).plus(null), [1, 2.5, null]);
      expect(NonEmptyList.from<num?>(source).getOrNull()!.plus(2.5), [1, 2.5]);
    });

    test('eagerly consumes a lazy input once', () {
      final seen = <int>[];
      Iterable<int> values() sync* {
        if (seen.isNotEmpty) {
          throw StateError('Must not traverse twice');
        }
        for (final value in [1, 2]) {
          seen.add(value);
          yield value;
        }
      }

      final result = NonEmptyList.from(values());

      expect(seen, [1, 2]);
      expect(result.getOrNull(), [1, 2]);
      expect(result.getOrNull(), [1, 2]);
      expect(seen, [1, 2]);
    });

    test('propagates errors after reading an element', () {
      final error = StateError('Input failed');
      Iterable<int> values() sync* {
        yield 1;
        throw error;
      }

      expect(() => NonEmptyList.from(values()), throwsA(same(error)));
    });

    test('matches every extension conversion', () {
      final source = NonEmptyList.of(1, tail: const [2]);

      expect(source.toNonEmptyListOrNone(), NonEmptyList.from(source));
      expect(source.toNonEmptyListOrNull(), same(source));
      expect(source.toNonEmptyListOrThrow(), same(source));
      expect(<int?>[null].toNonEmptyListOrNone().getOrNull(), [null]);
      expect(<int>[].toNonEmptyListOrNull(), isNull);
      expect(<int>[].toNonEmptyListOrNone(), const None());
      expect(<int>[].toNonEmptyListOrThrow, throwsStateError);
    });
  });

  group('NonEmptySet.from', () {
    test('keeps unique elements in first-occurrence order or returns none', () {
      final result = NonEmptySet.from([2, 1, 2, 3]);

      expect(result.getOrNull()!.toList(), [2, 1, 3]);
      expect(NonEmptySet.from(<int>[]), const None());
    });

    test('preserves and deduplicates null elements', () {
      final result = NonEmptySet.from(<int?>[null, 1, null]);

      expect(result.isSome, isTrue);
      expect(result.getOrNull()!.toList(), [null, 1]);
      expect(NonEmptySet.from(<int?>[null]).getOrNull()!.toList(), [null]);
    });

    test('copies mutable inputs', () {
      final values = {2, 1};
      final result = NonEmptySet.from(values).getOrNull()!;

      values.clear();

      expect(result.toList(), [2, 1]);
      expect(result.asSet().clear, throwsUnsupportedError);
    });

    test('reuses an existing set only when its runtime element type is exact',
        () {
      final source = NonEmptySet.of(1);
      final Iterable<int> exact = source;
      final Iterable<num?> widened = source;

      expect(NonEmptySet.from(exact).getOrNull(), same(source));
      final result = NonEmptySet.from(widened).getOrNull()!;
      expect(identical(result, source), isFalse);
      expect(result.plus(2.5).plus(null).toList(), [1, 2.5, null]);
      expect(NonEmptySet.from<num?>(source).getOrNull()!.plus(2.5), {1, 2.5});
    });

    test('eagerly consumes a lazy input once', () {
      final seen = <int>[];
      Iterable<int> values() sync* {
        if (seen.isNotEmpty) {
          throw StateError('Must not traverse twice');
        }
        for (final value in [2, 1, 2]) {
          seen.add(value);
          yield value;
        }
      }

      final result = NonEmptySet.from(values());

      expect(seen, [2, 1, 2]);
      expect(result.getOrNull()!.toList(), [2, 1]);
      expect(result.getOrNull()!.toList(), [2, 1]);
      expect(seen, [2, 1, 2]);
    });

    test('propagates errors after reading an element', () {
      final error = StateError('Input failed');
      Iterable<int> values() sync* {
        yield 1;
        throw error;
      }

      expect(() => NonEmptySet.from(values()), throwsA(same(error)));
    });

    test('matches every extension conversion', () {
      final source = NonEmptySet.of(1, tail: const [2]);

      expect(source.toNonEmptySetOrNone(), NonEmptySet.from(source));
      expect(source.toNonEmptySetOrNull(), same(source));
      expect(source.toNonEmptySetOrThrow(), same(source));
      expect(<int?>[null].toNonEmptySetOrNone().getOrNull()!.toList(), [null]);
      expect(<int>[].toNonEmptySetOrNull(), isNull);
      expect(<int>[].toNonEmptySetOrNone(), const None());
      expect(<int>[].toNonEmptySetOrThrow, throwsStateError);
    });
  });

  group('NonEmptyMap.from', () {
    test('returns a map in key insertion order or none when empty', () {
      final result = NonEmptyMap.from({'b': 2, 'a': 1});

      expect(result.getOrNull()!.asMap(), {'b': 2, 'a': 1});
      expect(result.getOrNull()!.keys, ['b', 'a']);
      expect(NonEmptyMap.from(<String, int>{}), const None());
    });

    test('preserves nullable keys and values', () {
      final result = NonEmptyMap.from(<String?, int?>{null: null, 'a': 1});

      expect(result.isSome, isTrue);
      expect(result.getOrNull()!.keys, [null, 'a']);
      expect(
        result.getOrNull()!.asMap().getOrNone(null),
        const Some<int?>(null),
      );
      expect(NonEmptyMap.from(<String, int?>{'a': null}).isSome, isTrue);
    });

    test('copies mutable inputs', () {
      final values = {'a': 1};
      final result = NonEmptyMap.from(values).getOrNull()!;

      values.clear();

      expect(result.asMap(), {'a': 1});
      expect(result.asMap().clear, throwsUnsupportedError);
    });

    test('copies covariantly widened maps with the requested runtime types',
        () {
      final Map<Object?, num?> values = <String, int>{'a': 1};
      final result = NonEmptyMap.from(values).getOrNull()!;

      expect(
        result.plus((null, 2.5)).plus((2, null)).asMap(),
        {'a': 1, null: 2.5, 2: null},
      );
      expect(
        NonEmptyMap.from<Object?, num?>(<String, int>{'a': 1})
            .getOrNull()!
            .plus((2, 2.5)).asMap(),
        {'a': 1, 2: 2.5},
      );
    });

    test('does not retain custom key equality', () {
      final values = LinkedHashMap<String, int>(
        equals: (left, right) => left.toLowerCase() == right.toLowerCase(),
        hashCode: (key) => key.toLowerCase().hashCode,
      )..['Ada'] = 1;

      final result = NonEmptyMap.from(values).getOrNull()!;

      expect(values.containsKey('ADA'), isTrue);
      expect(result.containsKey('Ada'), isTrue);
      expect(result.containsKey('ADA'), isFalse);
    });

    test('matches every extension conversion', () {
      const values = {'a': 1};

      expect(values.toNonEmptyMapOrNone(), NonEmptyMap.from(values));
      expect(
        values.toNonEmptyMapOrNull(),
        NonEmptyMap.from(values).getOrNull(),
      );
      expect(values.toNonEmptyMapOrThrow().asMap(), values);
      expect(<String, int>{}.toNonEmptyMapOrNull(), isNull);
      expect(<String, int>{}.toNonEmptyMapOrNone(), const None());
      expect(<String, int>{}.toNonEmptyMapOrThrow, throwsStateError);
    });
  });
}
