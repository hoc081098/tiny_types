import 'dart:collection';

import 'package:meta/meta.dart';

import 'option.dart';

/// An immutable map guaranteed to contain at least one entry.
///
/// ## Creating a map
///
/// [NonEmptyMap.of] requires a first key-value pair. For a possibly empty
/// [Map], [MapToNonEmptyMapExtension] provides `toNonEmptyMapOrNull()`,
/// `toNonEmptyMapOrNone()`, and `toNonEmptyMapOrThrow()`.
///
/// Entries keep their first insertion position. A later value for an equal key
/// replaces the earlier value without moving that key. Input maps are copied
/// into a normal insertion-ordered Dart map; custom key equality and ordering
/// from an input map are not retained.
///
/// ## Read-only map operations
///
/// This type does not implement [Map], whose interface includes mutating
/// members. [asMap] provides an unmodifiable [Map] view for APIs requiring
/// one; [toMap] creates a modifiable copy. [plus], [plusAll], and [map] create
/// new non-empty maps without changing this one.
///
/// [head] is the first entry in iteration order. [keys], [values], and
/// [entries] are lazy views; their types do not encode the non-empty guarantee.
/// Two [NonEmptyMap]s are equal when they contain equal key-value pairs,
/// regardless of iteration order. A plain [Map] is not equal to a
/// [NonEmptyMap].
@immutable
final class NonEmptyMap<K, V> {
  NonEmptyMap._wrap(this._map)
      : assert(
          _map.isNotEmpty,
          'NonEmptyMap must have at least one entry',
        ),
        assert(
          _map is LinkedHashMap<K, V>,
          'NonEmptyMap must use insertion-ordered map',
        );

  /// Creates a map containing [head], followed by [tail].
  ///
  /// Equal keys in [tail] replace earlier values without changing their
  /// insertion positions. [tail] is copied, so later changes to it are not
  /// visible through the result.
  ///
  /// ```dart
  /// NonEmptyMap.of(
  ///   ('a', 1),
  ///   tail: {'b': 2, 'a': 3},
  /// ); // {a: 3, b: 2}
  /// ```
  factory NonEmptyMap.of(
    (K, V) head, {
    Map<K, V> tail = const <Never, Never>{},
  }) =>
      NonEmptyMap._wrap(<K, V>{head.$1: head.$2, ...tail});

  // Never handed out directly or mutated after construction.
  final Map<K, V> _map;

  /// The first entry in iteration order.
  ///
  /// This is always available, though its value may be `null` when [V] is
  /// nullable.
  @useResult
  MapEntry<K, V> get head => _map.entries.first;

  /// The number of entries, always at least one.
  @useResult
  int get length => _map.length;

  /// Always `false`.
  @useResult
  bool get isEmpty => false;

  /// Always `true`.
  @useResult
  bool get isNotEmpty => true;

  /// The value associated with [key], or `null` when the key is absent.
  ///
  /// If values can be `null`, use [containsKey] to distinguish a present key
  /// with a `null` value from an absent key.
  @useResult
  V? operator [](Object? key) => _map[key];

  /// Whether [key] is present, as in [Map.containsKey].
  @useResult
  bool containsKey(Object? key) => _map.containsKey(key);

  /// Whether any entry has [value], as in [Map.containsValue].
  @useResult
  bool containsValue(Object? value) => _map.containsValue(value);

  /// The keys in insertion order, as in [Map.keys].
  @useResult
  Iterable<K> get keys => _map.keys;

  /// The values in key insertion order, as in [Map.values].
  @useResult
  Iterable<V> get values => _map.values;

  /// The entries in key insertion order, as in [Map.entries].
  @useResult
  Iterable<MapEntry<K, V>> get entries => _map.entries;

  /// Invokes [action] once for each entry, in iteration order.
  void forEach(void Function(K key, V value) action) => _map.forEach(action);

  /// Returns a new map with [key] associated with [value].
  ///
  /// An existing key keeps its position and receives the new value. A new key
  /// is appended. A covariantly widened receiver may reject [key] or [value]
  /// at runtime; use [castToNonEmptyMap] to copy it with wider runtime types.
  @useResult
  NonEmptyMap<K, V> plus(K key, V value) =>
      NonEmptyMap._wrap(<K, V>{..._map, key: value});

