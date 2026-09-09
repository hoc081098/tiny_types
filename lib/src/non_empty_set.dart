part of 'non_empty_collection.dart';

/// An immutable [NonEmptyCollection] of unique elements.
///
/// `NonEmptySet<T>` is an [Iterable] but deliberately not a [Set]: the [Set]
/// interface declares mutating members that an immutable set could only
/// implement by throwing at run time. Use [asSet] to hand the elements to an
/// API that needs a [Set] or to compute an intersection or a difference, and
/// [Iterable.toSet] for a modifiable copy.
///
/// Elements keep their insertion order and duplicates are discarded.
/// Transformations that cannot preserve uniqueness, such as
/// [NonEmptyCollection.map] and [NonEmptyCollection.flatMap], return a
/// [NonEmptyList].
///
/// Create one with [NonEmptySet.of] when the first element is known
/// statically, or with [IterableToNonEmptySetExtension] when starting from an
/// [Iterable] whose length is only known at run time.
///
/// ```dart
/// final tags = NonEmptySet.of('dart', ['dart', 'types']);
/// // {dart, types}
/// ```
@immutable
final class NonEmptySet<T> extends NonEmptyCollection<T> {
  const NonEmptySet._(this._elements) : super._();

  /// Creates a set containing [head] followed by the new values of [tail].
  ///
  /// Values of [tail] that are equal to an earlier element are discarded, so
  /// the result can be shorter than `1 + tail.length`.
  ///
  /// ```dart
  /// final single = NonEmptySet.of(1); // {1}
  /// final several = NonEmptySet.of(1, [2, 1]); // {1, 2}
  /// ```
  factory NonEmptySet.of(T head, [Iterable<T> tail = const <Never>[]]) =>
      NonEmptySet._(<T>{head, ...tail});

  // Never handed out directly, and never mutated after construction, which is
  // what makes the unmodifiable view returned by `asSet` safe to share.
  final Set<T> _elements;

  @override
  @useResult
  T get head => _elements.first;

  /// Returns these elements as an unmodifiable [Set].
  ///
  /// The result is a view, so it is created in constant time and reflects no
  /// later changes, because this set can never change. Its mutating members
  /// throw [UnsupportedError]; use [Iterable.toSet] for a modifiable copy.
  ///
  /// ```dart
  /// final tags = NonEmptySet.of('dart', ['types']);
  ///
  /// tags.asSet().intersection({'dart'}); // {dart}
  /// tags.asSet().difference({'dart'}); // {types}
  /// ```
  @useResult
  Set<T> asSet() => UnmodifiableSetView<T>(_elements);

  /// The element equal to [element], or `null` when there is none.
  ///
  /// ```dart
  /// NonEmptySet.of(1, [2]).lookup(2); // 2
  /// NonEmptySet.of(1, [2]).lookup(3); // null
  /// ```
  @useResult
  T? lookup(Object? element) => _elements.lookup(element);

  @override
  @useResult
  NonEmptySet<T> plus(T element) => NonEmptySet._(<T>{..._elements, element});

  @override
  @useResult
  NonEmptySet<T> plusAll(Iterable<T> elements) =>
      NonEmptySet._(<T>{..._elements, ...elements});

  @override
  Iterator<T> get iterator => _elements.iterator;

  @override
  @useResult
  int get length => _elements.length;

  @override
  @useResult
  T get first => _elements.first;

  @override
  @useResult
  T get last => _elements.last;

  @override
  @useResult
  bool contains(Object? element) => _elements.contains(element);

  @override
  @useResult
  List<T> toList({bool growable = true}) =>
      _elements.toList(growable: growable);

  @override
  @useResult
  Set<T> toSet() => _elements.toSet();

  /// Whether [other] is a `NonEmptySet` containing exactly the same elements.
  ///
  /// Insertion order is not part of set equality.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NonEmptySet<Object?> &&
          length == other.length &&
          other.every(_elements.contains);

  /// A hash code derived from every element, independent of their order.
  @override
  int get hashCode => Object.hashAllUnordered(_elements);

  /// Returns the elements in set form, such as `{1, 2, 3}`.
  @override
  String toString() => _elements.toString();
}

/// Adds non-empty set conversions to any [Iterable].
extension IterableToNonEmptySetExtension<T> on Iterable<T> {
  /// Returns these elements as a [NonEmptySet], or `null` when empty.
  ///
  /// The elements are copied, so later changes to this iterable are not
  /// visible through the result.
  ///
  /// ```dart
  /// [1, 2, 1].toNonEmptySetOrNull(); // {1, 2}
  /// <int>[].toNonEmptySetOrNull(); // null
  /// ```
  @useResult
  NonEmptySet<T>? toNonEmptySetOrNull() {
    final elements = toSet();
    return elements.isEmpty ? null : NonEmptySet._(elements);
  }

  /// Returns these elements as an [Option] of [NonEmptySet].
  ///
  /// ```dart
  /// [1, 2].toNonEmptySetOrNone(); // Option.Some({1, 2})
  /// <int>[].toNonEmptySetOrNone(); // Option.None
  /// ```
  @useResult
  Option<NonEmptySet<T>> toNonEmptySetOrNone() =>
      toNonEmptySetOrNull().toOption();

  /// Returns these elements as a [NonEmptySet].
  ///
  /// Throws a [StateError] when this iterable is empty. Prefer
  /// [toNonEmptySetOrNull] or [toNonEmptySetOrNone] when emptiness is a
  /// normal outcome.
  ///
  /// ```dart
  /// [1, 2].toNonEmptySetOrThrow(); // {1, 2}
  /// ```
  @useResult
  NonEmptySet<T> toNonEmptySetOrThrow() =>
      toNonEmptySetOrNull() ??
      (throw StateError('Cannot create a NonEmptySet from an empty '
          'iterable.'));
}
