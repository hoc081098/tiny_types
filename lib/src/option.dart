import 'package:meta/meta.dart';

/// An immutable value that is either present ([Some]) or absent ([None]).
///
/// `Option<T>` makes absence explicit without exposing `null` to the rest of a
/// computation. Use [map], [flatMap], and [filter] to transform a present
/// value, then use [fold] or [getOrNull] when a concrete result is needed.
///
/// The type parameter [T] must be non-nullable. To convert a nullable value,
/// use [Option.fromNullable] or [NullableObjectToOption.toOption].
/// All callbacks are invoked synchronously, and callback exceptions are not
/// caught.
///
/// ```dart
/// const String? nickname = 'Ada';
///
/// final label = Option.fromNullable(nickname)
///     .map((name) => name.trim())
///     .filter((name) => name.isNotEmpty)
///     .fold(
///       ifSome: (name) => 'Hello, $name!',
///       ifNone: () => 'Hello!',
///     );
/// ```
@immutable
sealed class Option<T extends Object> {
  const Option._();

  /// Creates a [Some] containing [value].
  ///
  /// Because [T] extends [Object], [value] cannot be `null`.
  ///
  /// ```dart
  /// final Option<int> answer = Option.some(42);
  /// ```
  const factory Option.some(T value) = Some<T>;

  /// Creates an option with no value.
  ///
  /// This factory can be used in constant expressions. All [None] instances
  /// are equal, but callers should not rely on object identity.
  ///
  /// ```dart
  /// const Option<int> missingAnswer = Option.none();
  /// ```
  const factory Option.none() = None;

  /// Creates a [Some] for a non-null [value], or [None] for `null`.
  ///
  /// ```dart
  /// final String? name = readName();
  /// final Option<String> optionalName = Option.fromNullable(name);
  /// ```
  factory Option.fromNullable(T? value) =>
      value == null ? _singletonNone : Option.some(value);

  // Reuse one canonical instance for internally produced absent values.
  static const None _singletonNone = None();

  /// Whether this option contains a value.
  ///
  /// ```dart
  /// Option.some(42).isSome; // true
  /// Option<int>.none().isSome; // false
  /// ```
  @useResult
  bool get isSome => this is Some<T>;

  /// Whether this option contains no value.
  ///
  /// ```dart
  /// Option.some(42).isNone; // false
  /// Option<int>.none().isNone; // true
  /// ```
  @useResult
  bool get isNone => this is None;

  /// Runs [action] with the contained value when this option is a [Some].
  ///
  /// The action runs eagerly and at most once. This method returns the same
  /// option, which allows side effects to be inserted into a chain.
  ///
  /// ```dart
  /// Option.some(42)
  ///     .onSome((value) => print('Found $value'))
  ///     .map((value) => value * 2);
  /// ```
  Option<T> onSome(void Function(T value) action) {
    if (this case final Some<T> some) {
      action(some.value);
    }
    // Return `this` to allow chaining of `onSome` with other operations.
    // ignore: avoid_returning_this
    return this;
  }

  /// Runs [action] when this option is [None].
  ///
  /// The action runs eagerly and at most once. This method returns the same
  /// option, which allows side effects to be inserted into a chain.
  ///
  /// ```dart
  /// Option<int>.none()
  ///     .onNone(() => print('No value found'))
  ///     .orElse(() => Option.some(0));
  /// ```
  Option<T> onNone(void Function() action) {
    if (this is None) {
      action();
    }
    // Return `this` to allow chaining of `onNone` with other operations.
    // ignore: avoid_returning_this
    return this;
  }

  /// Transforms the contained value with [mapper].
  ///
  /// [mapper] is called exactly once for [Some] and is not called for [None].
  /// An absent option remains absent.
  ///
  /// ```dart
  /// final result = Option.some(21).map((value) => value * 2);
  /// // Option.Some(42)
  /// ```
  @useResult
  Option<R> map<R extends Object>(R Function(T value) mapper) {
    final self = this;
    return switch (self) {
      Some(value: final v) => Some(mapper(v)),
      None() => self._retag(),
    };
  }

  /// Transforms the contained value with an option-producing [mapper].
  ///
  /// Use `flatMap` when the transformation can itself return [None]. [mapper]
  /// is not called when this option is absent.
  ///
  /// ```dart
  /// Option<double> reciprocal(int value) =>
  ///     value == 0 ? Option.none() : Option.some(1 / value);
  ///
  /// final result = Option.some(2).flatMap(reciprocal);
  /// // Option.Some(0.5)
  /// ```
  @useResult
  Option<R> flatMap<R extends Object>(Option<R> Function(T value) mapper) {
    final self = this;
    return switch (self) {
      Some(value: final v) => mapper(v),
      None() => self._retag(),
    };
  }

  /// Keeps a contained value only when it satisfies [predicate].
  ///
  /// [predicate] is not called for [None]. A matching [Some] and an existing
  /// [None] are returned unchanged.
  ///
  /// ```dart
  /// final positive = Option.some(3).filter((value) => value > 0);
  /// final absent = Option.some(-1).filter((value) => value > 0);
  /// ```
  @useResult
  Option<T> filter(bool Function(T value) predicate) {
    return switch (this) {
      Some(value: final v) => predicate(v) ? this : _singletonNone,
      None() => this,
    };
  }