  /// Returns a new map with all entries from [other] added in iteration order.
  ///
  /// Later values for equal keys win without moving those keys. A covariantly
  /// widened receiver may reject [other] at runtime; use [castToNonEmptyMap]
  /// to copy it with wider runtime types.
  @useResult
  NonEmptyMap<K, V> plusAll(Map<K, V> other) =>
      NonEmptyMap._wrap(<K, V>{..._map, ...other});

  /// Eagerly transforms each entry into a new [NonEmptyMap].
  ///
  /// [convert] runs exactly once per entry, in iteration order. If converted
  /// keys are equal, the last converted value wins while the key keeps its
  /// first insertion position, as with [Map.map].
  @useResult
  NonEmptyMap<K2, V2> map<K2, V2>(
    MapEntry<K2, V2> Function(K key, V value) convert,
  ) {
    final mapped = <K2, V2>{};
    for (final entry in _map.entries) {
      final result = convert(entry.key, entry.value);
      mapped[result.key] = result.value;
    }
    return NonEmptyMap._wrap(mapped);
  }

  /// Returns an unmodifiable [Map] view of these entries.
  ///
  /// The view is created in constant time and remains unchanged because this
  /// map is immutable. Its mutating members throw [UnsupportedError]; use
  /// [toMap] for a modifiable copy.
  @useResult
  Map<K, V> asMap() => UnmodifiableMapView<K, V>(_map);

  /// Returns a modifiable [Map] copy of these entries.
  @useResult
  Map<K, V> toMap() => Map<K, V>.of(_map);

  /// Copies the entries into a [NonEmptyMap] with key and value types
  /// [RK] and [RV].
  ///
  /// Every key and value is checked eagerly. A failed cast throws a
  /// [TypeError]. Unlike [Map.cast], the result is an independent copy with
  /// the requested runtime types.
  @useResult
  NonEmptyMap<RK, RV> castToNonEmptyMap<RK, RV>() =>
      NonEmptyMap._wrap(Map<RK, RV>.from(_map));

  /// Whether [other] is a [NonEmptyMap] containing the same key-value pairs.
  ///
  /// Iteration order and generic type arguments are not part of equality.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! NonEmptyMap<Object?, Object?> || length != other.length) {
      return false;
    }
    for (final entry in _map.entries) {
      if (!other._map.containsKey(entry.key) ||
          other._map[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }

  /// A hash code derived from every key-value pair, independent of order.
  @override
  int get hashCode => Object.hashAllUnordered(
        _map.entries.map((entry) => Object.hash(entry.key, entry.value)),
      );

  /// Returns the entries in map form, such as `{a: 1, b: 2}`.
  @override
  String toString() => _map.toString();
}

/// Adds non-empty map conversions to any [Map].
extension MapToNonEmptyMapExtension<K, V> on Map<K, V> {
  /// Returns these entries as a [NonEmptyMap], or `null` when empty.
  ///
  /// The input is copied before checking emptiness. Later changes to this map
  /// are not visible through the result.
  @useResult
  NonEmptyMap<K, V>? toNonEmptyMapOrNull() {
    final entries = Map<K, V>.of(this);
    return entries.isEmpty ? null : NonEmptyMap._wrap(entries);
  }

  /// Returns these entries as an [Option] of [NonEmptyMap].
  ///
  /// Conversion follows [toNonEmptyMapOrNull].
  @useResult
  Option<NonEmptyMap<K, V>> toNonEmptyMapOrNone() =>
      toNonEmptyMapOrNull().toOption();

  /// Returns these entries as a [NonEmptyMap].
  ///
  /// Throws a [StateError] when this map is empty. Prefer
  /// [toNonEmptyMapOrNull] or [toNonEmptyMapOrNone] when emptiness is a normal
  /// outcome.
  @useResult
  NonEmptyMap<K, V> toNonEmptyMapOrThrow() =>
      toNonEmptyMapOrNull() ??
      (throw StateError('Cannot create a NonEmptyMap from an empty map.'));
}
