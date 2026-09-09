import 'dart:collection';

import 'package:meta/meta.dart';

import 'option.dart';

part 'non_empty_list.dart';
part 'non_empty_set.dart';

/// An [Iterable] that always contains at least one element.
///
/// `NonEmptyCollection<T>` moves the "at least one element" requirement into
/// the type system, so an API can demand it once instead of validating it at
/// every call site. It also turns the partial operations of [Iterable] into
/// total ones: [Iterable.first], [Iterable.last], and [Iterable.reduce] can
/// never throw for a non-empty collection.
///
/// [NonEmptyList] and [NonEmptySet] are the two implementations. Neither is a
/// [List] nor a [Set], deliberately: those interfaces declare mutating members
/// that an immutable non-empty collection could only implement by throwing at
/// run time. Only operations that preserve non-emptiness are declared here;
/// reach for [NonEmptyList.asList] or [NonEmptySet.asSet] to hand the elements
/// to an API that needs the plain type, and for [Iterable.toList] or
/// [Iterable.toSet] to get a modifiable copy.
///
/// Operations that have to preserve element order and duplicates return a
/// [NonEmptyList], while [plus] and [plusAll] return the same kind of
/// collection as their receiver.
///
/// ```dart
/// void notifyAll(NonEmptyCollection<String> recipients) {
///   // `head` and `reduce` cannot fail here.
///   print('Notifying ${recipients.head} and ${recipients.length - 1} more');
/// }
/// ```
sealed class NonEmptyCollection<T> extends Iterable<T> {
  const NonEmptyCollection._();

  /// The first element of this collection.
  ///
  /// Unlike [Iterable.first], this never throws.
  ///
  /// ```dart
  /// NonEmptyList.of(1, [2, 3]).head; // 1
  /// ```
  @useResult
  T get head;

  /// Always `false`.
  @override
  @useResult
  bool get isEmpty => false;

  /// Always `true`.
  @override
  @useResult
  bool get isNotEmpty => true;

  /// Returns a new collection with [element] appended to this one.
  ///
  /// ```dart
  /// NonEmptyList.of(1).plus(2); // [1, 2]
  /// ```
  @useResult
  NonEmptyCollection<T> plus(T element);

  /// Returns a new collection with every value of [elements] appended.
  ///
  /// ```dart
  /// NonEmptyList.of(1).plusAll([2, 3]); // [1, 2, 3]
  /// ```
  @useResult
  NonEmptyCollection<T> plusAll(Iterable<T> elements);

  /// Returns the elements of this collection without duplicates.
  ///
  /// The first occurrence of each element is kept, in iteration order.
  ///
  /// ```dart
  /// NonEmptyList.of(1, [2, 1]).distinct(); // [1, 2]
  /// ```
  @useResult
  NonEmptyList<T> distinct() => distinctBy<T>((element) => element);

  /// Returns the elements whose [selector] value is seen for the first time.
  ///
  /// [selector] is called exactly once per element, in iteration order.
  ///
  /// ```dart
  /// NonEmptyList.of('one', ['three', 'two'])
  ///     .distinctBy((word) => word.length); // ['one', 'three']
  /// ```
  @useResult
  NonEmptyList<T> distinctBy<K>(K Function(T element) selector) {
    final seenKeys = <K>{};
    return NonEmptyList._([
      for (final element in this)
        if (seenKeys.add(selector(element))) element,
    ]);
  }

  /// Transforms every element with [toElement].
  ///
  /// Unlike [Iterable.map], the result is computed eagerly, because the
  /// returned collection has to be known to be non-empty.
  ///
  /// ```dart
  /// NonEmptyList.of(1, [2]).map((value) => value * 2); // [2, 4]
  /// ```
  @override
  @useResult
  NonEmptyList<R> map<R>(R Function(T element) toElement) =>
      NonEmptyList._([for (final element in this) toElement(element)]);

  /// Transforms every element with its iteration index.
  ///
  /// ```dart
  /// NonEmptyList.of('a', ['b'])
  ///     .mapIndexed((index, letter) => '$index$letter'); // ['0a', '1b']
  /// ```
  @useResult
  NonEmptyList<R> mapIndexed<R>(
    R Function(int index, T element) toElement,
  ) =>
      NonEmptyList._([
        for (final (index, element) in indexed) toElement(index, element),
      ]);

  /// Concatenates the collections produced by [toElements].
  ///
  /// Because each result is itself non-empty, the concatenation is non-empty.
  ///
  /// ```dart
  /// NonEmptyList.of(1, [2])
  ///     .flatMap((value) => NonEmptyList.of(value, [-value]));
  /// // [1, -1, 2, -2]
  /// ```
  @useResult
  NonEmptyList<R> flatMap<R>(
    NonEmptyCollection<R> Function(T element) toElements,
  ) =>
      NonEmptyList._([
        for (final element in this) ...toElements(element),
      ]);

  /// Pairs each element with the element of [other] at the same position.
  ///
  /// The result is as long as the shorter of the two collections.
  ///
  /// ```dart
  /// final pairs = NonEmptyList.of(1, [2]).zip(NonEmptyList.of('a', ['b']));
  /// // [(1, 'a'), (2, 'b')]
  /// ```
  @useResult
  NonEmptyList<(T, R)> zip<R>(NonEmptyCollection<R> other) =>
      zipWith(other, (element, otherElement) => (element, otherElement));

