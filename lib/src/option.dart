import 'package:meta/meta.dart';

@immutable
sealed class Option<T extends Object> {
  static const None _singletonNone = None._();

  const Option();

  const factory Option.some(T value) = Some<T>;

  factory Option.none() => _singletonNone;

  @useResult
  factory Option.fromNullable(T? value) =>
      value == null ? _singletonNone : Option.some(value);

  @useResult
  bool get isSome => this is Some<T>;

  @useResult
  bool get isNone => this is None;

  Option<T> onSome(void Function(T value) action) {
    if (this case final Some<T> some) {
      action(some.value);
    }
    return this;
  }

  Option<T> onNone(void Function() action) {
    if (this is None) {
      action();
    }
    return this;
  }

  @useResult
  Option<R> map<R extends Object>(R Function(T value) mapper) {
    final self = this;
    return switch (self) {
      Some(value: final v) => Some(mapper(v)),
      None() => self._retag(),
    };
  }

  @useResult
  Option<R> flatMap<R extends Object>(Option<R> Function(T value) mapper) {
    final self = this;
    return switch (self) {
      Some(value: final v) => mapper(v),
      None() => self._retag(),
    };
  }

  @useResult
  Option<T> filter(bool Function(T value) predicate) {
    return switch (this) {
      Some(value: final v) => predicate(v) ? this : _singletonNone,
      None() => this,
    };
  }

  @useResult
  Option<T> orElse(Option<T> Function() alternative) =>
      isSome ? this : alternative();

  R fold<R>({
    required R Function(T value) ifSome,
    required R Function() ifNone,
  }) =>
      switch (this) {
        Some(value: final v) => ifSome(v),
        None() => ifNone(),
      };

  @useResult
  T? getOrNull() => fold(ifSome: (v) => v, ifNone: () => null);

  @useResult
  List<T> toList() => fold(
        ifSome: (v) => List<T>.unmodifiable([v]),
        ifNone: () => List<T>.unmodifiable([]),
      );
}

final class Some<T extends Object> extends Option<T> {
  const Some(this.value);

  final T value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Some && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Option.Some($value)';
}

final class None extends Option<Never> {
  const None._();

  static None get value => Option._singletonNone;

  @override
  bool operator ==(Object other) => identical(this, other) || other is None;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'Option.None';

  @pragma('vm:always-consider-inlining')
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @useResult
  Option<R> _retag<R extends Object>() => this;
}

extension ObjectToSome<T extends Object> on T {
  // ignore: use_to_and_as_if_applicable
  @useResult
  Some<T> some() => Some(this);
}

extension NullableObjectToOption<T extends Object> on T? {
  @useResult
  Option<T> toOption() {
    final self = this;
    return self == null ? Option._singletonNone._retag() : Some(self);
  }
}
