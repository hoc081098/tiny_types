part of 'non_empty_iterable.dart';

/// An immutable [NonEmptyIterable] that models an ordered list guaranteed to
/// contain at least one element. It preserves duplicates.
///
/// ## Creating a list
///
/// [NonEmptyList.of] takes a required first element, so the result cannot be
/// empty. For a possibly empty [Iterable], [IterableToNonEmptyListExtension]
/// provides `toNonEmptyListOrNull()`, `toNonEmptyListOrNone()`, and
/// `toNonEmptyListOrThrow()`.
///
/// ```dart
/// final recipients = NonEmptyList.of('ada@example.com', tail: [
///   'grace@example.com',
/// ]);
/// recipients.head; // 'ada@example.com'
/// ```
///
/// ## Read-only list operations
///
/// Use [operator []], [indexOf], and [reversed] as with a [List].
/// [NonEmptyList] does not implement [List], whose interface includes mutating
/// members. [asList] provides an unmodifiable [List] view for APIs requiring
/// one; [Iterable.toList] creates a modifiable copy. [plus] and [plusAll]
/// return new non-empty lists without changing this one.
///
/// ## Transformations and equality
///
/// Standard [Iterable] operations delegate to the backing list. In particular,
/// [map], [where], and [expand] remain lazy and return plain [Iterable]
/// results.
/// Use [mapToNonEmptyList] or [flatMapToNonEmptyList] when the result must stay
/// non-empty. Two non-empty lists are equal when their elements compare equal
/// in the same order; a plain [List] is not equal to a [NonEmptyList].
@immutable
final class NonEmptyList<T> extends NonEmptyIterable<T> {
  /// Wraps a list without copying it.
  ///
  /// The caller must keep the list non-empty and never mutate it afterward.
  NonEmptyList._wrap(this._elements)
      : assert(
          _elements.isNotEmpty,
          'NonEmptyList must have at least one element',
        ),
        super._();

  /// Creates a list containing [head] followed by [tail].
  ///
  /// The elements of [tail] are copied, so later changes to it are not
  /// visible through the returned list.
  ///
  /// ```dart
  /// final single = NonEmptyList.of(1); // [1]
  /// final several = NonEmptyList.of(1, tail: [2, 3]); // [1, 2, 3]
  /// ```
  factory NonEmptyList.of(
    T head, {
    Iterable<T> tail = const <Never>[],
  }) =>
      NonEmptyList._wrap([head, ...tail]);

  // Never handed out directly, and never mutated after construction, which is
  // what makes the unmodifiable view returned by `asList` safe to share.
  final List<T> _elements;

  // NonEmptyIterable.

  @override
  @useResult
  T get head => _elements[0];

  /// The elements after [head], as a lazy [Iterable].
  ///
  /// The result is empty when this list has a single element.
  ///
  /// ```dart
  /// NonEmptyList.of(1, tail: [2, 3]).tail.toList(); // [2, 3]
  /// ```
  @override
  @useResult
  Iterable<T> get tail => _elements.skip(1);

  @override
  @useResult
  NonEmptyList<T> plus(T element) =>
      NonEmptyList._wrap([..._elements, element]);

  @override
  @useResult
  NonEmptyList<T> plusAll(Iterable<T> elements) =>
      NonEmptyList._wrap([..._elements, ...elements]);

  @override
  @useResult
  NonEmptyList<T> distinct() => distinctBy<T>(_identity);

  @override
  @useResult
  NonEmptyList<T> distinctBy<K>(K Function(T element) selector) {
    final seenKeys = HashSet<K>();
    return NonEmptyList._wrap([
      for (final element in _elements)
        if (seenKeys.add(selector(element))) element,
    ]);
  }

  @override
  @useResult
  NonEmptyList<T> toNonEmptyList() => this;

  @override
  @useResult
  NonEmptySet<T> toNonEmptySet() => NonEmptySet._wrap(_elements.toSet());

  /// Returns these elements as an unmodifiable [List].
  ///
  /// The view is created in constant time and remains unchanged because this
  /// list is immutable. Its mutating members throw [UnsupportedError]; use
  /// [Iterable.toList] for a modifiable copy.
  ///
  /// ```dart
  /// void render(List<String> lines) {}
  ///
  /// render(NonEmptyList.of('first').asList());
  /// ```
  @useResult
  List<T> asList() => UnmodifiableListView<T>(_elements);

  // List-like.

  /// The element at [index].
  ///
  /// Reading index `0` never throws. Throws a [RangeError] for any other index
  /// outside `0` until [length] minus one.
  ///
  /// ```dart
  /// NonEmptyList.of(1, tail: [2])[1]; // 2
  /// ```
  @useResult
  T operator [](int index) => _elements[index];

