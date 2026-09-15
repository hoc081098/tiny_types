import 'dart:collection';

import 'package:meta/meta.dart';

import 'option.dart';

part 'non_empty_list.dart';

part 'non_empty_set.dart';

/// An [Iterable] that always contains at least one element.
///
/// ## Non-empty guarantee
///
/// `NonEmptyIterable<T>` moves the "at least one element" requirement into
/// the type system, so an API can demand it once instead of validating it at
/// every call site. As a result, [Iterable.first], [Iterable.last], and
/// [Iterable.reduce] cannot fail due to an empty receiver.
///
/// ```dart
/// void notifyAll(NonEmptyIterable<String> recipients) {
///   // `head` is always available.
///   print('Notifying ${recipients.head} and ${recipients.length - 1} more');
/// }
/// ```
///
/// The strengthened operations follow Arrow's non-empty collection
/// conventions, adapted to Dart's lazy [Iterable] contract:
/// https://arrow-kt.io/learn/collections-functions/non-empty/
///
/// ## Read-only collection interfaces
///
/// [NonEmptyList] and [NonEmptySet] implement [Iterable] and provide read-only
/// list-like and set-like operations, respectively. Neither implements [List]
/// or [Set]; operations such as [plus] and [plusAll] return new collections
/// instead of changing the originals.
///
/// [NonEmptyList.asList] and [NonEmptySet.asSet] provide unmodifiable views
/// when an API requires a [List] or [Set]. [Iterable.toList] and
/// [Iterable.toSet] create modifiable copies.
///
/// The separation from mutable [List] and [Set] interfaces follows the
/// approach used by built_collection: https://pub.dev/packages/built_collection
///
/// ## Transformations
///
/// Inherited transformations such as [map], [where], and [expand] keep the
/// standard lazy [Iterable] semantics. Their return type no longer represents
/// the non-empty guarantee, and filtering or expanding may actually produce no
/// elements.
///
/// Non-empty-preserving transformations such as
/// [mapIndexedToNonEmptyList] and [flatMapToNonEmptyList] eagerly materialize a
/// [NonEmptyList]. A `ToNonEmptySet` variant is available when equal results
/// should be collapsed.
///
/// [plus] and [plusAll] return the same kind of collection as their receiver.
sealed class NonEmptyIterable<T> extends Iterable<T> {
  const NonEmptyIterable._();

  bool _hasExactElementType(Type type) => T == type;

  //region Non-empty guarantee

  /// The first element of this collection.
  ///
  /// Unlike [Iterable.first], this never throws.
  ///
  /// ```dart
  /// NonEmptyList.of(1, tail: [2, 3]).head; // 1
  /// ```
  @useResult
  T get head;

  /// The elements after [head], in iteration order.
  ///
  /// The result is a lazy [Iterable] and is empty when this collection has a
  /// single element.
  ///
  /// ```dart
  /// NonEmptyList.of(1, tail: [2, 3]).tail.toList(); // [2, 3]
  /// NonEmptySet.of(1, tail: [2, 3]).tail.toList(); // [2, 3]
  /// ```
  @useResult
  Iterable<T> get tail;

  @override
  @nonVirtual
  @useResult
  T get first => head;

  /// Always `false`.
  @override
  @nonVirtual
  @useResult
  bool get isEmpty => false;

  /// Always `true`.
  @override
  @nonVirtual
  @useResult
  bool get isNotEmpty => true;

  //endregion

  // --------------------------------------------------------------------------

  //region Operations that return the same kind of collection

  /// Returns a new collection with [element] added.
  ///
  /// A [NonEmptySet] keeps only one occurrence of an equal element.
  /// A covariantly widened receiver may still reject [element] at runtime.
  /// Use [castToNonEmptyList] or [castToNonEmptySet] to copy it with a wider
  /// runtime element type before adding the element.
  ///
  /// ```dart
  /// NonEmptyList.of(1).plus(2); // [1, 2]
  ///
  /// NonEmptySet.of(1).plus(2); // {1, 2}
  /// NonEmptySet.of(1).plus(1); // {1}
  /// ```
  @useResult
  NonEmptyIterable<T> plus(T element);

