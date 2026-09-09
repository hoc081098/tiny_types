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

      test('none returns the shared absent value', () {
        final intOption = Option<int>.none();
        final stringOption = Option<String>.none();
        final concreteNone = None();

        expect(identical(intOption, stringOption), isTrue);
        expect(identical(intOption, concreteNone), isTrue);
        expect(identical(concreteNone, None()), isTrue);
        expect(intOption.isSome, isFalse);
        expect(intOption.isNone, isTrue);
      });

      test('fromNullable selects some or none', () {
        expect(Option.fromNullable(42), const Some(42));
        expect(Option<int>.fromNullable(null), same(None()));
      });
    });

    group('side effects', () {
      test('onSome runs only for some and returns the same option', () {
        const option = Option.some(42);
        final receivedValues = <int>[];

        final result = option.onSome(receivedValues.add);
        Option<int>.none().onSome(receivedValues.add);

        expect(receivedValues, [42]);
        expect(result, same(option));
      });

      test('onNone runs only for none and returns the same option', () {
        final option = Option<int>.none();
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
        expect(Option<int>.none().map(mapper), same(None()));
        expect(callCount, 1);
      });

      test('flatMap transforms some and skips none', () {
        var callCount = 0;
        Option<double> reciprocal(int value) {
          callCount++;
          return value == 0 ? Option.none() : Option.some(1 / value);
        }

        expect(const Option.some(2).flatMap(reciprocal), const Some(0.5));
        expect(const Option.some(0).flatMap(reciprocal), same(None()));
        expect(Option<int>.none().flatMap(reciprocal), same(None()));
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
        expect(const Option.some(-1).filter(isPositive), same(None()));
        expect(Option<int>.none().filter(isPositive), same(None()));
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
        final noneResult = Option<int>.none().fold(
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

      test('getOrNull converts absence to null', () {
        expect(const Option.some(42).getOrNull(), 42);
        expect(Option<int>.none().getOrNull(), isNull);
      });

      test('toList creates an unmodifiable zero-or-one-element list', () {
        final someList = const Option.some(42).toList();
        final noneList = Option<int>.none().toList();

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
        expect(Option<int>.none().orElse(alternative), const Some(0));
        expect(callCount, 1);
      });

      test('flatten removes one level of nesting', () {
        expect(
          const Option.some(Option.some(42)).flatten(),
          const Some(42),
        );
        expect(
          Option<Option<int>>.some(Option<int>.none()).flatten(),
          same(None()),
        );
        expect(
          Option<Option<int>>.none().flatten(),
          same(None()),
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
          const Option.some(20).combine(Option<int>.none(), add),
          same(None()),
        );
        expect(
          Option<int>.none().combine(const Option.some(22), add),
          same(None()),
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
        expect(absent.toOption(), same(None()));
      });
    });

    group('pattern matching', () {
      test('supports an exhaustive switch over some and none', () {
        String describe(Option<int> option) => switch (option) {
              Some(:final value) => 'Some($value)',
              None() => 'None',
            };

        expect(describe(const Option.some(42)), 'Some(42)');
        expect(describe(Option<int>.none()), 'None');
        expect(describe(None()), 'None');
      });
    });

    group('value semantics', () {
      test('some uses its contained value for equality and hashCode', () {
        const first = Some<int>(42);
        const second = Some<num>(42);

        expect(first, second);
        expect(first.hashCode, second.hashCode);
        expect(first, isNot(const Some(0)));
      });

      test('none values are equal and have the same hashCode', () {
        final first = Option<int>.none();
        final second = Option<String>.none();

        expect(first, second);
        expect(first.hashCode, second.hashCode);
      });

      test('toString identifies the option state', () {
        expect(const Option.some(42).toString(), 'Option.Some(42)');
        expect(Option<int>.none().toString(), 'Option.None');
      });
    });
  });
}

T? _nullable<T extends Object>(T? value) => value;
