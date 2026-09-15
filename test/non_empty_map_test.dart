import 'dart:collection';

import 'package:meta/meta.dart';
import 'package:test/test.dart';
import 'package:tiny_types/tiny_types.dart';

void main() {
  group('NonEmptyMap', () {
    group('constructors', () {
      test('of wraps a single entry', () {
        final map = NonEmptyMap.of(('coffee', 2));

        expect(map.asMap(), {'coffee': 2});
        expect(map.length, 1);
        expect(map.head.key, 'coffee');
        expect(map.head.value, 2);
      });

      test('of keeps first key position and the last value', () {
        final map =
            NonEmptyMap.of(('a', 1), tail: const {'b': 2, 'a': 3, 'c': 4});

        expect(map.keys, ['a', 'b', 'c']);
        expect(map.values, [3, 2, 4]);
        expect(map.head.key, 'a');
        expect(map.head.value, 3);
      });

      test('of copies the tail', () {
        final tail = {'b': 2};
        final map = NonEmptyMap.of(('a', 1), tail: tail);

        tail['b'] = 3;
        tail['c'] = 4;

        expect(map.asMap(), {'a': 1, 'b': 2});
      });

      test('every construction path preserves key insertion order', () {
        final map = NonEmptyMap.of((2, 20), tail: const {1: 10});
        final maps = <NonEmptyMap<int, int>>[
          map,
          map.plus((2, 200)),
          map.plusAll(const {2: 200}),
          map.map(MapEntry.new),
          map.castToNonEmptyMap<int, int>(),
          const {2: 20, 1: 10}.toNonEmptyMapOrThrow(),
        ];

        for (final result in maps) {
          expect(result.keys, [2, 1]);
        }
      });
    });

    group('read-only map operations', () {
      test('is never empty and is neither a Map nor an Iterable', () {
        final map = NonEmptyMap.of(('a', 1));

        expect(map.isEmpty, isFalse);
        expect(map.isNotEmpty, isTrue);
        expect(map, isNot(isA<Map<String, int>>()));
        expect(map, isNot(isA<Iterable<MapEntry<String, int>>>()));
      });

      test('queries keys and values, including nullable ones', () {
        final map =
            NonEmptyMap<String?, int?>.of((null, null), tail: const {'b': 2});

        expect(map[null], isNull);
        expect(map.containsKey(null), isTrue);
        expect(map.containsKey('missing'), isFalse);
        expect(map['missing'], isNull);
        expect(map.containsValue(null), isTrue);
        expect(map.containsValue(2), isTrue);
        expect(map.containsValue(3), isFalse);
      });

      test('iterates keys, values, and entries in the same order', () {
        final map = NonEmptyMap.of(('b', 2), tail: const {'a': 1});
        final seen = <(String, int)>[];

        map.forEach((key, value) => seen.add((key, value)));

        expect(map.keys, ['b', 'a']);
        expect(map.values, [2, 1]);
        expect(map.entries.map((entry) => (entry.key, entry.value)), seen);
      });

      test('tail lazily exposes the entries after head', () {
        final map = NonEmptyMap.of(('a', 1), tail: const {'b': 2, 'c': 3});

        expect(
          map.tail.map((entry) => (entry.key, entry.value)),
          [('b', 2), ('c', 3)],
        );
        expect(NonEmptyMap.of(('a', 1)).tail, isEmpty);
      });

      test('asMap returns an unmodifiable view', () {
        final map = NonEmptyMap.of(('a', 1), tail: const {'b': 2});
        final view = map.asMap();

        expect(view, {'a': 1, 'b': 2});
        expect(() => view['c'] = 3, throwsUnsupportedError);
        expect(() => view.remove('a'), throwsUnsupportedError);
        expect(view.clear, throwsUnsupportedError);
        expect(map.asMap(), {'a': 1, 'b': 2});
      });

      test('toMap returns an independent modifiable copy', () {
        final map = NonEmptyMap.of(('a', 1), tail: const {'b': 2});
        final copy = map.toMap();

        expect(
          copy
            ..remove('a')
            ..addAll({'c': 3}),
          {'b': 2, 'c': 3},
        );
        expect(map.asMap(), {'a': 1, 'b': 2});
      });
    });

    group('non-empty transformations', () {
      test('plus appends a new key without changing the original', () {
        final map = NonEmptyMap.of(('a', 1));
        final result = map.plus(('b', 2));

        expect(result.keys, ['a', 'b']);
        expect(result.asMap(), {'a': 1, 'b': 2});
        expect(map.asMap(), {'a': 1});
      });

      test('plus replaces a value without moving the key', () {
        final map = NonEmptyMap.of(('a', 1), tail: const {'b': 2});
        final result = map.plus(('a', 3));

        expect(result.keys, ['a', 'b']);
        expect(result.asMap(), {'a': 3, 'b': 2});
        expect(map['a'], 1);
      });

      test('plusAll keeps first key positions and later values', () {
        final map = NonEmptyMap.of(('a', 1), tail: const {'b': 2});
        final result = map.plusAll({'b': 3, 'c': 4, 'a': 5});

        expect(result.keys, ['a', 'b', 'c']);
        expect(result.asMap(), {'a': 5, 'b': 3, 'c': 4});
        expect(map.plusAll(<String, int>{}).asMap(), map.asMap());
        expect(map.asMap(), {'a': 1, 'b': 2});
      });

      test('map eagerly converts each entry once in order', () {
        final map = NonEmptyMap.of(('a', 1), tail: const {'b': 2});
        final seen = <String>[];

        final result = map.map((key, value) {
          seen.add(key);
          return MapEntry(key.toUpperCase(), value * 10);
        });

        expect(seen, ['a', 'b']);
        expect(result.asMap(), {'A': 10, 'B': 20});
        expect(result.head.key, 'A');
        expect(map.asMap(), {'a': 1, 'b': 2});
      });

      test('map collapses equal converted keys without becoming empty', () {
        final map = NonEmptyMap.of(('a', 1), tail: const {'b': 2});
        final result = map.map((key, value) => MapEntry('same', value));

        expect(result.asMap(), {'same': 2});
        expect(result.head.key, 'same');
      });
    });

    group('cast conversion', () {
      test('copies widened keys and values before adding new entries', () {
        final integers = NonEmptyMap<int, int>.of((1, 2));
        final widened = integers.castToNonEmptyMap<num, num>();
        final result = widened.plus((1.5, 2.5));

        expect(result.asMap(), {1: 2, 1.5: 2.5});
        expect(integers.asMap(), {1: 2});
      });

      test('rejects a key or value that cannot be cast', () {
        final map = NonEmptyMap<int, int>.of((1, 2));

        expect(
          () => map.castToNonEmptyMap<String, num>(),
          throwsA(isA<TypeError>()),
        );
        expect(
          () => map.castToNonEmptyMap<num, String>(),
          throwsA(isA<TypeError>()),
        );
      });

      test('widened receivers reject incompatible additions until copied', () {
        final NonEmptyMap<num, num> widened = NonEmptyMap<int, int>.of((1, 2));

        expect(() => widened.plus((1.5, 2.5)), throwsA(isA<TypeError>()));
        expect(
          () => widened.plusAll(<num, num>{1.5: 2.5}),
          throwsA(isA<TypeError>()),
        );
        expect(widened.castToNonEmptyMap<num, num>().plus((1.5, 2.5)).asMap(), {
          1: 2,
          1.5: 2.5,
        });
      });
    });

    group('Map conversions', () {
      test('OrNull returns null for an empty map', () {
        expect(<String, int>{}.toNonEmptyMapOrNull(), isNull);
      });

      test('OrNull copies entries before checking emptiness', () {
        final source = {'a': 1, 'b': 2};
        final result = source.toNonEmptyMapOrNull()!;

        source['a'] = 3;
        source['c'] = 4;

        expect(result.asMap(), {'a': 1, 'b': 2});
        expect(result.keys, ['a', 'b']);
      });

      test('conversion uses normal key equality', () {
        // Keep these instances distinct to test identity-based source keys.
        // ignore: prefer_const_constructors
        final keys = List.generate(2, (_) => _EqualKey(1));
        final first = keys[0];
        final second = keys[1];
        final source = LinkedHashMap<_EqualKey, int>.identity()
          ..[first] = 1
          ..[second] = 2;

        final result = source.toNonEmptyMapOrThrow();

        expect(source.length, 2);
        expect(result.length, 1);
        expect(result[first], 2);
      });

      test('OrNone returns some or none', () {
        expect({'a': 1}.toNonEmptyMapOrNone().getOrNull()?.asMap(), {'a': 1});
        expect(<String, int>{}.toNonEmptyMapOrNone().isNone, isTrue);
      });

      test('OrThrow rejects an empty map', () {
        expect({'a': 1}.toNonEmptyMapOrThrow().asMap(), {'a': 1});
        expect(<String, int>{}.toNonEmptyMapOrThrow, throwsStateError);
      });
    });

    group('equality', () {
      test('equal entries in different orders have equal hashes', () {
        final first = NonEmptyMap.of(('a', 1), tail: const {'b': 2});
        final second = NonEmptyMap.of(('b', 2), tail: const {'a': 1});

        expect(first == second, isTrue);
        expect(second == first, isTrue);
        expect(first.hashCode, second.hashCode);
        expect(first == first, isTrue);
      });

      test('equal entries with different type arguments are equal', () {
        final integers = NonEmptyMap<int, String>.of((1, 'one'));
        final widened = NonEmptyMap<num, Object>.of((1, 'one'));

        expect(integers == widened, isTrue);
        expect(widened == integers, isTrue);
        expect(integers.hashCode, widened.hashCode);
      });

      test('distinguishes missing keys from present null values', () {
        final first = NonEmptyMap<String, int?>.of(('a', null));
        final same = NonEmptyMap<String, int?>.of(('a', null));
        final different = NonEmptyMap<String, int?>.of(('b', null));

        expect(first == same, isTrue);
        expect(first.hashCode, same.hashCode);
        expect(first == different, isFalse);
      });

      test('different keys or values are not equal', () {
        expect(NonEmptyMap.of(('a', 1)) == NonEmptyMap.of(('b', 1)), isFalse);
        expect(NonEmptyMap.of(('a', 1)) == NonEmptyMap.of(('a', 2)), isFalse);
        expect(
          NonEmptyMap.of(('a', 1)) ==
              NonEmptyMap.of(('a', 1), tail: const {'b': 2}),
          isFalse,
        );
      });

      test('a plain Map is not equal to a NonEmptyMap', () {
        final map = NonEmptyMap.of(('a', 1));
        final plain = {'a': 1};

        expect((map as Object) == plain, isFalse);
        expect((plain as Object) == map, isFalse);
      });

      test('toString matches the map form', () {
        expect(
          NonEmptyMap.of(('a', 1), tail: const {'b': 2}).toString(),
          '{a: 1, b: 2}',
        );
      });
    });
  });
}

@immutable
final class _EqualKey {
  const _EqualKey(this.value);

  final int value;

  @override
  bool operator ==(Object other) => other is _EqualKey && value == other.value;

  @override
  int get hashCode => value.hashCode;
}
