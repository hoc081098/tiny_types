import 'dart:async';

import 'package:meta/meta.dart';

/// It represents the absence of a meaningful return value.
/// Used instead of `void` as a return type for a function when no value
/// is to be returned.
///
/// Read [this article](https://medium.com/flutter-community/the-curious-case-of-void-in-dart-f0535705e529)
/// to understand why it is better to not use `void` and use [Unit] instead.
///
/// There is only one value of type [Unit].
@immutable
final class Unit implements Comparable<Unit> {
  const Unit._();

  /// Default and only value of the [Unit] type.
  static const Unit value = Unit._();

  /// A `Future<Unit>` completed with [Unit.value].
  /// It can be used when a `Future<Unit>` is expected.
  static final Future<Unit> future = Zone.root.run(() => Future.value(value));

  @override
  String toString() => '()';

  @override
  bool operator ==(Object other) => other is Unit;

  @override
  int get hashCode => 0;

  @override
  int compareTo(Unit other) => 0;
}
