import 'package:test/test.dart';
import 'package:tiny_types/tiny_types.dart';

void main() {
  group('Option', () {
    group('constructors', () {
      test('some contains a non-null value', () {
        const option = Option.some(42);

        expect(option, const Some(42));
        expect(option.getOrNull(), 42);
        expect(option.isSome, isTrue);
        expect(option.isNone, isFalse);
      });

      test('none supports canonical constant values', () {
        const intOption = Option<int>.none();
        const stringOption = Option<String>.none();
        const concreteNone = None();

        expect(identical(intOption, stringOption), isTrue);
        expect(identical(intOption, concreteNone), isTrue);
        expect(intOption.isSome, isFalse);
        expect(intOption.isNone, isTrue);
      });

      test('fromNullable selects some or none', () {
        expect(Option.fromNullable(42), const Some(42));
        expect(Option<int>.fromNullable(null), const None());
      });
    });

    group('side effects', () {
      test('onSome runs only for some and returns the same option', () {
        const option = Option.some(42);
        final receivedValues = <int>[];

        final result = option.onSome(receivedValues.add);
        const Option<int>.none().onSome(receivedValues.add);

        expect(receivedValues, [42]);
        expect(result, same(option));
      });

      test('onNone runs only for none and returns the same option', () {
        const option = Option<int>.none();
        var callCount = 0;

        final result = option.onNone(() => callCount++);
        const Option.some(42).onNone(() => callCount++);

        expect(callCount, 1);
        expect(result, same(option));
      });
    });

    group('transformations', () {
      test('map transforms some and skips none', () {
        var callCount = 0;
        int mapper(int value) {
          callCount++;
          return value * 2;
        }

        expect(const Option.some(21).map(mapper), const Some(42));
        expect(const Option<int>.none().map(mapper), const None());
        expect(callCount, 1);
      });

      test('flatMap transforms some and skips none', () {
        var callCount = 0;
        Option<double> reciprocal(int value) {
          callCount++;
          return value == 0 ? const Option.none() : Option.some(1 / value);
        }

        expect(const Option.some(2).flatMap(reciprocal), const Some(0.5));
        expect(const Option.some(0).flatMap(reciprocal), const None());
        expect(const Option<int>.none().flatMap(reciprocal), const None());
        expect(callCount, 2);
      });

      test('filter keeps matching some and skips none', () {
        const option = Option.some(42);
        var callCount = 0;
        bool isPositive(int value) {
          callCount++;
          return value > 0;
        }

        expect(option.filter(isPositive), same(option));
        expect(const Option.some(-1).filter(isPositive), const None());
        expect(const Option<int>.none().filter(isPositive), const None());
        expect(callCount, 2);
      });
    });

    group('consumption', () {
      test('fold evaluates exactly one branch', () {
        var someCallCount = 0;
        var noneCallCount = 0;

        final someResult = const Option.some(42).fold(
          ifSome: (value) {
            someCallCount++;
            return 'Value: $value';
          },
          ifNone: () {
            noneCallCount++;
            return 'No value';
          },
        );
        final noneResult = const Option<int>.none().fold(
          ifSome: (value) {
            someCallCount++;
            return 'Value: $value';
          },
          ifNone: () {
            noneCallCount++;
            return 'No value';
          },
        );

        expect(someResult, 'Value: 42');
        expect(noneResult, 'No value');
        expect(someCallCount, 1);
        expect(noneCallCount, 1);
      });

      test('fold supports side-effect-only callbacks', () {
        var observed = 0;

        const Option.some(42).fold<void>(
          ifSome: (value) => observed = value,
          ifNone: () => observed = -1,
        );

        expect(observed, 42);
      });

      test('getOrNull converts absence to null', () {
        expect(const Option.some(42).getOrNull(), 42);
        expect(const Option<int>.none().getOrNull(), isNull);
      });

      test('getOrElse evaluates its default only for none', () {
        var callCount = 0;

        int defaultValue() {
          callCount++;
          return 0;
        }

        expect(const Option.some(42).getOrElse(defaultValue), 42);
        expect(callCount, 0);

        expect(const Option<int>.none().getOrElse(defaultValue), 0);
        expect(callCount, 1);
      });

      test('getOrElse propagates exceptions from its default', () {
        final error = StateError('No default value');

        expect(
          () => const Option<int>.none().getOrElse(() => throw error),
          throwsA(same(error)),
        );
        expect(
          const Option.some(42).getOrElse(() => throw error),
          42,
        );
      });

      test('toList creates an unmodifiable zero-or-one-element list', () {
        final someList = const Option.some(42).toList();
        final noneList = const Option<int>.none().toList();

        expect(someList, [42]);
        expect(noneList, isEmpty);
        expect(someList.clear, throwsUnsupportedError);
        expect(noneList.clear, throwsUnsupportedError);
      });
    });

    group('extensions', () {
      test('orElse evaluates its alternative only for none', () {
        const option = Option.some(42);
        var callCount = 0;
        Option<int> alternative() {
          callCount++;
          return const Option.some(0);
        }

        expect(option.orElse(alternative), same(option));
        expect(const Option<int>.none().orElse(alternative), const Some(0));
        expect(callCount, 1);
      });

      test('flatten removes one level of nesting', () {
        expect(
          const Option.some(Option.some(42)).flatten(),
          const Some(42),
        );
        expect(
          const Option<Option<int>>.some(Option<int>.none()).flatten(),
          const None(),
        );
        expect(
          const Option<Option<int>>.none().flatten(),
          const None(),
        );
      });

      test('combine invokes its callback only when both values exist', () {
        var callCount = 0;
        int add(int left, int right) {
          callCount++;
          return left + right;
        }

        expect(
          const Option.some(20).combine(const Option.some(22), add),
          const Some(42),
        );
        expect(
          const Option.some(20).combine(const Option<int>.none(), add),
          const None(),
        );
        expect(
          const Option<int>.none().combine(const Option.some(22), add),
          const None(),
        );
        expect(callCount, 1);
      });

      test('some wraps a non-null value', () {
        final Option<int> option = 42.some();

        expect(option, const Some(42));
      });

      test('toOption selects some or none', () {
        final present = _nullable(42);
        const int? absent = null;

        expect(present.toOption(), const Some(42));
        expect(absent.toOption(), const None());
      });
    });

    group('covariance safety', () {
      const Option<num> widenedSome = Some<int>(1);
      const Option<num> widenedNone = None();

      test('state getters support widened variants', () {
        expect(widenedSome.isSome, isTrue);
        expect(widenedSome.isNone, isFalse);
        expect(widenedNone.isSome, isFalse);
        expect(widenedNone.isNone, isTrue);
      });

      test('onSome supports widened variants', () {
        final observed = <num>[];

        expect(widenedSome.onSome(observed.add), same(widenedSome));
        expect(widenedNone.onSome(observed.add), same(widenedNone));
        expect(observed, [1]);
      });

      test('onNone supports widened variants', () {
        var callCount = 0;

        expect(widenedSome.onNone(() => callCount++), same(widenedSome));
        expect(widenedNone.onNone(() => callCount++), same(widenedNone));
        expect(callCount, 1);
      });

      test('map supports widened variants', () {
        expect(
          widenedSome.map((value) => value.toDouble()),
          const Some<double>(1),
        );
        expect(
          widenedNone.map((value) => value.toDouble()),
          const None(),
        );
      });

      test('flatMap supports widened variants', () {
        expect(
          widenedSome.flatMap((value) => Some('value:$value')),
          const Some<String>('value:1'),
        );
        expect(
          widenedNone.flatMap((value) => Some('value:$value')),
          const None(),
        );
      });

      test('filter supports widened variants', () {
        expect(widenedSome.filter((value) => value > 0), same(widenedSome));
        expect(widenedNone.filter((value) => value > 0), same(widenedNone));
      });

      test('fold supports widened variants', () {
        expect(
          widenedSome.fold(
            ifSome: (value) => 'some:$value',
            ifNone: () => 'none',
          ),
          'some:1',
        );
        expect(
          widenedNone.fold(
            ifSome: (value) => 'some:$value',
            ifNone: () => 'none',
          ),
          'none',
        );
      });

      test('getOrNull supports widened variants', () {
        expect(widenedSome.getOrNull(), 1);
        expect(widenedNone.getOrNull(), isNull);
      });

      test('toList supports widened variants', () {
        expect(widenedSome.toList(), <num>[1]);
        expect(widenedNone.toList(), isEmpty);
      });

      test('getOrElse supports widened variants', () {
        var callCount = 0;

        num defaultValue() {
          callCount++;
          return 2.5;
        }

        expect(widenedSome.getOrElse(defaultValue), 1);
        expect(callCount, 0);
        expect(widenedNone.getOrElse(defaultValue), 2.5);
        expect(callCount, 1);
      });

      test('orElse supports widened variants', () {
        var callCount = 0;

        Option<num> alternative() {
          callCount++;
          return const Some<double>(2.5);
        }

        expect(widenedSome.orElse(alternative), same(widenedSome));
        expect(callCount, 0);
        expect(widenedNone.orElse(alternative), const Some<double>(2.5));
        expect(callCount, 1);
      });

      test('flatten supports widened variants', () {
        const Option<Option<num>> widenedNestedSome =
            Some<Option<int>>(Some<int>(1));
        const Option<Option<num>> widenedNestedInnerNone =
            Some<Option<int>>(None());
        const Option<Option<num>> widenedNestedNone = None();

        expect(widenedNestedSome.flatten(), const Some<int>(1));
        expect(widenedNestedInnerNone.flatten(), const None());
        expect(widenedNestedNone.flatten(), const None());
      });

      test('combine supports widened variants', () {
        var callCount = 0;

        num add(num left, num right) {
          callCount++;
          return left + right;
        }

        expect(
          widenedSome.combine(const Some<double>(2.5), add),
          const Some<double>(3.5),
        );
        expect(callCount, 1);
        expect(
          widenedSome.combine(widenedNone, add),
          const None(),
        );
        expect(
          widenedNone.combine(const Some<double>(2.5), add),
          const None(),
        );
        expect(callCount, 1);
      });
    });

    group('pattern matching', () {
      test('supports an exhaustive switch over some and none', () {
        String describe(Option<int> option) => switch (option) {
              Some(:final value) => 'Some($value)',
              None() => 'None',
            };

        expect(describe(const Option.some(42)), 'Some(42)');
        expect(describe(const Option<int>.none()), 'None');
        expect(describe(const None()), 'None');
      });
    });

    group('value semantics', () {
      test('some uses its contained value for equality and hashCode', () {
        const first = Some<int>(42);
        const second = Some<num>(42);

        expect(identical(first, second), isFalse);
        expect(first, second);
        expect(second, first);

        expect(first.hashCode, second.hashCode);

        expect(first, isNot(const Some(0)));
        expect(first, isNot(const None()));
        expect(const None(), isNot(first));
      });

      test('distinct none instances are equal and have the same hashCode', () {
        // These calls intentionally omit `const` to create distinct instances.
        // ignore: prefer_const_constructors
        final first = Option<int>.none();
        // Omit `const` here as well so this is not identical to `first`.
        // ignore: prefer_const_constructors
        final second = Option<String>.none();

        expect(identical(first, second), isFalse);
        expect(first, second);
        expect(second, first);

        expect(first.hashCode, second.hashCode);
        expect(first.hashCode, isNot(Unit.value.hashCode));
      });

      test('toString identifies the option state', () {
        expect(const Option.some(42).toString(), 'Option.Some(42)');
        expect(const Option<int>.none().toString(), 'Option.None');
      });
    });
  });
}

T? _nullable<T extends Object>(T? value) => value;
