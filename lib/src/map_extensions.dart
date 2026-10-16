import 'package:meta/meta.dart';

import 'option.dart';

/// Adds presence-preserving value lookup to any [Map].
extension MapOptionExtension<K, V> on Map<K, V> {
  /// Returns the value for [key] as [Some], or [None] when the key is absent.
  ///
  /// Key lookup uses this map's equality rules, as with [Map.containsKey] and
  /// [Map.operator []]. A present key associated with `null` remains present
  /// as `Some(null)`. Errors from the map's lookup operations propagate to the
  /// caller.
  ///
  /// ```dart
  /// final values = <String, int?>{'a': null, 'b': 42};
  /// values.getOrNone('a'); // Option.Some(null)
  /// values.getOrNone('b'); // Option.Some(42)
  /// values.getOrNone('c'); // Option.None
  /// ```
  @useResult
  Option<V> getOrNone(Object? key) {
    final value = this[key];
    if (value == null && !containsKey(key)) {
      return const None();
    }
    return Some(value as V);
  }
}
