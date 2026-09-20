import 'package:meta/meta.dart';

/// An immutable option containing either a value ([Some]) or no value ([None]).
///
/// ## Creation and nullability
///
/// Presence and nullability are independent. `Option<String>` has a
/// non-nullable payload; `Option<String?>` may contain `null`.
/// A `Some(null)` is present and differs from [None].
///
/// Choose how to create an option based on how `null` should be handled:
///
/// - [Option.some] and [ObjectToSome.some] wrap a value unchanged, including
///   `null` when [T] is nullable.
/// - [Option.fromNullable] and [NullableObjectToOption.toOption] treat `null`
///   as absence.
/// - [Option.none] creates an absent option explicitly.
///
/// ## Transforming and consuming
///
/// - [map] transforms the contained value while preserving absence.
/// - [flatMap] chains an option-returning operation.
/// - [filter] keeps the contained value when the predicate returns `true`;
///   otherwise, it returns [None].
/// - [fold] produces a value by handling both variants.
/// - [OptionFallbackExtension.getOrElse] returns the contained value or a
///   fallback for [None].
/// - [OptionFallbackExtension.or] returns this option when it is [Some], or an
///   eagerly evaluated alternative when it is [None].
/// - [OptionFallbackExtension.orElse] lazily computes an alternative for
///   [None].
/// - [getOrNull] returns the contained value, or `null` for [None]. It cannot
///   distinguish `Some(null)` from [None].
///
/// Callbacks run synchronously, and their exceptions propagate to the caller.
///
/// ```dart
/// const String? nickname = ' Ada ';
///
/// final label = Option.fromNullable(nickname)
///     .map((name) => name.trim())
///     .filter((name) => name.isNotEmpty)
///     .fold(
///       ifSome: (name) => 'Hello, $name!',
///       ifNone: () => 'Hello!',
///     ); // Hello, Ada!
/// ```
@immutable
sealed class Option<T> {
  const Option._();

  /// Creates a [Some] containing [value].
  ///
  /// The value is kept unchanged, including `null` when [T] is nullable.
  /// Use [Option.fromNullable] to treat `null` as absence instead.
  ///
  /// ```dart
  /// final Option<int> answer = Option.some(42);
  /// const Option<String?> presentNull = Option.some(null);
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
  /// const String? name = 'Ada';
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
  /// For [Some], [mapper] is called exactly once and its result is wrapped in
  /// [Some]. For [None], [mapper] is not called and the option remains absent.
  /// A `null` result remains present.
  ///
  /// ```dart
  /// final result = Option.some(21).map((value) => value * 2);
  /// // Option.Some(42)
  /// ```
  @useResult
  Option<R> map<R>(R Function(T value) mapper) {
    final self = this;
    return switch (self) {
      Some(value: final v) => Some(mapper(v)),
      None() => self._retag(),
    };
  }

  /// Transforms the contained value with an option-producing [mapper].
  ///
  /// For [Some], [mapper] is called exactly once and its option is returned
  /// directly. For [None], [mapper] is not called and the option remains
  /// absent.
  ///
  /// ```dart
  /// Option<double> reciprocal(int value) =>
  ///     value == 0 ? Option.none() : Option.some(1 / value);
  ///
  /// final result = Option.some(2).flatMap(reciprocal);
  /// // Option.Some(0.5)
  /// ```
  @useResult
  Option<R> flatMap<R>(Option<R> Function(T value) mapper) {
    final self = this;
    return switch (self) {
      Some(value: final v) => mapper(v),
      None() => self._retag(),
    };
  }

  /// Keeps a contained value only when it satisfies [predicate].
  ///
  /// For [Some], [predicate] is called exactly once. A matching [Some] and an
  /// existing [None] are returned unchanged; a non-matching [Some] becomes
  /// [None].
  ///
  /// ```dart
  /// final positive = Option.some(3).filter((value) => value > 0);
  /// // Option.Some(3)
  ///
  /// final notSatisfied = Option.some(-1).filter((value) => value > 0);
  /// // Option.None
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
  /// This is useful at an API boundary that expects a nullable value. It loses
  /// the distinction between `Some(null)` and [None]; use [fold] or [isSome]
  /// when that distinction matters.
  ///
  /// ```dart
  /// Option.some(42).getOrNull(); // 42
  /// Option<int>.none().getOrNull(); // null
  /// ```
  @useResult
  T? getOrNull() => fold(ifSome: (v) => v, ifNone: () => null);

