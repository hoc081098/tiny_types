part of 'non_empty_iterable.dart';

/// An immutable [NonEmptyIterable] that models a set guaranteed to contain at
/// least one element. It keeps unique values in first-occurrence order.
///
/// ## Creating a set
///
/// [NonEmptySet.of] takes a required first element, so the result cannot be
/// empty. Equal values are kept only once, in first-occurrence order. For a
/// possibly empty [Iterable], [IterableToNonEmptySetExtension] provides
/// `toNonEmptySetOrNull()`, `toNonEmptySetOrNone()`, and
/// `toNonEmptySetOrThrow()`.
///
/// ```dart
/// final tags = NonEmptySet.of('dart', ['dart', 'types']);
/// tags.toList(); // ['dart', 'types']
/// ```
///
/// ## Read-only set operations
///
/// Use [containsAll] and [lookup] as read-only set queries; [union] combines
/// two non-empty sets into another [NonEmptySet]. This type does not implement
/// [Set], whose interface includes mutating members. [asSet]
/// provides an unmodifiable [Set] view for APIs requiring one or for
/// operations such as intersection and difference that may be empty.
/// [Iterable.toSet] creates a modifiable copy. [plus] and [plusAll] return new
/// non-empty sets without changing this one.
///
/// ## Transformations and equality
///
/// Standard [Iterable] operations delegate to the backing set. In particular,
/// [map], [where], and [expand] remain lazy and return plain [Iterable]
/// results.
/// Use [mapToNonEmptySet] or [flatMapToNonEmptySet] when the result must stay
/// non-empty and equal results should be collapsed. Iteration preserves
/// first-occurrence order, but equality ignores order; a plain [Set] is not
/// equal to a [NonEmptySet].
@immutable
final class NonEmptySet<T> extends NonEmptyIterable<T> {
  /// Wraps a set without copying it.
  ///
  /// The caller must keep the set non-empty and never mutate it afterward.
  NonEmptySet._wrap(this._elements)
      : assert(
          _elements.isNotEmpty,
          'NonEmptySet must have at least one element',
        ),
        super._();

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
      NonEmptySet._wrap(<T>{head, ...tail});

  // Never handed out directly, and never mutated after construction, which is
  // what makes the unmodifiable view returned by `asSet` safe to share.
  final Set<T> _elements;

  // NonEmptyIterable.

  @override
  @useResult
  T get head => _elements.first;

  @override
  @useResult
  NonEmptySet<T> plus(T element) =>
      NonEmptySet._wrap(<T>{..._elements, element});

  @override
  @useResult
  NonEmptySet<T> plusAll(Iterable<T> elements) =>
      NonEmptySet._wrap(<T>{..._elements, ...elements});

  @override
  @useResult
  NonEmptySet<T> distinct() => this;

  @override
  @useResult
  NonEmptySet<T> distinctBy<K>(K Function(T element) selector) {
    final seenKeys = HashSet<K>();
    return NonEmptySet._wrap(<T>{
      for (final element in _elements)
        if (seenKeys.add(selector(element))) element,
    });
  }

  @override
  @useResult
  NonEmptyList<T> toNonEmptyList() =>
      NonEmptyList._wrap(_elements.toList(growable: false));

  @override
  @useResult
  NonEmptySet<T> toNonEmptySet() => this;

  /// Returns these elements as an unmodifiable [Set].
  ///
  /// The view is created in constant time and remains unchanged because this
  /// set is immutable. Its mutating members throw [UnsupportedError]; use
  /// [Iterable.toSet] for a modifiable copy.
  ///
  /// ```dart
  /// final tags = NonEmptySet.of('dart', ['types']);
  ///
  /// tags.asSet().intersection({'dart'}); // {dart}
  /// tags.asSet().difference({'dart'}); // {types}
  /// ```
  @useResult
  Set<T> asSet() => UnmodifiableSetView<T>(_elements);

  // Set-like.

  /// Whether this set contains every element of [other], as in
  /// [Set.containsAll].
  @useResult
  bool containsAll(Iterable<Object?> other) => _elements.containsAll(other);

  /// Returns a new [NonEmptySet] containing the elements of both sets.
  ///
  /// Like [Set.union], equal elements occur only once. This set's elements
  /// come first in iteration order, followed by new elements from [other].
  /// Neither input changes, and the result is always non-empty.
  /// A covariantly widened receiver may reject [other] at runtime; use
  /// [castToNonEmptySet] to copy it with the intended runtime element type.
  ///
  /// ```dart
  /// NonEmptySet.of(2, [1]).union(NonEmptySet.of(1, [3])); // {2, 1, 3}
  /// ```
  @useResult
  NonEmptySet<T> union(NonEmptySet<T> other) =>
      NonEmptySet._wrap(_elements.union(other._elements));

  /// The element equal to [element], or `null` when there is none, as in
  /// [Set.lookup].
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
  @useResult
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
          _elements.containsAll(other._elements);

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
  /// An existing [NonEmptySet] with the exact element type is returned
  /// unchanged. Other non-empty iterables are copied, so later changes to
  /// them are not visible through the result.
  ///
  /// ```dart
  /// [1, 2, 1].toNonEmptySetOrNull(); // {1, 2}
  /// <int>[].toNonEmptySetOrNull(); // null
  /// ```
  @useResult
  NonEmptySet<T>? toNonEmptySetOrNull() {
    final self = this;
    if (self is NonEmptySet<T> && self._hasExactElementType(T)) {
      return self;
    }
    final elements = Set<T>.of(this);
    return elements.isEmpty ? null : NonEmptySet._wrap(elements);
  }

  /// Returns these elements as an [Option] of [NonEmptySet].
  ///
  /// Conversion follows [toNonEmptySetOrNull], including its reuse behavior.
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
  /// Conversion follows [toNonEmptySetOrNull], including its reuse behavior.
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
