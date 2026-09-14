import 'package:test/test.dart';
import 'package:tiny_types/tiny_types.dart';

void main() {
  group('NonEmptyList', () {
    group('constructors', () {
      test('of wraps a single element', () {
        final list = NonEmptyList.of(1);

        expect(list, [1]);
        expect(list.length, 1);
        expect(list.head, 1);
        expect(list.tail, isEmpty);
      });

      test('of keeps the order and duplicates of the tail', () {
        final list = NonEmptyList.of(1, const [2, 1]);

        expect(list, [1, 2, 1]);
        expect(list.head, 1);
        expect(list.tail, [2, 1]);
      });

      test('of copies the tail', () {
        final tail = [2];
        final list = NonEmptyList.of(1, tail);

        tail.add(3);

        expect(list, [1, 2]);
      });
    });

    group('non-emptiness', () {
      test('is never empty', () {
        final list = NonEmptyList.of(1);

        expect(list.isEmpty, isFalse);
        expect(list.isNotEmpty, isTrue);
      });

      test('head, first, last, and reduce are total', () {
        final list = NonEmptyList.of(1, const [2, 3]);

        expect(list.head, 1);
        expect(list.first, 1);
        expect(list.last, 3);
        expect(list.reduce((left, right) => left + right), 6);
      });

      test('is usable as a plain iterable', () {
        Iterable<int> asIterable(Iterable<int> values) => values;

        final list = NonEmptyList.of(1, const [2]);

        expect(asIterable(list), [1, 2]);
        expect([...list], [1, 2]);
        expect(list.join(','), '1,2');
      });

      test('is not a list', () {
        // The mutating members of `List` cannot be reached at all, so the
        // non-emptiness and immutability of the type cannot be circumvented.
        expect(NonEmptyList.of(1), isNot(isA<List<int>>()));
      });

      test('reads elements by index', () {
        final list = NonEmptyList.of(1, const [2]);

        expect(list[0], 1);
        expect(list[1], 2);
        expect(list.elementAt(1), 2);
        expect(() => list[2], throwsRangeError);
      });
    });

    group('list-like searches', () {
      final list = NonEmptyList.of(1, const [2, 1, 3]);

      test('indexOf searches forward from start', () {
        expect(list.indexOf(1), 0);
        expect(list.indexOf(1, 1), 2);
        expect(list.indexOf(1, 3), -1);
        expect(list.indexOf(4), -1);
      });

      test('lastIndexOf searches backward from start', () {
        expect(list.lastIndexOf(1), 2);
        expect(list.lastIndexOf(1, 1), 0);
        expect(list.lastIndexOf(1, -1), -1);
        expect(list.lastIndexOf(4), -1);
      });

      test('indexWhere searches forward from start', () {
        expect(list.indexWhere((value) => value.isOdd), 0);
        expect(list.indexWhere((value) => value.isOdd, 1), 2);
        expect(list.indexWhere((value) => value.isEven, 2), -1);
      });

      test('lastIndexWhere searches backward from start', () {
        expect(list.lastIndexWhere((value) => value.isOdd), 3);
        expect(list.lastIndexWhere((value) => value.isOdd, 2), 2);
        expect(list.lastIndexWhere((value) => value.isEven, 0), -1);
      });
    });

    group('list views', () {
      test('tail returns an unmodifiable view', () {
        final list = NonEmptyList.of(1, const [2]);
        final view = list.tail;

        expect(view, [2]);
        expect(() => view.add(3), throwsUnsupportedError);
        expect(() => view[0] = 3, throwsUnsupportedError);
        expect(view.sort, throwsUnsupportedError);
      });

      test('asList returns an unmodifiable view', () {
        final list = NonEmptyList.of(1, const [2]);
        final view = list.asList();

        expect(view, [1, 2]);
        expect(() => view.add(3), throwsUnsupportedError);
        expect(() => view[0] = 3, throwsUnsupportedError);
        expect(view.sort, throwsUnsupportedError);
        expect(list, [1, 2]);
      });

      test('toList returns a modifiable copy', () {
        final list = NonEmptyList.of(1);
        final copy = list.toList()..add(2);

        expect(copy, [1, 2]);
        expect(list, [1]);
        expect(list.toList(growable: false), [1]);
      });

      test('toSet discards duplicates', () {
        expect(NonEmptyList.of(1, const [2, 1]).toSet(), {1, 2});
      });
    });

    group('additions', () {
      test('plus appends one element', () {
        final list = NonEmptyList.of(1);

        expect(list.plus(2), [1, 2]);
        expect(list, [1]);
      });

      test('plusAll appends every element', () {
        expect(NonEmptyList.of(1).plusAll([2, 3]), [1, 2, 3]);
        expect(NonEmptyList.of(1).plusAll(<int>[]), [1]);
      });

      test('operator + returns a non-empty list', () {
        final result = NonEmptyList.of(1) + const [2];

        // Reading `head` only compiles when the static type is non-empty.
        expect(result.head, 1);
        expect(result, [1, 2]);
      });

      test('reversed returns a non-empty list', () {
        final result = NonEmptyList.of(1, const [2, 3]).reversed;

        expect(result.head, 3);
        expect(result, [3, 2, 1]);
      });
    });

    group('transformations', () {
      test('map keeps the lazy Iterable contract', () {
        var callCount = 0;
        final result = NonEmptyList.of(1, const [2]).map((value) {
          callCount++;
          return value * 2;
        });

        expect(callCount, 0);
        expect(result.first, 2);
        expect(callCount, 1);
        expect(result, [2, 4]);
        expect(callCount, 3);
      });

      test('mapToNonEmptyList transforms eagerly', () {
        var callCount = 0;
        final result = NonEmptyList.of(1, const [2]).mapToNonEmptyList(
          (value) {
            callCount++;
            return value * 2;
          },
        );

        expect(result, [2, 4]);
        expect(result.head, 2);
        expect(callCount, 2);
      });

      test('mapToNonEmptySet collapses equal results', () {
        final result = NonEmptyList.of(1, const [2, 3])
            .mapToNonEmptySet((value) => value.isEven);

        expect(result, {false, true});
        expect(result.head, isFalse);
      });

      test('mapIndexedToNonEmptyList exposes the iteration index', () {
        final result =
            NonEmptyList.of('a', const ['b']).mapIndexedToNonEmptyList(
          (index, letter) => '$index$letter',
        );

        expect(result, ['0a', '1b']);
        expect(result.head, '0a');
      });

      test('mapIndexedToNonEmptySet collapses equal results', () {
        final result = NonEmptyList.of('a', const ['b'])
            .mapIndexedToNonEmptySet((index, letter) => letter.length);

        expect(result, {1});
        expect(result.head, 1);
      });

      test('flatMapToNonEmptyList concatenates the results', () {
        final result = NonEmptyList.of(1, const [2]).flatMapToNonEmptyList(
          (value) => NonEmptyList.of(value, [-value]),
        );

        expect(result, [1, -1, 2, -2]);
        expect(result.head, 1);
      });

      test('flatMapToNonEmptySet collapses equal results', () {
        final result = NonEmptyList.of(1, const [2]).flatMapToNonEmptySet(
          (value) => NonEmptyList.of(value, [value]),
        );

        expect(result, {1, 2});
        expect(result.head, 1);
      });

      test('distinct keeps the first occurrence of each element', () {
        final result = NonEmptyList.of(1, const [2, 1, 3]).distinct();

        expect(result, [1, 2, 3]);
        expect(result, isA<NonEmptyList<int>>());
      });

      test('distinctBy keeps the first occurrence of each key', () {
        final result = NonEmptyList.of('one', const ['three', 'two'])
            .distinctBy((word) => word.length);

        expect(result, ['one', 'three']);
        expect(result, isA<NonEmptyList<String>>());
      });

      test('distinctBy calls selector once per element in order', () {
        final visited = <int>[];
        final result = NonEmptyList.of(1, const [2, 3]).distinctBy((value) {
          visited.add(value);
          return value.isOdd;
        });

        expect(visited, [1, 2, 3]);
        expect(result, [1, 2]);
      });

      test('flatten removes one level of nesting', () {
        final nested = NonEmptyList.of(
          NonEmptyList.of(1, const [2]),
          [NonEmptyList.of(3)],
        );

        expect(nested.flatten(), [1, 2, 3]);
      });
    });

    group('combinations', () {
      test('zip pairs elements by position', () {
        final result = NonEmptyList.of(1, const [2])
            .zip(NonEmptyList.of('a', const ['b']));

        expect(result, [(1, 'a'), (2, 'b')]);
      });

      test('zip stops at the shorter collection', () {
        expect(
          NonEmptyList.of(1, const [2, 3]).zip(NonEmptyList.of('a')),
          [(1, 'a')],
        );
        expect(
          NonEmptyList.of(1).zip(NonEmptyList.of('a', const ['b'])),
          [(1, 'a')],
        );
      });

      test('zipWith combines elements by position', () {
        var callCount = 0;
        final result = NonEmptyList.of(1, const [2]).zipWith(
          NonEmptyList.of(10, const [20, 30]),
          (left, right) {
            callCount++;
            return left + right;
          },
        );

        expect(result, [11, 22]);
        expect(callCount, 2);
      });

      test('unzip splits pairs into two collections', () {
        final (numbers, letters) =
            NonEmptyList.of((1, 'a'), const [(2, 'b')]).unzip();

        expect(numbers, [1, 2]);
        expect(letters, ['a', 'b']);
      });
    });

    group('conversions', () {
      test('toNonEmptyList returns the same immutable list', () {
        final list = NonEmptyList.of(1, const [2]);
        final result = list.toNonEmptyList();

        expect(result, [1, 2]);
        expect(identical(list, result), isTrue);
      });

      test('toNonEmptySet discards duplicates', () {
        expect(NonEmptyList.of(1, const [2, 1]).toNonEmptySet(), {1, 2});
      });

      test('toNonEmptyListOrNull selects a list or null', () {
        expect([1, 2].toNonEmptyListOrNull(), [1, 2]);
        expect(<int>[].toNonEmptyListOrNull(), isNull);
      });

      test('toNonEmptyListOrNull copies the elements', () {
        final source = [1];
        final list = source.toNonEmptyListOrNull();

        source.add(2);

        expect(list, [1]);
      });

      test('Iterable conversions reuse a list with the exact element type', () {
        final list = NonEmptyList.of(1, const [2]);
        final Iterable<int> source = list;

        expect(
          identical(source.toNonEmptyListOrNull(), list),
          isTrue,
        );
        expect(
          identical(source.toNonEmptyListOrNone().getOrNull(), list),
          isTrue,
        );
        expect(
          identical(source.toNonEmptyListOrThrow(), list),
          isTrue,
        );
      });

      test('Iterable conversion copies a covariantly widened list', () {
        final integers = NonEmptyList<int>.of(1);
        final Iterable<num> source = integers;
        final result = source.toNonEmptyListOrNull()!;

        expect(identical(result, integers), isFalse);
        expect(result.plus(1.5), [1, 1.5]);
        expect(result.toList()..add(2.5), [1, 2.5]);
      });

      test('toNonEmptyListOrNone selects some or none', () {
        expect(
          [1, 2].toNonEmptyListOrNone().getOrNull(),
          [1, 2],
        );
        expect(<int>[].toNonEmptyListOrNone().isNone, isTrue);
      });

      test('toNonEmptyListOrThrow throws for an empty iterable', () {
        expect([1, 2].toNonEmptyListOrThrow(), [1, 2]);
        expect(<int>[].toNonEmptyListOrThrow, throwsStateError);
      });
    });

    group('equality', () {
      test('equal elements in equal order are equal', () {
        final list = NonEmptyList.of(1, const [2]);
        final other = NonEmptyList.of(1, const [2]);

        expect(list == other, isTrue);
        expect(list.hashCode, other.hashCode);
        expect(list == list, isTrue);
      });

      test('equal elements with different type arguments are equal', () {
        final integers = NonEmptyList<int>.of(1, const [2]);
        final numbers = NonEmptyList<num>.of(1, const [2]);

        expect(integers == numbers, isTrue);
        expect(numbers == integers, isTrue);
        expect(integers.hashCode, numbers.hashCode);
      });

      test('order and length are significant', () {
        expect(
          NonEmptyList.of(1, const [2]) == NonEmptyList.of(2, const [1]),
          isFalse,
        );
        expect(NonEmptyList.of(1, const [2]) == NonEmptyList.of(1), isFalse);

        final Object otherElementType = NonEmptyList.of('1');
        expect(NonEmptyList.of(1) == otherElementType, isFalse);
      });

      test('a plain list is not equal to a non-empty list', () {
        final Object plainList = <int>[1];

        expect(NonEmptyList.of(1) == plainList, isFalse);
        expect(plainList == NonEmptyList.of(1), isFalse);
      });

      test('nested non-empty lists compare by element', () {
        final list = NonEmptyList.of(NonEmptyList.of(1));
        final other = NonEmptyList.of(NonEmptyList.of(1));

        expect(list == other, isTrue);
        expect(list.hashCode, other.hashCode);
      });

      test('toString matches the list form', () {
        expect(NonEmptyList.of(1, const [2]).toString(), '[1, 2]');
      });
    });
  });
}