  /// Returns a new [NonEmptyList] with the elements of [other] appended.
  ///
  /// Like [List.+], this does not change the original list. See [plusAll] for
  /// the runtime type check that applies to a covariantly widened receiver.
  ///
  /// ```dart
  /// NonEmptyList.of(1) + [2, 3]; // [1, 2, 3]
  /// ```
  @useResult
  NonEmptyList<T> operator +(Iterable<T> other) => plusAll(other);

  /// The elements of this list in reverse order, as a lazy [Iterable].
  ///
  /// Like [List.reversed], this does not change the original list. The result
  /// is non-empty, though its return type does not encode that guarantee.
  ///
  /// ```dart
  /// NonEmptyList.of(1, tail: [2]).reversed.toList(); // [2, 1]
  /// ```
  @useResult
  Iterable<T> get reversed => _elements.reversed;

  @override
  @useResult
  int get length => _elements.length;

  /// The first index of [element] at or after [start], or `-1` if absent.
  ///
  /// [start] follows the same rules as [List.indexOf].
  @useResult
  int indexOf(T element, [int start = 0]) => _elements.indexOf(element, start);

  /// The last index of [element] at or before [start], or `-1` if absent.
  ///
  /// Omitting [start] searches from the end, as in [List.lastIndexOf].
  @useResult
  int lastIndexOf(T element, [int? start]) =>
      _elements.lastIndexOf(element, start);

  /// The first index at or after [start] matching [test], or `-1` if none.
  ///
  /// [start] follows the same rules as [List.indexWhere].
  @useResult
  int indexWhere(bool Function(T element) test, [int start = 0]) =>
      _elements.indexWhere(test, start);

  /// The last index at or before [start] matching [test], or `-1` if none.
  ///
  /// Omitting [start] searches from the end, as in [List.lastIndexWhere].
  @useResult
  int lastIndexWhere(bool Function(T element) test, [int? start]) =>
      _elements.lastIndexWhere(test, start);

  // Iterable.
  // Delegate to the backing list for its specialized implementations.

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
  T get last => _elements[_elements.length - 1];

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
  T elementAt(int index) => _elements[index];

  @override
  @useResult
  Iterable<R> cast<R>() => Iterable.castFrom<T, R>(_elements);

  // Object.

  /// Whether [other] is a `NonEmptyList` with equal elements in equal order.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! NonEmptyList<Object?> || length != other.length) {
      return false;
    }
    for (var index = 0; index < length; index++) {
      if (_elements[index] != other._elements[index]) {
        return false;
      }
    }
    return true;
  }

  /// A hash code derived from every element, in order.
  @override
  int get hashCode => Object.hashAll(_elements);

  /// Returns the elements in list form, such as `[1, 2, 3]`.
  @override
  String toString() => _elements.toString();
}

/// Adds non-empty list conversions to any [Iterable].
extension IterableToNonEmptyListExtension<T> on Iterable<T> {
  /// Returns these elements as a [NonEmptyList], or `null` when empty.
  ///
  /// An existing [NonEmptyList] with the exact element type is returned
  /// unchanged. Other non-empty iterables are copied, so later changes to
  /// them are not visible through the result.
  ///
  /// ```dart
  /// [1, 2].toNonEmptyListOrNull(); // [1, 2]
  /// <int>[].toNonEmptyListOrNull(); // null
  /// ```
  @useResult
  NonEmptyList<T>? toNonEmptyListOrNull() {
    final self = this;
    if (self is NonEmptyList<T> && self._hasExactElementType(T)) {
      return self;
    }
    final elements = List<T>.unmodifiable(this);
    return elements.isEmpty ? null : NonEmptyList._wrap(elements);
  }

  /// Returns these elements as an [Option] of [NonEmptyList].
  ///
  /// Conversion follows [toNonEmptyListOrNull], including its reuse behavior.
  ///
  /// ```dart
  /// [1, 2].toNonEmptyListOrNone(); // Option.Some([1, 2])
  /// <int>[].toNonEmptyListOrNone(); // Option.None
  /// ```
  @useResult
  Option<NonEmptyList<T>> toNonEmptyListOrNone() =>
      toNonEmptyListOrNull().toOption();

  /// Returns these elements as a [NonEmptyList].
  ///
  /// Conversion follows [toNonEmptyListOrNull], including its reuse behavior.
  ///
  /// Throws a [StateError] when this iterable is empty. Prefer
  /// [toNonEmptyListOrNull] or [toNonEmptyListOrNone] when emptiness is a
  /// normal outcome.
  ///
  /// ```dart
  /// [1, 2].toNonEmptyListOrThrow(); // [1, 2]
  /// ```
  @useResult
  NonEmptyList<T> toNonEmptyListOrThrow() =>
      toNonEmptyListOrNull() ??
      (throw StateError('Cannot create a NonEmptyList from an empty '
          'iterable.'));
}
