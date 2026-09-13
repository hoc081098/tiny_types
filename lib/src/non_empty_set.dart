part of 'non_empty_iterable.dart';

/// An immutable [NonEmptyIterable] of unique elements.
///
/// `NonEmptySet<T>` is an [Iterable] but deliberately not a [Set]: the [Set]
/// interface declares mutating members that an immutable set could only
/// implement by throwing at run time. Use [asSet] to hand the elements to an
/// API that needs a [Set] or to compute an intersection or a difference, and
/// [Iterable.toSet] for a modifiable copy.
/// Common [Iterable] operations delegate directly to the backing set so they
/// retain its specialized implementations; lazy operations remain lazy.
///
/// Elements keep their insertion order and duplicates are discarded.
/// Inherited [Iterable] transformations remain lazy. Non-empty-preserving
/// transformations on [NonEmptyIterable] materialize a list by default; use
/// a `ToNonEmptySet` variant when equal results should be collapsed.
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
final class NonEmptySet<T> extends NonEmptyIterable<T> {
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

  // NonEmptyIterable.

  @override
  @useResult
  T get head => _elements.first;

  @override
  @useResult
  NonEmptySet<T> plus(T element) => NonEmptySet._(<T>{..._elements, element});

  @override
  @useResult
  NonEmptySet<T> plusAll(Iterable<T> elements) =>
      NonEmptySet._(<T>{..._elements, ...elements});

  @override
  @useResult
  NonEmptySet<T> distinct() => this;

  @override
  @useResult
  NonEmptySet<T> distinctBy<K>(K Function(T element) selector) {
    final seenKeys = <K>{};
    return NonEmptySet._(<T>{
      for (final element in _elements)
        if (seenKeys.add(selector(element))) element,
    });
  }

  @override
  @useResult
  NonEmptyList<T> toNonEmptyList() => NonEmptyList._(_elements.toList());

  @override
  @useResult
  NonEmptySet<T> toNonEmptySet() => this;

  // Set-like.

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

  /// Whether this set contains every element of [other].
  @useResult
  bool containsAll(Iterable<Object?> other) => _elements.containsAll(other);

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
  int get length => _elements.length;

  // Iterable.
  // Delegate to the backing set for its specialized implementations.

  @override
  Iterator<T> get iterator => _elements.iterator;

  @override
  @useResult
  Iterable<R> map<R>(R Function(T element) toElement) =>
      _elements.map(toElement);

  @override
  @useResult
  Iterable<T> where(bool Function(T element) test) => _elements.where(test);

  @override
  @useResult
  Iterable<R> whereType<R>() => _elements.whereType<R>();

  @override
  @useResult
  Iterable<R> expand<R>(Iterable<R> Function(T element) toElements) =>
      _elements.expand(toElements);

  @override
  @useResult
  bool contains(Object? element) => _elements.contains(element);

  @override
  void forEach(void Function(T element) action) => _elements.forEach(action);

  @override
  @useResult
  T reduce(T Function(T value, T element) combine) => _elements.reduce(combine);

  @override
  R fold<R>(R initialValue, R Function(R value, T element) combine) =>
      _elements.fold(initialValue, combine);

  @override
  @useResult
  Iterable<T> followedBy(Iterable<T> other) => _elements.followedBy(other);

  @override
  @useResult
  bool every(bool Function(T element) test) => _elements.every(test);

  @override
  @useResult
  String join([String separator = '']) => _elements.join(separator);

  @override
  @useResult
  bool any(bool Function(T element) test) => _elements.any(test);

  @override
  @useResult
  List<T> toList({bool growable = true}) =>
      _elements.toList(growable: growable);

  @override
  @useResult
  Set<T> toSet() => _elements.toSet();

  @override
  @useResult
  Iterable<T> take(int count) => _elements.take(count);

  @override
  @useResult
  Iterable<T> takeWhile(bool Function(T element) test) =>
      _elements.takeWhile(test);

  @override
  @useResult
  Iterable<T> skip(int count) => _elements.skip(count);

  @override
  @useResult
  Iterable<T> skipWhile(bool Function(T element) test) =>
      _elements.skipWhile(test);

  @override
  @useResult
  T get last => _elements.last;

  @override
  @useResult
  T get single => _elements.single;

  @override
  @useResult
  T firstWhere(bool Function(T element) test, {T Function()? orElse}) =>
      _elements.firstWhere(test, orElse: orElse);

  @override
  @useResult
  T lastWhere(bool Function(T element) test, {T Function()? orElse}) =>
      _elements.lastWhere(test, orElse: orElse);

  @override
  @useResult
  T singleWhere(bool Function(T element) test, {T Function()? orElse}) =>
      _elements.singleWhere(test, orElse: orElse);

  @override
  @useResult
  T elementAt(int index) => _elements.elementAt(index);

  @override
  @useResult
  Iterable<R> cast<R>() => Iterable.castFrom<T, R>(_elements);

  // Object.

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
