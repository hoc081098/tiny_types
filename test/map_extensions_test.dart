import 'dart:collection';

import 'package:test/test.dart';
import 'package:tiny_types/tiny_types.dart';

void main() {
  group('Map.getOrNone', () {
    test('returns a present value or none for a missing key', () {
      const values = {'a': 1};
      final result = values.getOrNone('a');

      expect(result, const Some(1));
      expect(values.getOrNone('b'), const None());
      expect(<String, int>{}.getOrNone('a'), const None());
    });

    test('distinguishes present null values from missing keys', () {
      const values = <String, int?>{'a': null, 'b': 2};
      final result = values.getOrNone('a');

      expect(result, const Some<int?>(null));
      expect(values.getOrNone('b'), const Some(2));
      expect(values.getOrNone('missing'), const None());
      expect(result.getOrElse(() => throw StateError('Must not run')), isNull);
    });

    test('supports nullable keys independently of nullable values', () {
      const values = <String?, int?>{null: null, 'a': 1};

      expect(values.getOrNone(null), const Some<int?>(null));
      expect(values.getOrNone('a'), const Some(1));
      expect(values.getOrNone('missing'), const None());
    });

    test('accepts Object keys as with the standard Map lookup API', () {
      const values = {'a': 1};
      const Object key = 'a';

      expect(values.getOrNone(key), const Some(1));
      expect(values.getOrNone(42), const None());
      expect(values.getOrNone(null), const None());
    });

    test('uses custom key equality instead of copying to a normal map', () {
      final values = LinkedHashMap<String, int?>(
        equals: (left, right) => left.toLowerCase() == right.toLowerCase(),
        hashCode: (key) => key.toLowerCase().hashCode,
      )..['Ada'] = null;

      expect(values.getOrNone('ADA'), const Some<int?>(null));
      expect(values.getOrNone('Grace'), const None());
    });

    test('preserves covariance without accepting writes', () {
      final Map<Object?, num?> values = <String, int>{'a': 1};

      expect(values.getOrNone('a'), const Some(1));
      expect(values.getOrNone(2.5), const None());
    });

    test('reflects mutations rather than caching lookup results', () {
      final values = <String, int?>{};

      expect(values.getOrNone('a'), const None());
      values['a'] = null;
      expect(values.getOrNone('a'), const Some<int?>(null));
      values['a'] = 1;
      expect(values.getOrNone('a'), const Some(1));
      values.remove('a');
      expect(values.getOrNone('a'), const None());
    });

    test('checks key presence only when the value lookup returns null', () {
      final nonNull = _LookupProbeMap(value: 1, containsKeyResult: true);
      final presentNull = _LookupProbeMap(
        value: null,
        containsKeyResult: true,
      );
      final missing = _LookupProbeMap(
        value: null,
        containsKeyResult: false,
      );

      expect(nonNull.getOrNone('a'), const Some(1));
      expect(nonNull.valueLookupCount, 1);
      expect(nonNull.containsKeyCount, 0);

      expect(presentNull.getOrNone('a'), const Some<int?>(null));
      expect(presentNull.valueLookupCount, 1);
      expect(presentNull.containsKeyCount, 1);

      expect(missing.getOrNone('a'), const None());
      expect(missing.valueLookupCount, 1);
      expect(missing.containsKeyCount, 1);
    });

    test('propagates errors from containsKey and value lookup', () {
      final error = StateError('Lookup failed');

      expect(
        () => _ThrowingMap(error, failContainsKey: true).getOrNone('a'),
        throwsA(same(error)),
      );
      expect(
        () => _ThrowingMap(error, failContainsKey: false).getOrNone('a'),
        throwsA(same(error)),
      );
    });

    test('non-empty conversions propagate errors while copying a map', () {
      final error = StateError('Input failed');
      final values = _ThrowingMap(error, failContainsKey: false);

      expect(() => NonEmptyMap.from(values), throwsA(same(error)));
      expect(values.toNonEmptyMapOrNull, throwsA(same(error)));
      expect(values.toNonEmptyMapOrNone, throwsA(same(error)));
      expect(values.toNonEmptyMapOrThrow, throwsA(same(error)));
    });
  });
}

/// A Map that always throws an [StateError] when looking up a value,
/// and optionally throws the same error when checking for key presence.
class _ThrowingMap with MapMixin<String, int> implements Map<String, int> {
  _ThrowingMap(this._error, {required this.failContainsKey});

  final StateError _error;
  final bool failContainsKey;

  @override
  bool containsKey(Object? key) {
    if (failContainsKey) {
      throw _error;
    }
    return true;
  }

  @override
  int? operator [](Object? key) {
    if (failContainsKey) {
      return null;
    }
    throw _error;
  }

  @override
  void operator []=(String key, int value) => _fail();

  @override
  Iterable<String> get keys => const ['a'];

  @override
  void clear() => _fail();

  @override
  int? remove(Object? key) => _fail();

  Never _fail() => throw UnsupportedError('Read-only');
}

class _LookupProbeMap with MapMixin<String, int?> implements Map<String, int?> {
  _LookupProbeMap({
    required this.value,
    required this.containsKeyResult,
  });

  final int? value;
  final bool containsKeyResult;

  int valueLookupCount = 0;
  int containsKeyCount = 0;

  @override
  int? operator [](Object? key) {
    valueLookupCount++;
    return value;
  }

  @override
  bool containsKey(Object? key) {
    containsKeyCount++;
    return containsKeyResult;
  }

  @override
  void operator []=(String key, int? value) => _fail();

  @override
  Iterable<String> get keys => throw UnimplementedError('Not needed for tests');

  @override
  void clear() => _fail();

  @override
  int? remove(Object? key) => _fail();

  Never _fail() => throw UnsupportedError('Read-only');
}
