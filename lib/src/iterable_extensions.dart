import 'package:meta/meta.dart';

import 'option.dart';

/// Adds presence-preserving lookups to any [Iterable].
///
/// Lookups run synchronously without materializing a collection. A selected
/// `null` element remains present as `Some(null)`. Iterator, getter, and
/// predicate exceptions propagate to the caller.
extension IterableOptionExtension<T> on Iterable<T> {
  /// Returns the first element as [Some], or [None] when empty.
  ///
  /// Reads at most one element. A first element of `null` remains present.
  ///
  /// ```dart
  /// <int?>[1, 2].firstOrNone; // Option.Some(1)
  /// <int?>[null, 2].firstOrNone; // Option.Some(null)
  /// <int?>[].firstOrNone; // Option.None
  /// ```
  @useResult
  Option<T> get firstOrNone {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      return Some(iterator.current);
    }
    return const None();
  }

  /// Returns the last element as [Some], or [None] when empty.
  ///
  /// For [List] and [Set], checks [Iterable.isEmpty] before using
  /// [Iterable.last]. Other iterables are traversed once. A last element of
  /// `null` remains present. An infinite iterable cannot produce a result.
  @useResult
  Option<T> get lastOrNone {
    // The SDK's EfficientLengthIterable marker is internal. Use the same
    // fast path for these public collection interfaces.
    if (this is List<T> || this is Set<T>) {
      return isEmpty ? const None() : Option<T>.some(last);
    }

    final iterator = this.iterator;
    if (!iterator.moveNext()) {
      return const None();
    }
    var result = iterator.current;

    while (iterator.moveNext()) {
      result = iterator.current;
    }
    return Some(result);
  }

  /// Returns the only element as [Some] when there is exactly one, or [None]
  /// otherwise.
  ///
  /// Reads at most two elements without throwing for an empty or
  /// multiple-element iterable. A sole `null` element remains present.
  @useResult
  Option<T> get singleOrNone {
    final iterator = this.iterator;
    if (!iterator.moveNext()) {
      return const None();
    }

    final result = iterator.current;
    if (iterator.moveNext()) {
      return const None();
    }

    return Some(result);
  }

  /// Returns the first element matching [predicate] as [Some], or [None] when
  /// there is no match.
  ///
  /// Calls [predicate] once per visited element and stops at the first match.
  /// A matching `null` remains present. Iterator and predicate exceptions
  /// propagate.
  @useResult
  Option<T> firstWhereOrNone(bool Function(T element) predicate) {
    for (final element in this) {
      if (predicate(element)) {
        return Some(element);
      }
    }
    return const None();
  }

  /// Returns the last element matching [predicate] as [Some], or [None] when
  /// there is no match.
  ///
  /// Calls [predicate] exactly once per element, in iteration order. A matching
  /// `null` remains present. Iterator and predicate exceptions propagate.
  /// An infinite iterable cannot produce a result.
  @useResult
  Option<T> lastWhereOrNone(bool Function(T element) predicate) {
    Option<T> result = const None();

    for (final element in this) {
      if (predicate(element)) {
        result = Some(element);
      }
    }

    return result;
  }

  /// Returns the matching element as [Some] when there is exactly one, or
  /// [None] otherwise.
  ///
  /// Unlike [Iterable.singleWhere], this method does not throw for zero or
  /// multiple matches. Its behavior matches `package:collection`'s
  /// `singleWhereOrNull` while preserving a sole matching `null`.
  ///
  /// [predicate] is called once per visited element, and iteration stops at the
  /// second match. An infinite iterable with fewer than two matches cannot
  /// produce a result. Iterator and predicate exceptions propagate.
  @useResult
  Option<T> singleWhereOrNone(bool Function(T element) predicate) {
    final iterator = this.iterator;
    while (iterator.moveNext()) {
      final result = iterator.current;

      if (!predicate(result)) {
        continue;
      }

      // A second match means there is no single matching element.
      while (iterator.moveNext()) {
        if (predicate(iterator.current)) {
          return const None();
        }
      }
      return Some(result);
    }

    return const None();
  }
}