  /// Returns a new collection with all [elements] added.
  ///
  /// A [NonEmptySet] keeps only the first occurrence of each element.
  /// A covariantly widened receiver may still reject [elements] at runtime.
  /// Use [castToNonEmptyList] or [castToNonEmptySet] to copy it with a wider
  /// runtime element type before adding the elements.
  ///
  /// ```dart
  /// NonEmptyList.of(1).plusAll([2, 3]); // [1, 2, 3]
  ///
  /// NonEmptySet.of(1).plusAll([1, 2, 3]); // {1, 2, 3}
  /// ```
  @useResult
  NonEmptyIterable<T> plusAll(Iterable<T> elements);

  /// Returns the elements of this iterable without duplicates.
  ///
  /// The result has the same concrete kind as this iterable. The first
  /// occurrence of each element is kept, in iteration order.
  ///
  /// ```dart
  /// NonEmptyList.of(1, tail: [2, 1]).distinct(); // [1, 2]
  ///
  /// final nes = NonEmptySet.of(1, tail: [2, 3]);
  /// nes.distinct(); // {1, 2, 3}
  /// identical(nes, nes.distinct()); // true
  /// ```
  @useResult
  NonEmptyIterable<T> distinct();

  /// Returns the elements whose [selector] value is seen for the first time.
  ///
  /// The result has the same concrete kind as this iterable. [selector] is
  /// called exactly once per element, in iteration order.
  ///
  /// ```dart
  /// NonEmptyList.of('one', tail: ['three', 'two'])
  ///     .distinctBy((word) => word.length); // ['one', 'three']
  ///
  /// final nes = NonEmptySet.of(-1, tail: [-2, -3, 1, 2, 3]);
  /// // {-1, -2, -3, 1, 2, 3}
  /// nes.distinctBy((n) => n.abs()); // {-1, -2, -3}
  /// ```
  @useResult
  NonEmptyIterable<T> distinctBy<K>(K Function(T element) selector);

  //endregion

  // --------------------------------------------------------------------------

  //region Conversion between concrete NonEmptyIterable types.
  /// Returns these elements as a [NonEmptyList], preserving iteration order.
  ///
  /// Returns this object unchanged when it is already a [NonEmptyList].
  /// Otherwise, eagerly materializes a new list in iteration order.
  ///
  /// ```dart
  /// NonEmptySet.of(1, tail: [2]).toNonEmptyList(); // [1, 2]
  /// ```
  @useResult
  NonEmptyList<T> toNonEmptyList();

  /// Returns these elements as a [NonEmptySet], discarding duplicates.
  ///
  /// Returns this object unchanged when it is already a [NonEmptySet].
  /// Otherwise, eagerly materializes a new set in first-occurrence order.
  ///
  /// ```dart
  /// NonEmptyList.of(1, tail: [2, 1]).toNonEmptySet(); // {1, 2}
  /// ```
  @useResult
  NonEmptySet<T> toNonEmptySet();

  /// Casts the elements to [R] in a new [NonEmptyList].
  ///
  /// Unlike the lazy view returned by [Iterable.cast], this eagerly copies
  /// the elements in iteration order. The result has [R] as its runtime
  /// element type, even when this collection already contains only [R] values.
  /// Throws a [TypeError] immediately if any element is not an [R].
  ///
  /// This is useful after covariance widens a collection's static element
  /// type but leaves its runtime element type narrower: [plus] and [plusAll]
  /// would still check arguments against that narrower type.
  ///
  /// ```dart
  /// final NonEmptyIterable<num> numbers = NonEmptyList<int>.of(1);
  /// numbers.castToNonEmptyList<num>().plus(1.5); // [1, 1.5]
  /// ```
  @useResult
  @nonVirtual
  NonEmptyList<R> castToNonEmptyList<R>() =>
      mapToNonEmptyList<R>((element) => element as R);

