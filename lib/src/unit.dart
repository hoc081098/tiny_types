import 'dart:async';

import 'package:meta/meta.dart';

/// A type with exactly one value, [Unit.value].
///
/// In Dart, `void` indicates that a returned value must not be used. That is
/// the right choice for ordinary functions whose callers should discard the
/// result. `Unit` is useful in the different case where an operation has no
/// data to return but its result must still participate in a value-oriented
/// API.
///
/// Unlike a `void` result, [Unit.value] is a concrete value. It can be stored,
/// passed to another function, compared, or transformed inside generic types
/// such as `Future<Unit>` and `Option<Unit>`.
///
/// ```dart
/// Future<Unit> saveSettings() async {
///   await repository.save();
///   return Unit.value;
/// }
/// ```
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