  /// Produces a value by handling both possible states of this option.
  ///
  /// Exactly one callback is invoked: [ifSome] with the contained value, or
  /// [ifNone] when no value is present. [R] may be `void`, so this method can
  /// also be used as a statement when both callbacks perform side effects.
  ///
  /// ```dart
  /// final message = Option.some(42).fold(
  ///   ifSome: (value) => 'Value: $value',
  ///   ifNone: () => 'No value',
  /// );
  /// ```
  R fold<R>({
    required R Function(T value) ifSome,
    required R Function() ifNone,
  }) =>
      switch (this) {
        Some(value: final v) => ifSome(v),
        None() => ifNone(),
      };

  /// Returns the contained value, or `null` when this option is [None].
  ///
  /// This is useful at an API boundary that expects a nullable value.
  ///
  /// ```dart
  /// Option.some(42).getOrNull(); // 42
  /// Option<int>.none().getOrNull(); // null
  /// ```
  @useResult
  T? getOrNull() => fold(ifSome: (v) => v, ifNone: () => null);

  /// Returns the value as an unmodifiable, zero-or-one-element list.
  ///
  /// ```dart
  /// Option.some(42).toList(); // [42]
  /// Option<int>.none().toList(); // []
  /// ```
  @useResult
  List<T> toList() => fold(
        ifSome: (v) => List<T>.unmodifiable([v]),
        ifNone: () => List<T>.unmodifiable([]),
      );
}

/// Adds lazy fallback selection to [Option].
extension OrElseOptionExtension<T extends Object> on Option<T> {
  /// Returns this option when it is [Some], otherwise returns [alternative].
  ///
  /// [alternative] is evaluated lazily, so it is not called when a value is
  /// already present.
  ///
  /// ```dart
  /// final result = Option<int>.none().orElse(() => Option.some(42));
  /// // Option.Some(42)
  /// ```
  @useResult
  Option<T> orElse(Option<T> Function() alternative) =>
      isSome ? this : alternative();
}

/// Adds one-level flattening to nested [Option] values.
extension FlattenOptionExtension<T extends Object> on Option<Option<T>> {
  /// Removes one level of [Option] nesting.
  ///
  /// The result is absent when either the outer or inner option is [None].
  ///
  /// ```dart
  /// final nested = Option.some(Option.some(42));
  /// final result = nested.flatten(); // Option.Some(42)
  /// ```
  @useResult
  Option<T> flatten() => switch (this) {
        Some(:final value) => value,
        None() => Option._singletonNone._retag(),
      };
}

/// Adds pairwise combination to [Option] values of the same type.
extension CombineOptionExtension<T extends Object> on Option<T> {
  /// Combines the values from this option and [other].
  ///
  /// The [combine] callback is called exactly once when both options are
  /// [Some]. If either option is [None], the result is [None] and [combine] is
  /// not called.
  ///
  /// ```dart
  /// final fullName = Option.some('Ada').combine(
  ///   Option.some('Lovelace'),
  ///   (first, last) => '$first $last',
  /// );
  /// // Option.Some(Ada Lovelace)
  /// ```
  @useResult
  Option<T> combine(
    Option<T> other,
    T Function(T, T) combine,
  ) =>
      switch (this) {
        Some(:final value) => switch (other) {
            Some(value: final otherValue) => combine(value, otherValue).some(),
            None() => Option._singletonNone._retag(),
          },
        None() => Option._singletonNone._retag(),
      };
}

/// An [Option] that contains [value].
///
/// Prefer [Option.some] when the surrounding code is expressed in terms of
/// [Option]. Constructing `Some` directly is equivalent.
@immutable
final class Some<T extends Object> extends Option<T> {
  /// Creates an option containing [value].
  const Some(this.value) : super._();

  /// The value contained in this option.
  final T value;

  /// Whether [other] is a [Some] containing an equal value.
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Some && value == other.value;

  /// The hash code of [value].
  @override
  int get hashCode => value.hashCode;

  /// Returns `Option.Some(value)` using the string form of [value].
  @override
  String toString() => 'Option.Some($value)';
}

/// The single absent [Option] value.
///
/// All `None` values compare equal. Use [Option.none] to create a typed absent
/// option, or invoke [None.new] when the concrete [None] type is needed.
@immutable
final class None extends Option<Never> {
  /// Creates an absent option.
  ///
  /// ```dart
  /// const None none = None();
  /// ```
  const None() : super._();

  /// Whether [other] is a [None].
  @override
  bool operator ==(Object other) => identical(this, other) || other is None;

  /// The hash code shared by all absent options.
  @override
  int get hashCode => 0;

  /// Returns `Option.None`.
  @override
  String toString() => 'Option.None';

  @pragma('vm:always-consider-inlining')
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @useResult
  Option<R> _retag<R extends Object>() => this;
}

/// Adds a concise conversion from a non-null value to [Some].
extension ObjectToSome<T extends Object> on T {
  /// Wraps this value in [Some].
  ///
  /// ```dart
  /// final Option<int> answer = 42.some();
  /// ```
  @pragma('vm:always-consider-inlining')
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @useResult
  // Follow Arrow-kt style.
  // ignore: use_to_and_as_if_applicable
  Some<T> some() => Some(this);
}

/// Adds conversion from a nullable value to [Option].
extension NullableObjectToOption<T extends Object> on T? {
  /// Returns [Some] for a non-null value, or [None] for `null`.
  ///
  /// ```dart
  /// const String? name = 'Ada';
  /// final Option<String> optionalName = name.toOption();
  /// ```
  @useResult
  Option<T> toOption() => Option.fromNullable(this);
}