  /// Casts the elements to [R] in a new [NonEmptySet].
  ///
  /// Unlike the lazy view returned by [Iterable.cast], this eagerly copies
  /// the elements, keeping the first occurrence of each value in iteration
  /// order. The result has [R] as its runtime element type, even when this
  /// collection already contains only [R] values. Throws a [TypeError]
  /// immediately if any element is not an [R].
  ///
  /// This is useful after covariance widens a collection's static element
  /// type but leaves its runtime element type narrower: [plus] and [plusAll]
  /// would still check arguments against that narrower type.
  ///
  /// ```dart
  /// final NonEmptyIterable<num> numbers = NonEmptySet<int>.of(1);
  /// numbers.castToNonEmptySet<num>().plus(1.5); // {1, 1.5}
  /// ```
  @useResult
  @nonVirtual
  NonEmptySet<R> castToNonEmptySet<R>() =>
      mapToNonEmptySet<R>((element) => element as R);

  //endregion

  // --------------------------------------------------------------------------

  //region Non-empty-preserving transformations

  /// Transforms every element into a new [NonEmptyList].
  ///
  /// The result is computed eagerly. Use [map] for a lazy [Iterable] instead.
  ///
  /// ```dart
  /// NonEmptyList.of(1, tail: [2])
  ///     .mapToNonEmptyList((value) => value * 2); // [2, 4]
  /// ```
  @useResult
  @nonVirtual
  NonEmptyList<R> mapToNonEmptyList<R>(
    R Function(T element) toElement,
  ) =>
      NonEmptyList._wrap([for (final element in this) toElement(element)]);

  /// Transforms every element into a new [NonEmptySet].
  ///
  /// The result is computed eagerly, and equal transformed elements are
  /// collapsed. Use [map] for a lazy [Iterable] that preserves duplicates.
  ///
  /// ```dart
  /// NonEmptyList.of(1, tail: [2])
  ///     .mapToNonEmptySet((value) => value.isEven); // {false, true}
  /// ```
  @useResult
  @nonVirtual
  NonEmptySet<R> mapToNonEmptySet<R>(
    R Function(T element) toElement,
  ) =>
      NonEmptySet._wrap(<R>{
        for (final element in this) toElement(element),
      });

  /// Transforms every element with its iteration index into a
  /// [NonEmptyList].
  ///
  /// The result is computed eagerly. This name is deliberately distinct from
  /// `package:collection`'s lazy `mapIndexed` extension.
  ///
  /// ```dart
  /// NonEmptyList.of('a', tail: ['b'])
  ///     .mapIndexedToNonEmptyList(
  ///       (index, letter) => '$index$letter',
  ///     ); // ['0a', '1b']
  /// ```
  @useResult
  @nonVirtual
  NonEmptyList<R> mapIndexedToNonEmptyList<R>(
    R Function(int index, T element) toElement,
  ) =>
      NonEmptyList._wrap([
        for (final (index, element) in indexed) toElement(index, element),
      ]);

  /// Transforms every element with its iteration index into a [NonEmptySet].
  ///
  /// The result is computed eagerly, and equal transformed elements are
  /// collapsed.
  ///
  /// ```dart
  /// NonEmptyList.of('a', tail: ['b'])
  ///     .mapIndexedToNonEmptySet(
  ///       (index, letter) => '$index$letter',
  ///     ); // {'0a', '1b'}
  /// ```
  @useResult
  @nonVirtual
  NonEmptySet<R> mapIndexedToNonEmptySet<R>(
    R Function(int index, T element) toElement,
  ) =>
      NonEmptySet._wrap(<R>{
        for (final (index, element) in indexed) toElement(index, element),
      });

