part of 'non_empty_collection.dart';

/// An immutable [NonEmptyCollection] that preserves element order and
/// duplicates.
///
/// `NonEmptyList<T>` is an [Iterable] but deliberately not a [List]: the [List]
/// interface declares mutating members that an immutable list could only
/// implement by throwing at run time. Use [asList] to hand the elements to an
/// API that needs a [List], [operator []] to read one by index, and
/// [Iterable.toList] for a modifiable copy.
///
/// Create one with [NonEmptyList.of] when the first element is known
/// statically, or with [IterableToNonEmptyListExtension] when starting from an
/// [Iterable] whose length is only known at run time.
///
/// ```dart
/// void sendNotifications(NonEmptyList<String> recipients) {
///   // `recipients` can never be empty, and nothing can add to it.
///   print('First recipient: ${recipients.head}');
/// }
///
/// sendNotifications(NonEmptyList.of('ada@example.com'));
/// ```
@immutable
final class NonEmptyList<T> extends NonEmptyCollection<T> {
  const NonEmptyList._(this._elements) : super._();

  /// Creates a list containing [head] followed by [tail].
  ///
  /// The elements of [tail] are copied, so later changes to it are not
  /// visible through the returned list.
  ///
  /// ```dart
  /// final single = NonEmptyList.of(1); // [1]
  /// final several = NonEmptyList.of(1, [2, 3]); // [1, 2, 3]
  /// ```
  factory NonEmptyList.of(T head, [Iterable<T> tail = const <Never>[]]) =>
      NonEmptyList._([head, ...tail]);

  // Never handed out directly, and never mutated after construction, which is
  // what makes the unmodifiable view returned by `asList` safe to share.
  final List<T> _elements;

  @override
  @useResult
  T get head => _elements[0];

  /// The elements after [head], as an unmodifiable list.
  ///
  /// Each access creates a snapshot in linear time. The result is empty when
  /// this list has a single element.
  ///
  /// ```dart
  /// NonEmptyList.of(1, [2, 3]).tail; // [2, 3]
  /// ```
  @useResult
  List<T> get tail => List<T>.unmodifiable(_elements.skip(1));

  /// The elements of this list in reverse order.
  ///
  /// ```dart
  /// NonEmptyList.of(1, [2]).reversed; // [2, 1]
  /// ```
  @useResult
  NonEmptyList<T> get reversed =>
      NonEmptyList._(_elements.reversed.toList(growable: false));

  /// The element at [index].
  ///
  /// Reading index `0` never throws. Throws a [RangeError] for any other index
  /// outside `0` until [length] minus one.
  ///
  /// ```dart
  /// NonEmptyList.of(1, [2])[1]; // 2
  /// ```
  @useResult
  T operator [](int index) => _elements[index];

  /// Returns these elements as an unmodifiable [List].
  ///
  /// The result is a view, so it is created in constant time and reflects no
  /// later changes, because this list can never change. Its mutating members
  /// throw [UnsupportedError]; use [Iterable.toList] for a modifiable copy.
  ///
  /// ```dart
  /// void render(List<String> lines) {}
  ///
  /// render(NonEmptyList.of('first').asList());
  /// ```
  @useResult
  List<T> asList() => UnmodifiableListView<T>(_elements);

  @override
  @useResult
  NonEmptyList<T> plus(T element) => NonEmptyList._([..._elements, element]);

  @override
  @useResult
  NonEmptyList<T> plusAll(Iterable<T> elements) =>
      NonEmptyList._([..._elements, ...elements]);

  /// Returns a new list with the elements of [other] appended.
  ///
  /// ```dart
  /// NonEmptyList.of(1) + [2, 3]; // [1, 2, 3]
  /// ```
  @useResult
  NonEmptyList<T> operator +(Iterable<T> other) => plusAll(other);

  @override
  Iterator<T> get iterator => _elements.iterator;

  @override
  @useResult
  int get length => _elements.length;

  @override
  @useResult
  T get first => _elements[0];

  @override
  @useResult
  T get last => _elements[_elements.length - 1];

  @override
  @useResult
  T elementAt(int index) => _elements[index];

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

  @override
  @useResult
  NonEmptyList<T> toNonEmptyList() => this;

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
      if (_elements[index] != other[index]) {
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
  /// The elements are copied, so later changes to this iterable are not
  /// visible through the result.
  ///
  /// ```dart
  /// [1, 2].toNonEmptyListOrNull(); // [1, 2]
  /// <int>[].toNonEmptyListOrNull(); // null
  /// ```
  @useResult
  NonEmptyList<T>? toNonEmptyListOrNull() {
    final elements = toList();
    return elements.isEmpty ? null : NonEmptyList._(elements);
  }

  /// Returns these elements as an [Option] of [NonEmptyList].
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