  /// Returns the contained value as an unmodifiable, zero-or-one-element list.
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

/// Adds eager and lazy fallback operations to [Option].
extension OptionFallbackExtension<T> on Option<T> {
  // Keep this API extension-based. A None object's reified supertype is
  // Option<Never>, so an instance method accepting T Function() would check a
  // fallback against Never Function() at runtime.

  /// Returns the contained value, or a lazily computed fallback for [None].
  ///
  /// [defaultValue] is called exactly once for [None] and is not called for
  /// [Some]. Any exception thrown by [defaultValue] propagates to the caller.
  ///
  /// ```dart
  /// Option.some(42).getOrElse(() => 0); // 42
  /// Option<int>.none().getOrElse(() => 0); // 0
  /// ```
  @useResult
  T getOrElse(T Function() defaultValue) => switch (this) {
        Some(value: final v) => v,
        None() => defaultValue(),
      };

  /// Returns this option when it is [Some], or [alternative] when it is [None].
  ///
  /// [alternative] is evaluated before this method is called, even when this
  /// option is [Some]. Use [orElse] to create the alternative lazily.
  ///
  /// ```dart
  /// final result = Option<int>.none().or(Option.some(42));
  /// // Option.Some(42)
  /// ```
  @useResult
  Option<T> or(Option<T> alternative) => isSome ? this : alternative;

  /// Returns this option when it is [Some], or the option produced by
  /// [alternative] when it is [None].
  ///
  /// [alternative] is evaluated exactly once for [None] and is not evaluated
  /// for [Some]. Any exception thrown by [alternative] propagates to the
  /// caller.
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
extension FlattenOptionExtension<T> on Option<Option<T>> {
  /// Removes one level of [Option] nesting.
  ///
  /// An outer [Some] returns its contained option unchanged. An outer [None]
  /// remains absent.
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
extension CombineOptionExtension<T> on Option<T> {
  /// Combines the values from this option and [other].
  ///
  /// When both options are [Some], [combine] is called exactly once and its
  /// result is wrapped in [Some], including a `null` result. If either option
  /// is [None], the result is [None] and [combine] is not called. Any exception
  /// thrown by [combine] propagates to the caller.
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
final class Some<T> extends Option<T> {
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

/// The absent [Option] variant.
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

  // The UTF-8 bytes for `None`, used as a fixed non-zero variant hash.
  static const int _hashCode = 0x4e6f6e65;

  /// Whether [other] is a [None].
  @override
  bool operator ==(Object other) => identical(this, other) || other is None;

  /// The non-zero hash code shared by all absent options.
  @override
  int get hashCode => _hashCode;

  /// Returns `Option.None`.
  @override
  String toString() => 'Option.None';

  @pragma('vm:always-consider-inlining')
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @useResult
  Option<R> _retag<R>() => this;
}

/// Adds a concise conversion from any value to [Some].
extension ObjectToSome<T> on T {
  /// Returns a [Some] containing this value.
  ///
  /// A `null` value remains present. Use [NullableObjectToOption.toOption] to
  /// treat `null` as absence instead.
  ///
  /// ```dart
  /// final Option<int> answer = 42.some();
  /// const String? name = null;
  /// final Option<String?> presentNull = name.some();
  /// ```
  @pragma('vm:always-consider-inlining')
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @useResult
  // Keep the established Arrow-style name for this wrapping operation.
  // ignore: use_to_and_as_if_applicable
  Some<T> some() => Some(this);
}

/// Adds conversion from a nullable value to [Option].
extension NullableObjectToOption<T extends Object> on T? {
  /// Returns [Some] for a non-null value, or [None] for `null`.
  ///
  /// The payload type [T] is non-nullable. Use [ObjectToSome.some] to preserve
  /// `null` as a present payload instead.
  ///
  /// ```dart
  /// const String? name = 'Ada';
  /// final Option<String> optionalName = name.toOption();
  /// ```
  @useResult
  Option<T> toOption() => Option.fromNullable(this);
}