  /// Combines each element with the element of [other] at the same position.
  ///
  /// [combine] is called once per resulting element, so it is called at least
  /// once. The result is as long as the shorter of the two collections.
  ///
  /// ```dart
  /// NonEmptyList.of(1, [2]).zipWith(
  ///   NonEmptyList.of(10, [20]),
  ///   (left, right) => left + right,
  /// );
  /// // [11, 22]
  /// ```
  @useResult
  NonEmptyList<R> zipWith<R, U>(
    NonEmptyCollection<U> other,
    R Function(T element, U otherElement) combine,
  ) {
    final otherIterator = other.iterator;
    final combined = <R>[];
    for (final element in this) {
      if (!otherIterator.moveNext()) {
        break;
      }
      combined.add(combine(element, otherIterator.current));
    }
    return NonEmptyList._(combined);
  }

  /// Returns the element with the smallest [selector] value.
  ///
  /// The first element wins when several elements share the smallest value.
  ///
  /// ```dart
  /// NonEmptyList.of('one', ['three'])
  ///     .minBy((word) => word.length); // 'one'
  /// ```
  @useResult
  T minBy<K extends Comparable<Object>>(K Function(T element) selector) =>
      _extremeBy(selector, keepGreater: false);

  /// Returns the element with the largest [selector] value.
  ///
  /// The first element wins when several elements share the largest value.
  ///
  /// ```dart
  /// NonEmptyList.of('one', ['three'])
  ///     .maxBy((word) => word.length); // 'three'
  /// ```
  @useResult
  T maxBy<K extends Comparable<Object>>(K Function(T element) selector) =>
      _extremeBy(selector, keepGreater: true);

  T _extremeBy<K extends Comparable<Object>>(
    K Function(T element) selector, {
    required bool keepGreater,
  }) {
    var best = head;
    var bestKey = selector(best);
    for (final element in skip(1)) {
      final key = selector(element);
      final comparison = key.compareTo(bestKey);
      if (keepGreater ? comparison > 0 : comparison < 0) {
        best = element;
        bestKey = key;
      }
    }
    return best;
  }

  /// Returns these elements as a [NonEmptyList], preserving iteration order.
  ///
  /// The result is always a copy.
  ///
  /// ```dart
  /// NonEmptySet.of(1, [2]).toNonEmptyList(); // [1, 2]
  /// ```
  @useResult
  NonEmptyList<T> toNonEmptyList() => NonEmptyList._(toList());

  /// Returns these elements as a [NonEmptySet], discarding duplicates.
  ///
  /// The result is always a copy.
  ///
  /// ```dart
  /// NonEmptyList.of(1, [2, 1]).toNonEmptySet(); // {1, 2}
  /// ```
  @useResult
  NonEmptySet<T> toNonEmptySet() => NonEmptySet._(toSet());
}

/// Adds one-level flattening to nested non-empty collections.
extension FlattenNonEmptyCollectionExtension<T>
    on NonEmptyCollection<NonEmptyCollection<T>> {
  /// Concatenates the nested collections into a single [NonEmptyList].
  ///
  /// ```dart
  /// final nested = NonEmptyList.of(
  ///   NonEmptyList.of(1, [2]),
  ///   [NonEmptyList.of(3)],
  /// );
  /// nested.flatten(); // [1, 2, 3]
  /// ```
  @useResult
  NonEmptyList<T> flatten() => flatMap((elements) => elements);
}

/// Adds pair splitting to non-empty collections of records.
extension UnzipNonEmptyCollectionExtension<A, B> on NonEmptyCollection<(A, B)> {
  /// Splits the pairs into one collection per record field.
  ///
  /// ```dart
  /// final (numbers, letters) =
  ///     NonEmptyList.of((1, 'a'), [(2, 'b')]).unzip();
  /// // ([1, 2], ['a', 'b'])
  /// ```
  @useResult
  (NonEmptyList<A>, NonEmptyList<B>) unzip() => (
        NonEmptyList._([for (final (first, _) in this) first]),
        NonEmptyList._([for (final (_, second) in this) second]),
      );
}

/// Adds total minimum and maximum queries to comparable elements.
extension ComparableNonEmptyCollectionExtension<T extends Comparable<Object>>
    on NonEmptyCollection<T> {
  /// Returns the smallest element.
  ///
  /// Unlike [Iterable.reduce] on a plain iterable, this never throws.
  ///
  /// ```dart
  /// NonEmptyList.of(3, [1, 2]).min(); // 1
  /// ```
  @useResult
  T min() => reduce((left, right) => left.compareTo(right) <= 0 ? left : right);

  /// Returns the largest element.
  ///
  /// Unlike [Iterable.reduce] on a plain iterable, this never throws.
  ///
  /// ```dart
  /// NonEmptyList.of(3, [1, 2]).max(); // 3
  /// ```
  @useResult
  T max() => reduce((left, right) => left.compareTo(right) >= 0 ? left : right);
}
