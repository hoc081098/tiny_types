import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:tiny_types/tiny_types.dart';

void main() {
  group('Iterable Option lookups', () {
    final collections = <String, Iterable<int?> Function(Iterable<int?>)>{
      'list': (values) => _GetterOnlyList(List<int?>.of(values)),
      'set': (values) => _GetterOnlySet(Set<int?>.of(values)),
    };

    group('firstOrNone', () {
      test('returns the first element or none when empty', () {
        expect([1, 2].firstOrNone, const Some(1));
        expect(<int>[].firstOrNone, const None());
      });

      test('distinguishes a first null element from an empty iterable', () {
        final result = <int?>[null, 2].firstOrNone;

        expect(result, const Some<int?>(null));
        expect(<int?>[].firstOrNone, const None());
      });

      test('does not evaluate the tail of a lazy iterable', () {
        Iterable<int?> values() sync* {
          yield null;
          throw StateError('Must not visit the tail');
        }

        expect(values().firstOrNone, const Some<int?>(null));
      });

      for (final MapEntry(key: k, value: v) in collections.entries) {
        test('uses $k getters without requesting an iterator', () {
          expect(v(<int?>[]).firstOrNone, const None());
          expect(v([1, 2]).firstOrNone, const Some(1));
          expect(v([null, 1]).firstOrNone, const Some<int?>(null));
        });
      }

      test('preserves a first null in non-empty lists and sets', () {
        final values = <Iterable<int?>>[
          NonEmptyList<int?>.of(null, tail: const [1]),
          NonEmptySet<int?>.of(null, tail: const [1]),
        ];

        for (final collection in values) {
          expect(collection.firstOrNone, const Some<int?>(null));
        }
      });
    });

    group('lastOrNone', () {
      test('returns the last element or none when empty', () {
        expect([1, 2].lastOrNone, const Some(2));
        expect(<int>[].lastOrNone, const None());
      });

      test('preserves a last null element without skipping other nulls', () {
        expect(<int?>[1, null].lastOrNone, const Some<int?>(null));
        expect(<int?>[null, 2].lastOrNone, const Some(2));
        expect(<int?>[null].lastOrNone, const Some<int?>(null));
      });

      test('traverses a single-use iterable once', () {
        final values = _SingleUseIterable([1, 2, 3]);

        expect(values.lastOrNone, const Some(3));
      });

      for (final MapEntry(key: k, value: v) in collections.entries) {
        test('uses $k getters without requesting an iterator', () {
          expect(v(<int?>[]).lastOrNone, const None());
          expect(v([1, 2]).lastOrNone, const Some(2));
          expect(v([1, null]).lastOrNone, const Some<int?>(null));
          expect(v([null]).lastOrNone, const Some<int?>(null));
        });
      }

      test('supports widened non-empty lists and sets', () {
        final values = <Iterable<num?>>[
          NonEmptyList<int>.of(1, tail: const [2]),
          NonEmptySet<int>.of(1, tail: const [2]),
        ];

        for (final collection in values) {
          expect(collection.lastOrNone, const Some(2));
        }
      });

      test('preserves a last null in non-empty lists and sets', () {
        final values = <Iterable<int?>>[
          NonEmptyList<int?>.of(1, tail: const [null]),
          NonEmptySet<int?>.of(1, tail: const [null]),
        ];

        for (final collection in values) {
          expect(collection.lastOrNone, const Some<int?>(null));
        }
      });

      test('evaluates a lazy mapped iterable once in order', () {
        final seen = <int>[];
        final values = [1, 2, 3].map((value) {
          seen.add(value);
          return value == 3 ? null : value;
        });

        expect(values.lastOrNone, const Some<int?>(null));
        expect(seen, [1, 2, 3]);
      });
    });

    group('singleOrNone', () {
      test('requires exactly one element, not one distinct value', () {
        expect(<int>[].singleOrNone, const None());
        expect([1].singleOrNone, const Some(1));
        expect([1, 2].singleOrNone, const None());
        expect([1, 1].singleOrNone, const None());
      });

      test('counts null elements when checking cardinality', () {
        expect(<int?>[null].singleOrNone, const Some<int?>(null));
        expect(<int?>[null, null].singleOrNone, const None());
        expect(<int?>[null, 1].singleOrNone, const None());
      });

      test('stops after the second element', () {
        final seen = <int>[];
        Iterable<int> values() sync* {
          for (var value = 1; value <= 2; value++) {
            seen.add(value);
            yield value;
          }
          throw StateError('Must not visit a third element');
        }

        expect(values().singleOrNone, const None());
        expect(seen, [1, 2]);
      });

      test('traverses a single-use iterable once', () {
        expect(_SingleUseIterable([1]).singleOrNone, const Some(1));
      });

      for (final MapEntry(key: k, value: v) in collections.entries) {
        test('uses $k getters without requesting an iterator', () {
          expect(v(<int?>[]).singleOrNone, const None());
          expect(v([1]).singleOrNone, const Some(1));
          expect(v([null]).singleOrNone, const Some<int?>(null));
          expect(v([1, 2]).singleOrNone, const None());
          expect(v([null, 1]).singleOrNone, const None());
        });
      }

      test('checks cardinality in nullable non-empty lists and sets', () {
        final singletons = <Iterable<num?>>[
          NonEmptyList<Null>.of(null),
          NonEmptySet<Null>.of(null),
        ];
        final multiple = <Iterable<num?>>[
          NonEmptyList<int>.of(1, tail: const [2]),
          NonEmptySet<int>.of(1, tail: const [2]),
        ];

        for (final collection in singletons) {
          expect(collection.singleOrNone, const Some<num?>(null));
        }
        for (final collection in multiple) {
          expect(collection.singleOrNone, const None());
        }
      });
    });

    group('firstWhereOrNone', () {
      test('returns the first match or none when there is no match', () {
        expect(
          [1, 2, 4].firstWhereOrNone((value) => value.isEven),
          const Some(2),
        );
        expect([1, 3].firstWhereOrNone((value) => value.isEven), const None());
      });

      test('preserves a matching null and short-circuits at the first match',
          () {
        final seen = <int?>[];
        Iterable<int?> values() sync* {
          yield 1;
          yield null;
          throw StateError('Must not visit the tail');
        }

        final result = values().firstWhereOrNone((value) {
          seen.add(value);
          return value == null;
        });

        expect(result, const Some<int?>(null));
        expect(seen, [1, null]);
      });

      test('skips nonmatching nulls without changing the selection', () {
        expect(
          <int?>[null, 2].firstWhereOrNone((value) => value != null),
          const Some(2),
        );
      });
    });

    group('lastWhereOrNone', () {
      test('returns the last match or none when there is no match', () {
        expect(
          [1, 2, 3, 4, 5].lastWhereOrNone((value) => value.isEven),
          const Some(4),
        );
        expect([1, 3].lastWhereOrNone((value) => value.isEven), const None());
      });

      test('evaluates each element once in order and preserves a null match',
          () {
        final values = _SingleUseIterable(<int?>[1, 2, null, 3]);
        final seen = <int?>[];

        final result = values.lastWhereOrNone((value) {
          seen.add(value);
          return value == null || value.isEven;
        });

        expect(result, const Some<int?>(null));
        expect(seen, [1, 2, null, 3]);
      });

      test('can replace an earlier null match with a later non-null match', () {
        expect(<int?>[null, 2].lastWhereOrNone((value) => true), const Some(2));
      });
    });

    group('singleWhereOrNone', () {
      test('requires exactly one matching element', () {
        expect(
          [1, 2, 3].singleWhereOrNone((value) => value.isEven),
          const Some(2),
        );
        expect([1, 3].singleWhereOrNone((value) => value.isEven), const None());
        expect([2, 4].singleWhereOrNone((value) => value.isEven), const None());
        expect([2, 2].singleWhereOrNone((value) => value.isEven), const None());
      });

      test('preserves a sole matching null and counts multiple null matches',
          () {
        final values = _SingleUseIterable(<int?>[1, null, 2]);
        final seen = <int?>[];

        final result = values.singleWhereOrNone((value) {
          seen.add(value);
          return value == null;
        });

        expect(result, const Some<int?>(null));
        expect(seen, [1, null, 2]);
        expect(
          <int?>[null, null].singleWhereOrNone((value) => value == null),
          const None(),
        );
      });

      test('stops at the second match even when the first match is null', () {
        final seen = <int?>[];
        Iterable<int?> values() sync* {
          yield null;
          yield 1;
          yield 2;
          throw StateError('Must not visit the tail');
        }

        final result = values().singleWhereOrNone((value) {
          seen.add(value);
          return value == null || value.isEven;
        });

        expect(result, const None());
        expect(seen, [null, 1, 2]);
      });

      test('matches collection singleWhereOrNull multiplicity semantics', () {
        for (final values in [
          <int>[],
          [1],
          [2],
          [2, 4],
          [1, 2, 3],
        ]) {
          expect(
            values.singleWhereOrNone((value) => value.isEven).getOrNull(),
            values.singleWhereOrNull((value) => value.isEven),
          );
        }
      });
    });

    group('shared contracts', () {
      final lookups = <String, Option<int> Function(Iterable<int>)>{
        'firstOrNone': (values) => values.firstOrNone,
        'lastOrNone': (values) => values.lastOrNone,
        'singleOrNone': (values) => values.singleOrNone,
        'firstWhereOrNone': (values) =>
            values.firstWhereOrNone((value) => true),
        'lastWhereOrNone': (values) => values.lastWhereOrNone((value) => true),
        'singleWhereOrNone': (values) => values.singleWhereOrNone(
              (value) => true,
            ),
      };

      for (final entry in lookups.entries) {
        test('${entry.key} supports single-use empty iterables', () {
          expect(entry.value(_SingleUseIterable(<int>[])), const None());
        });

        test(
            '${entry.key} propagates iterator errors instead of returning none',
            () {
          final error = StateError('Iterator failed');
          Iterable<int> values() sync* {
            throw error;
          }

          expect(() => entry.value(values()), throwsA(same(error)));
        });

        test('${entry.key} also works on non-empty lists and sets', () {
          expect(entry.value(NonEmptyList.of(1)), const Some(1));
          expect(entry.value(NonEmptySet.of(1)), const Some(1));
        });
      }

      final searches =
          <String, Option<int?> Function(Iterable<int?>, bool Function(int?))>{
        'firstWhereOrNone': (values, predicate) =>
            values.firstWhereOrNone(predicate),
        'lastWhereOrNone': (values, predicate) =>
            values.lastWhereOrNone(predicate),
        'singleWhereOrNone': (values, predicate) =>
            values.singleWhereOrNone(predicate),
      };

      for (final entry in searches.entries) {
        test('${entry.key} skips the predicate for an empty iterable', () {
          expect(
            entry.value(
              <int?>[],
              (value) => fail('Must not call the predicate'),
            ),
            const None(),
          );
        });

        test('${entry.key} propagates predicate errors on null elements', () {
          final error = StateError('Predicate failed');

          expect(
            () => entry.value(<int?>[null], (value) => throw error),
            throwsA(same(error)),
          );
        });
      }

      test('lookups reflect changes to mutable inputs rather than caching', () {
        final values = <int?>[null];

        expect(values.firstOrNone, const Some<int?>(null));
        values.clear();
        expect(values.firstOrNone, const None());
      });

      test('last and single searches propagate errors after the first match',
          () {
        final error = StateError('Tail failed');
        Iterable<int> values() sync* {
          yield 1;
          throw error;
        }

        expect(() => values().lastOrNone, throwsA(same(error)));
        expect(() => values().singleOrNone, throwsA(same(error)));
        expect(
          () => values().lastWhereOrNone((value) => true),
          throwsA(same(error)),
        );
        expect(
          () => values().singleWhereOrNone((value) => true),
          throwsA(same(error)),
        );
      });
    });
  });
}

class _GetterOnlyList<T> extends DelegatingList<T> {
  _GetterOnlyList(super.base);

  @override
  Iterator<T> get iterator => throw StateError('Must use collection getters');
}

class _GetterOnlySet<T> extends DelegatingSet<T> {
  _GetterOnlySet(super.base);

  @override
  Iterator<T> get iterator => throw StateError('Must use collection getters');
}

class _SingleUseIterable<T> extends IterableBase<T> {
  _SingleUseIterable(this._values);

  final Iterable<T> _values;
  bool _used = false;

  @override
  Iterator<T> get iterator {
    if (_used) {
      throw StateError('This iterable can only be traversed once');
    }
    _used = true;
    return _values.iterator;
  }
}
