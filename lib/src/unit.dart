import 'dart:async';

import 'package:meta/meta.dart';

/// A type with exactly one value, [Unit.value].
///
/// `Unit` represents a successful result with no payload. It is useful when
/// that result must still participate in a value-oriented or generic API.
///
/// ## Why not `void`?
///
/// In Dart, `void` does not mean that no object exists at runtime. It marks the
/// result as meaningless and requires callers to discard it. Consequently, it
/// cannot be consumed as an ordinary value: callers cannot read, compare, or
/// transform it, or pass it to an API that expects a meaningful value. The
/// value produced by `await Future<void>` is equally unusable.
///
/// A `void Function()` can also accept a function with any return type. The
/// returned value is silently discarded:
///
/// ```dart
/// int calculate() => 42;
/// void Function() callback = calculate; // Valid; 42 is discarded.
/// ```
///
/// This behavior is convenient for callbacks whose results do not matter, but
/// it does not model one predictable, reusable result. A `Unit Function()` has
/// a stricter contract: when it completes normally, it must return
/// [Unit.value]. That value can then be stored, passed, compared, or
/// transformed.
///
/// `Unit` is especially useful with generic types. For example,
/// `Option<Unit>` can distinguish a present success value from `None`, while a
/// result type such as `Result<Failure, Unit>` can distinguish success from
/// failure without inventing a payload.
///
/// ```dart
/// Future<Unit> saveSettings() async {
///   await repository.save();
///   return Unit.value;
/// }
/// ```
///
/// Prefer `void` or `Future<void>` when callers should discard the result. Use
/// `Unit` when a no-payload result needs to remain a first-class value.
///
/// Every `Unit` reference is the same instance. Its string representation is
/// `()`, and all comparisons between `Unit` values return zero.
@immutable
final class Unit implements Comparable<Unit> {
  const Unit._();

  /// The only value of the [Unit] type.
  static const Unit value = Unit._();

  /// A shared future that completes with [Unit.value].
  ///
  /// Use this when an already-completed `Future<Unit>` is needed. The future is
  /// created in the root [Zone] and cached, so repeated reads return the same
  /// instance.
  ///
  /// ```dart
  /// final Future<Unit> completed = Unit.future;
  /// ```
  static final Future<Unit> future = Zone.root.run(() => Future.value(value));

  /// Returns `()`.
  @override
  String toString() => '()';

  /// Whether [other] is a [Unit].
  @override
  bool operator ==(Object other) => other is Unit;

  /// The hash code shared by all `Unit` values.
  @override
  int get hashCode => 0;

  /// Returns zero because [Unit] has only one possible value.
  @override
  int compareTo(Unit other) => 0;
}