  /// Concatenates the collections produced by [toElements] into a
  /// [NonEmptyList].
  ///
  /// The result is computed eagerly. Because each result is itself non-empty,
  /// the concatenation is non-empty.
  ///
  /// ```dart
  /// NonEmptyList.of(1, tail: [2])
  ///     .flatMapToNonEmptyList(
  ///       (value) => NonEmptyList.of(value, tail: [-value]),
  ///     );
  /// // [1, -1, 2, -2]
  /// ```
  @useResult
  @nonVirtual
  NonEmptyList<R> flatMapToNonEmptyList<R>(
    NonEmptyIterable<R> Function(T element) toElements,
  ) =>
      NonEmptyList._wrap([
        for (final element in this) ...toElements(element),
      ]);

  /// Concatenates the collections produced by [toElements] into a
  /// [NonEmptySet].
  ///
  /// The result is computed eagerly. Because each result is itself non-empty,
  /// the result is non-empty; equal elements are collapsed.
  ///
  /// ```dart
  /// NonEmptyList.of(1, tail: [2])
  ///     .flatMapToNonEmptySet(
  ///       (value) => NonEmptyList.of(value, tail: [-value]),
  ///     );
  /// // {1, -1, 2, -2}
  /// ```
  @useResult
  @nonVirtual
  NonEmptySet<R> flatMapToNonEmptySet<R>(
    NonEmptyIterable<R> Function(T element) toElements,
  ) =>
      NonEmptySet._wrap(<R>{
        for (final element in this) ...toElements(element),
      });

  /// Pairs each element with the element of [other] at the same position.
  ///
  /// The result is as long as the shorter of the two collections.
  ///
  /// ```dart
  /// final pairs = NonEmptyList.of(1, tail: [2])
  ///     .zip(NonEmptyList.of('a', tail: ['b', 'c']));
  /// // [(1, 'a'), (2, 'b')]
  /// ```
  @useResult
  @nonVirtual
  NonEmptyList<(T, R)> zip<R>(NonEmptyIterable<R> other) =>
      zipWith(other, (element, otherElement) => (element, otherElement));

  /// Combines each element with the element of [other] at the same position.
  ///
  /// [combine] is called once per resulting element, so it is called at least
  /// once. The result is as long as the shorter of the two collections.
  ///
  /// ```dart
  /// NonEmptyList.of(1, tail: [2]).zipWith(
  ///   NonEmptyList.of(10, tail: [20, 30]),
  ///   (left, right) => left + right,
  /// );
  /// // [11, 22]
  /// ```
  @useResult
  @nonVirtual
  NonEmptyList<R> zipWith<R, U>(
    NonEmptyIterable<U> other,
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
    return NonEmptyList._wrap(combined);
  }

//endregion
}

T _identity<T>(T value) => value;

/// Adds one-level flattening to nested non-empty iterables.
extension FlattenNonEmptyIterableExtension<T>
    on NonEmptyIterable<NonEmptyIterable<T>> {
  /// Concatenates the nested collections into a single [NonEmptyList].
  ///
  /// ```dart
  /// final nested = NonEmptyList.of(
  ///   NonEmptyList.of(1, tail: [2]),
  ///   tail: [
  ///     NonEmptyList.of(3),
  ///     NonEmptyList.of(4, tail: [5]),
  ///   ],
  /// );
  /// nested.flatten(); // [1, 2, 3, 4, 5]
  /// ```
  @useResult
  NonEmptyList<T> flatten() => flatMapToNonEmptyList(_identity);
}

/// Adds pair splitting to non-empty iterables of records.
extension UnzipNonEmptyIterableExtension<A, B> on NonEmptyIterable<(A, B)> {
  /// Splits the pairs into one collection per record field.
  ///
  /// ```dart
  /// final (numbers, letters) =
  ///     NonEmptyList.of((1, 'a'), tail: [(2, 'b')]).unzip();
  /// // ([1, 2], ['a', 'b'])
  /// ```
  @useResult
  (NonEmptyList<A>, NonEmptyList<B>) unzip() {
    final first = <A>[];
    final second = <B>[];
    for (final element in this) {
      first.add(element.$1);
      second.add(element.$2);
    }
    return (NonEmptyList._wrap(first), NonEmptyList._wrap(second));
  }
}
