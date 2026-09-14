import 'package:test/test.dart';
import 'package:tiny_types/tiny_types.dart';

void main() {
  group('NonEmptySet', () {
    group('constructors', () {
      test('of wraps a single element', () {
        final set = NonEmptySet.of(1);

        expect(set, {1});
        expect(set.length, 1);
        expect(set.head, 1);
      });

      test('of discards duplicates and keeps insertion order', () {
        final set = NonEmptySet.of(2, const [1, 2, 3]);

        expect(set.toList(), [2, 1, 3]);
        expect(set.head, 2);
      });

      test('of copies the tail', () {
        final tail = [2];
        final set = NonEmptySet.of(1, tail);

        tail.add(3);

        expect(set, {1, 2});
      });
    });

    group('non-emptiness', () {
      test('is never empty', () {
        final set = NonEmptySet.of(1);

        expect(set.isEmpty, isFalse);
        expect(set.isNotEmpty, isTrue);
      });

      test('head, first, last, and reduce are total', () {
        final set = NonEmptySet.of(1, const [2, 3]);

        expect(set.head, 1);
        expect(set.first, 1);
        expect(set.last, 3);
        expect(set.reduce((left, right) => left + right), 6);
      });

      test('is usable as a plain iterable', () {
        Iterable<int> asIterable(Iterable<int> values) => values;

        expect(asIterable(NonEmptySet.of(1, const [2])), {1, 2});
        expect(NonEmptySet.of(1).contains(1), isTrue);
        const Object otherType = '1';
        expect(NonEmptySet.of(1).contains(otherType), isFalse);
        expect(NonEmptySet.of(1, const [2]).containsAll([1, 2]), isTrue);
        expect(NonEmptySet.of(1).containsAll([1, 2]), isFalse);
        expect(NonEmptySet.of(1).lookup(1), 1);
        expect(NonEmptySet.of(1).lookup(2), isNull);
      });

      test('is not a set', () {
        // The mutating members of `Set` cannot be reached at all, so the
        // non-emptiness and immutability of the type cannot be circumvented.
        expect(NonEmptySet.of(1), isNot(isA<Set<int>>()));
      });
    });

    group('set views', () {
      test('asSet returns an unmodifiable view', () {
        final set = NonEmptySet.of(1, const [2]);
        final view = set.asSet();

        expect(view, {1, 2});
        expect(() => view.add(3), throwsUnsupportedError);
        expect(() => view.remove(1), throwsUnsupportedError);
        expect(view.clear, throwsUnsupportedError);
        expect(set, {1, 2});
      });

      test('asSet computes set algebra that can be empty', () {
        final set = NonEmptySet.of(1, const [2]);

        expect(set.asSet().intersection({2}), {2});
        expect(set.asSet().difference({1, 2}), isEmpty);
        expect(set.asSet().containsAll([1, 2]), isTrue);
      });

      test('toSet returns a modifiable copy', () {
        final set = NonEmptySet.of(1);
        final copy = set.toSet()..add(2);

        expect(copy, {1, 2});
        expect(set, {1});
      });

      test('toList keeps the iteration order', () {
        expect(NonEmptySet.of(2, const [1]).toList(), [2, 1]);
      });
    });

    group('additions', () {
      test('plus adds one element', () {
        final set = NonEmptySet.of(1);

        expect(set.plus(2), {1, 2});
        expect(set.plus(1), {1});
        expect(set, {1});
      });

      test('plusAll adds every new element', () {
        expect(NonEmptySet.of(1).plusAll([2, 1]), {1, 2});
        expect(NonEmptySet.of(1).plusAll(<int>[]), {1});
      });

      test('plusAll subsumes a set union', () {
        final result = NonEmptySet.of(1).plusAll(const {2});

        // Reading `head` only compiles when the static type is non-empty.
        expect(result.head, 1);
        expect(result, {1, 2});
      });

      test('union keeps order without changing either set', () {
        final left = NonEmptySet.of(2, const [1]);
        final right = NonEmptySet.of(1, const [3]);
        final result = left.union(right);

        expect(result, isA<NonEmptySet<int>>());
        expect(result.head, 2);
        expect(result.toList(), [2, 1, 3]);
        expect(left.toList(), [2, 1]);
        expect(right.toList(), [1, 3]);
        expect(identical(result, left), isFalse);
      });

      test('union with itself stays non-empty and keeps order', () {
        final set = NonEmptySet.of(2, const [1]);

        expect(set.union(set).toList(), [2, 1]);
      });

      test('union works after copying a covariantly widened set', () {
        final NonEmptySet<num> widened = NonEmptySet<int>.of(1);
        final other = NonEmptySet<num>.of(1.5);

        expect(() => widened.union(other), throwsA(isA<TypeError>()));
        expect(widened.castToNonEmptySet<num>().union(other), {1, 1.5});
      });
    });

    group('transformations', () {
      test('map keeps the lazy Iterable contract', () {
        var callCount = 0;
        final result = NonEmptySet.of(1, const [2]).map((value) {
          callCount++;
          return value * 2;
        });

        expect(callCount, 0);
        expect(result.first, 2);
        expect(callCount, 1);
        expect(result, [2, 4]);
        expect(callCount, 3);
      });

      test('mapToNonEmptyList keeps equal results', () {
        final result = NonEmptySet.of(1, const [2, 3]).mapToNonEmptyList(
          (value) => value.isEven,
        );

        expect(result, [false, true, false]);
        expect(result.head, isFalse);
      });

      test('mapToNonEmptySet collapses equal results', () {
        final result = NonEmptySet.of(1, const [2, 3])
            .mapToNonEmptySet((value) => value.isEven);

        expect(result, {false, true});
        expect(result.head, isFalse);
      });

      test('mapIndexedToNonEmptyList exposes the iteration index', () {
        final result =
            NonEmptySet.of('a', const ['b']).mapIndexedToNonEmptyList(
          (index, letter) => '$index$letter',
        );

        expect(result, ['0a', '1b']);
        expect(result.head, '0a');
      });

      test('mapIndexedToNonEmptySet collapses equal results', () {
        final result = NonEmptySet.of('a', const ['b'])
            .mapIndexedToNonEmptySet((index, letter) => letter.length);

        expect(result, {1});
        expect(result.head, 1);
      });

      test('flatMapToNonEmptyList concatenates the results', () {
        final result = NonEmptySet.of(1, const [2]).flatMapToNonEmptyList(
          (value) => NonEmptySet.of(value, [-value]),
        );

        expect(result, [1, -1, 2, -2]);
        expect(result.head, 1);
      });

      test('flatMapToNonEmptySet collapses equal results', () {
        final result = NonEmptySet.of(1, const [2]).flatMapToNonEmptySet(
          (value) => NonEmptyList.of(value, [value]),
        );

        expect(result, {1, 2});
        expect(result.head, 1);
      });

      test('distinct returns the same immutable set', () {
        final set = NonEmptySet.of(1, const [2]);
        final result = set.distinct();

        expect(result, {1, 2});
        expect(result, isA<NonEmptySet<int>>());
        expect(identical(result, set), isTrue);
      });

      test('distinctBy keeps the first occurrence of each key', () {
        final result = NonEmptySet.of('one', const ['three', 'two'])
            .distinctBy((word) => word.length);

        expect(result, {'one', 'three'});
        expect(result, isA<NonEmptySet<String>>());
      });

      test('distinctBy calls selector once per element in order', () {
        final visited = <int>[];
        final result = NonEmptySet.of(1, const [2, 3]).distinctBy((value) {
          visited.add(value);
          return value.isOdd;
        });

        expect(visited, [1, 2, 3]);
        expect(result.toList(), [1, 2]);
      });

      test('zip pairs elements by position', () {
        final result = NonEmptySet.of(1, const [2]).zip(NonEmptySet.of('a'));

        expect(result, [(1, 'a')]);
      });
    });

    group('conversions', () {
      test('toNonEmptyList keeps the iteration order', () {
        expect(NonEmptySet.of(2, const [1]).toNonEmptyList(), [2, 1]);
      });

      test('toNonEmptySet returns the same immutable set', () {
        final set = NonEmptySet.of(1);
        final result = set.toNonEmptySet();

        expect(result, {1});
        expect(identical(set, result), isTrue);
      });

      test('toNonEmptySetOrNull selects a set or null', () {
        expect([1, 2, 1].toNonEmptySetOrNull(), {1, 2});
        expect(<int>[].toNonEmptySetOrNull(), isNull);
      });

      test('toNonEmptySetOrNull copies the elements', () {
        final source = [1];
        final set = source.toNonEmptySetOrNull();

        source.add(2);

        expect(set, {1});
      });

      test('Iterable conversions reuse a set with the exact element type', () {
        final set = NonEmptySet.of(1, const [2]);
        final Iterable<int> source = set;

        expect(
          identical(source.toNonEmptySetOrNull(), set),
          isTrue,
        );
        expect(
          identical(source.toNonEmptySetOrNone().getOrNull(), set),
          isTrue,
        );
        expect(
          identical(source.toNonEmptySetOrThrow(), set),
          isTrue,
        );
      });

      test('Iterable conversion copies a covariantly widened set', () {
        final integers = NonEmptySet<int>.of(1);
        final Iterable<num> source = integers;
        final result = source.toNonEmptySetOrNull()!;

        expect(identical(result, integers), isFalse);
        expect(result.plus(1.5), {1, 1.5});
        expect(result.toSet()..add(2.5), {1, 2.5});
      });

      test('toNonEmptySetOrNone selects some or none', () {
        expect([1, 2].toNonEmptySetOrNone().getOrNull(), {1, 2});
        expect(<int>[].toNonEmptySetOrNone().isNone, isTrue);
      });

      test('toNonEmptySetOrThrow throws for an empty iterable', () {
        expect([1, 2].toNonEmptySetOrThrow(), {1, 2});
        expect(<int>[].toNonEmptySetOrThrow, throwsStateError);
      });
    });

    group('equality', () {
      test('the same elements in any order are equal', () {
        final set = NonEmptySet.of(1, const [2]);
        final reordered = NonEmptySet.of(2, const [1]);

        expect(set == reordered, isTrue);
        expect(set.hashCode, reordered.hashCode);
        expect(set == set, isTrue);
      });

      test('equal elements with different type arguments are equal', () {
        final integers = NonEmptySet<int>.of(1, const [2]);
        final numbers = NonEmptySet<num>.of(2, const [1]);

        expect(integers == numbers, isTrue);
        expect(numbers == integers, isTrue);
        expect(integers.hashCode, numbers.hashCode);
      });

      test('different elements are not equal', () {
        expect(NonEmptySet.of(1, const [2]) == NonEmptySet.of(1), isFalse);
        expect(NonEmptySet.of(1) == NonEmptySet.of(2), isFalse);

        final Object otherElementType = NonEmptySet.of('1');
        expect(NonEmptySet.of(1) == otherElementType, isFalse);
      });

      test('a plain set is not equal to a non-empty set', () {
        final Object plainSet = <int>{1};

        expect(NonEmptySet.of(1) == plainSet, isFalse);
        expect(plainSet == NonEmptySet.of(1), isFalse);
      });

      test('a non-empty list is not equal to a non-empty set', () {
        final Object list = NonEmptyList.of(1);

        expect(NonEmptySet.of(1) == list, isFalse);
      });

      test('toString matches the set form', () {
        expect(NonEmptySet.of(1, const [2]).toString(), '{1, 2}');
      });
    });
  });
}
