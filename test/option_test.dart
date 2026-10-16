import 'package:test/test.dart';
import 'package:tiny_types/tiny_types.dart';

void main() {
  group('Option', () {
    group('creation and state', () {
      test('some and none expose their states, including Some(null)', () {
        const present = Option.some(42);
        const Option<String?> presentNull = Some<Null>(null);
        const Option<String?> absent = None();

        expect(present.isSome, isTrue);
        expect(present.isNone, isFalse);
        expect(presentNull.isSome, isTrue);
        expect(presentNull.isNone, isFalse);
        expect(absent.isSome, isFalse);
        expect(absent.isNone, isTrue);
      });

      test('fromNullable treats only null as absence', () {
        expect(Option.fromNullable(42), const Some(42));
        expect(Option<int>.fromNullable(null), const None());
        expect(Option<String?>.fromNullable('Ada'), const Some('Ada'));
        expect(Option<String?>.fromNullable(null), const None());
      });

      test('nullable payloads do not satisfy a non-nullable runtime type', () {
        const Object option = Some<Null>(null);

        expect(option, isA<Option<String?>>());
        expect(option, isNot(isA<Option<String>>()));
      });

      test('non-nullable payload types reject null at runtime', () {
        expect(
          () => Function.apply(Option<String>.some, [null]),
          throwsA(isA<TypeError>()),
        );
        expect(
          () => Function.apply(Some<String>.new, [null]),
          throwsA(isA<TypeError>()),
        );
      });
    });

    group('side effects', () {
      test('onSome runs only for present values and returns the receiver', () {
        const option = Option.some(42);
        const Option<String?> presentNull = Some<Null>(null);
        const Option<String?> absent = None();
        final integers = <int>[];
        final nullableStrings = <String?>[];

        expect(option.onSome(integers.add), same(option));
        expect(presentNull.onSome(nullableStrings.add), same(presentNull));
        expect(absent.onSome(nullableStrings.add), same(absent));
        expect(integers, [42]);
        expect(nullableStrings, [null]);
      });

      test('onNone runs only for absence and returns the receiver', () {
        const present = Option.some(42);
        const absent = Option<int>.none();
        var callCount = 0;

        expect(present.onNone(() => callCount++), same(present));
        expect(absent.onNone(() => callCount++), same(absent));
        expect(callCount, 1);
      });

      test('actions propagate their exceptions', () {
        final error = StateError('Action failed');

        expect(
          () => const Option.some(42).onSome((_) => throw error),
          throwsA(same(error)),
        );
        expect(
          () => const Option<int>.none().onNone(() => throw error),
          throwsA(same(error)),
        );
      });
    });

    group('transformations', () {
      test('map transforms Some once, skips None, and preserves null', () {
        var callCount = 0;
        int mapper(int value) {
          callCount++;
          return value * 2;
        }

        expect(const Option.some(21).map(mapper), const Some(42));
        expect(const Option<int>.none().map(mapper), const None());
        expect(callCount, 1);

        const Option<String?> presentNull = Some<Null>(null);
        final seen = <String?>[];
        expect(
          presentNull.map((value) {
            seen.add(value);
            return value;
          }),
          const Some<String?>(null),
        );
        expect(seen, [null]);
        expect(const Option.some(1).map((_) => null), const Some<Null>(null));
      });

      test('flatMap transforms Some once, skips None, and preserves null', () {
        var callCount = 0;
        Option<double> reciprocal(int value) {
          callCount++;
          return value == 0 ? const Option.none() : Option.some(1 / value);
        }

        expect(const Option.some(2).flatMap(reciprocal), const Some(0.5));
        expect(const Option.some(0).flatMap(reciprocal), const None());
        expect(const Option<int>.none().flatMap(reciprocal), const None());
        expect(callCount, 2);

        const Option<String?> presentNull = Some<Null>(null);
        expect(presentNull.flatMap(Some.new), const Some<String?>(null));
        expect(
          presentNull.flatMap(Option<String>.fromNullable),
          const None(),
        );
        expect(
          const Option.some(1).flatMap((_) => const Some<String?>(null)),
          const Some<String?>(null),
        );
      });

      test('filter evaluates Some once, skips None, and evaluates null', () {
        var callCount = 0;
        bool isPositive(int value) {
          callCount++;
          return value > 0;
        }

        const positive = Option.some(42);
        expect(positive.filter(isPositive), same(positive));
        expect(const Option.some(-1).filter(isPositive), const None());
        expect(const Option<int>.none().filter(isPositive), const None());
        expect(callCount, 2);

        const Option<String?> presentNull = Some<Null>(null);
        final seen = <String?>[];
        expect(
          presentNull.filter((value) {
            seen.add(value);
            return value == null;
          }),
          same(presentNull),
        );
        expect(presentNull.filter((value) => value != null), const None());
        expect(seen, [null]);
      });

      test('transformation callbacks propagate their exceptions', () {
        const Option<String?> option = Some<Null>(null);
        final error = StateError('Transformation failed');

        expect(
          () => option.map<String>((_) => throw error),
          throwsA(same(error)),
        );
        expect(
          () => option.flatMap<String>((_) => throw error),
          throwsA(same(error)),
        );
        expect(() => option.filter((_) => throw error), throwsA(same(error)));
      });
    });

    group('consumption', () {
      test('fold evaluates exactly one branch and preserves present null', () {
        var someCallCount = 0;
        var noneCallCount = 0;

        String describe<T>(Option<T> option) => option.fold(
              ifSome: (value) {
                someCallCount++;
                return 'present: $value';
              },
              ifNone: () {
                noneCallCount++;
                return 'absent';
              },
            );

        expect(describe(const Option.some(42)), 'present: 42');
        expect(describe(const Option<int>.none()), 'absent');
        expect(describe(const Some<Null>(null)), 'present: null');
        expect(someCallCount, 2);
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

      test('fold callbacks propagate their exceptions', () {
        final error = StateError('Fold failed');

        expect(
          () => const Option.some(42).fold<int>(
            ifSome: (_) => throw error,
            ifNone: () => 0,
          ),
          throwsA(same(error)),
        );
        expect(
          () => const Option<int>.none().fold<int>(
            ifSome: (value) => value,
            ifNone: () => throw error,
          ),
          throwsA(same(error)),
        );
      });

      test('getOrNull cannot distinguish present null from absence', () {
        expect(const Option.some(42).getOrNull(), 42);
        expect(const Option<int>.none().getOrNull(), isNull);
        expect(const Option<String?>.some(null).getOrNull(), isNull);
        expect(const Option<String?>.none().getOrNull(), isNull);
      });

      test('toList returns an unmodifiable zero-or-one-element list', () {
        final someList = const Option.some(42).toList();
        final nullList = const Option<String?>.some(null).toList();
        final noneList = const Option<int>.none().toList();

        expect(someList, [42]);
        expect(nullList, [null]);
        expect(noneList, isEmpty);
        expect(someList.clear, throwsUnsupportedError);
        expect(nullList.clear, throwsUnsupportedError);
        expect(noneList.clear, throwsUnsupportedError);
      });
    });

    group('fallbacks', () {
      test('getOrElse computes a fallback only for None', () {
        var callCount = 0;
        int defaultValue() {
          callCount++;
          return 0;
        }

        expect(const Option.some(42).getOrElse(defaultValue), 42);
        expect(const Option<int>.none().getOrElse(defaultValue), 0);

        const Option<String?> presentNull = Some<Null>(null);
        expect(
          presentNull.getOrElse(() {
            callCount++;
            return 'fallback';
          }),
          isNull,
        );

        const Option<String?> absent = None();
        expect(
          absent.getOrElse(() {
            callCount++;
            return null;
          }),
          isNull,
        );
        expect(callCount, 2);
      });

      test('getOrElse propagates exceptions from its fallback', () {
        final error = StateError('No default value');

        expect(
          () => const Option<int>.none().getOrElse(() => throw error),
          throwsA(same(error)),
        );
      });

      test('or evaluates its alternative eagerly', () {
        const some = Option.some(42);
        const none = Option<int>.none();
        var callCount = 0;

        Option<int> alternative() {
          callCount++;
          return const Option.some(0);
        }

        expect(some.or(alternative()), same(some));
        expect(callCount, 1);
        expect(none.or(alternative()), const Some(0));
        expect(callCount, 2);

        const Option<String?> presentNull = Some<Null>(null);
        const Option<String?> absent = None();
        const Option<String?> nullAlternative = Some<Null>(null);
        expect(
          presentNull.or(const Some<String?>('fallback')),
          same(presentNull),
        );
        expect(absent.or(nullAlternative), same(nullAlternative));
      });

      test('orElse computes its alternative only for None', () {
        const some = Option.some(42);
        const none = Option<int>.none();
        var callCount = 0;

        Option<int> alternative() {
          callCount++;
          return const Option.some(0);
        }

        expect(some.orElse(alternative), same(some));
        expect(none.orElse(alternative), const Some(0));
        expect(callCount, 1);

        const Option<String?> presentNull = Some<Null>(null);
        expect(
          presentNull.orElse(() => throw StateError('Must not run')),
          same(presentNull),
        );

        const Option<String?> absent = None();
        var nullableCallCount = 0;
        expect(
          absent.orElse(() {
            nullableCallCount++;
            return const Some<Null>(null);
          }),
          const Some<Null>(null),
        );
        expect(nullableCallCount, 1);
      });

      test('orElse propagates exceptions from its alternative', () {
        final error = StateError('No alternative');

        expect(
          () => const Option<int>.none().orElse(() => throw error),
          throwsA(same(error)),
        );
      });
    });

    group('composition', () {
      test('flatten removes one level while preserving nullable payloads', () {
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

        const inner = Some<Null>(null);
        const Option<Option<String?>> present = Some<Option<Null>>(inner);
        const Option<Option<String?>> innerNone = Some<Option<Never>>(None());
        expect(present.flatten(), same(inner));
        expect(innerNone.flatten(), const None());
      });

      test('combine runs only for two Some values and preserves null', () {
        var callCount = 0;
        int add(int left, int right) {
          callCount++;
          return left + right;
        }

        const left = Option.some(20);
        const right = Option.some(22);
        const none = Option<int>.none();
        expect(left.combine(right, add), const Some(42));
        expect(left.combine(none, add), const None());
        expect(none.combine(right, add), const None());
        expect(none.combine(none, add), const None());
        expect(callCount, 1);

        const Option<num?> nullValue = Some<Null>(null);
        const Option<num?> two = Some<int>(2);
        final seen = <(num?, num?)>[];
        num? returnNull(num? first, num? second) {
          seen.add((first, second));
          return null;
        }

        expect(
          nullValue.combine(two, returnNull),
          const Some<num?>(null),
        );
        expect(
          two.combine(nullValue, returnNull),
          const Some<num?>(null),
        );
        expect(seen, [(null, 2), (2, null)]);
      });

      test('combine propagates exceptions from its callback', () {
        final error = StateError('Combination failed');

        expect(
          () => const Option.some(1).combine(
            const Option.some(2),
            (left, right) => throw error,
          ),
          throwsA(same(error)),
        );
      });
    });

    group('value conversions', () {
      test('some wraps null while toOption treats null as absence', () {
        final value = _nullable<String>(null);
        final Option<String?> wrapped = value.some();
        final converted = value.toOption();

        expect(42.some(), const Some(42));
        expect(wrapped, const Some<String?>(null));
        expect(converted, const None());
        expect(null.some(), const Some<Null>(null));
        expect(NullableObjectToOption<String>(null).toOption(), const None());

        final String? name = _nullable('Ada');
        expect(name.toOption().map((value) => value.length), const Some(3));
      });
    });

    group('covariance safety', () {
      const Option<num> widenedSome = Some<int>(1);
      const Option<num> widenedNone = None();

      test('state, side effects, and consumers support widened variants', () {
        expect(widenedSome.isSome, isTrue);
        expect(widenedSome.isNone, isFalse);
        expect(widenedNone.isSome, isFalse);
        expect(widenedNone.isNone, isTrue);

        final observed = <num>[];
        var noneCallCount = 0;
        expect(widenedSome.onSome(observed.add), same(widenedSome));
        expect(widenedNone.onSome(observed.add), same(widenedNone));
        expect(
          widenedSome.onNone(() => noneCallCount++),
          same(widenedSome),
        );
        expect(
          widenedNone.onNone(() => noneCallCount++),
          same(widenedNone),
        );
        expect(observed, [1]);
        expect(noneCallCount, 1);

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
        expect(widenedSome.getOrNull(), 1);
        expect(widenedNone.getOrNull(), isNull);
        expect(widenedSome.toList(), <num>[1]);
        expect(widenedNone.toList(), isEmpty);
      });

      test('transformations support widened variants', () {
        expect(
          widenedSome.map((value) => value.toDouble()),
          const Some<double>(1),
        );
        expect(
          widenedNone.map((value) => value.toDouble()),
          const None(),
        );
        expect(
          widenedSome.flatMap((value) => Some('value:$value')),
          const Some<String>('value:1'),
        );
        expect(
          widenedNone.flatMap((value) => Some('value:$value')),
          const None(),
        );
        expect(widenedSome.filter((value) => value > 0), same(widenedSome));
        expect(widenedNone.filter((value) => value > 0), same(widenedNone));
      });

      test('fallbacks support widened variants', () {
        var defaultCallCount = 0;
        num defaultValue() {
          defaultCallCount++;
          return 2.5;
        }

        expect(widenedSome.getOrElse(defaultValue), 1);
        expect(widenedNone.getOrElse(defaultValue), 2.5);
        expect(defaultCallCount, 1);

        const Option<num> alternative = Some<double>(2.5);
        expect(widenedSome.or(alternative), same(widenedSome));
        expect(widenedNone.or(alternative), same(alternative));

        var alternativeCallCount = 0;
        Option<num> createAlternative() {
          alternativeCallCount++;
          return alternative;
        }

        expect(widenedSome.orElse(createAlternative), same(widenedSome));
        expect(widenedNone.orElse(createAlternative), same(alternative));
        expect(alternativeCallCount, 1);
      });

      test('composition supports widened variants', () {
        const Option<Option<num>> nestedSome = Some<Option<int>>(Some<int>(1));
        const Option<Option<num>> nestedInnerNone = Some<Option<int>>(None());
        const Option<Option<num>> nestedNone = None();

        expect(nestedSome.flatten(), const Some<int>(1));
        expect(nestedInnerNone.flatten(), const None());
        expect(nestedNone.flatten(), const None());

        var callCount = 0;
        num add(num left, num right) {
          callCount++;
          return left + right;
        }

        expect(
          widenedSome.combine(const Some<double>(2.5), add),
          const Some<double>(3.5),
        );
        expect(widenedSome.combine(widenedNone, add), const None());
        expect(
          widenedNone.combine(const Some<double>(2.5), add),
          const None(),
        );
        expect(callCount, 1);
      });
    });

    group('pattern matching', () {
      test('an exhaustive switch distinguishes presence, null, and absence',
          () {
        String describe<T>(Option<T> option) => switch (option) {
              Some(:final value) => 'Some($value)',
              None() => 'None',
            };

        expect(describe(const Option.some(42)), 'Some(42)');
        expect(describe(const Some<Null>(null)), 'Some(null)');
        expect(describe(const Option<int>.none()), 'None');
        expect(describe(const None()), 'None');
      });
    });

    group('value semantics', () {
      test('Some uses its value across generic type arguments', () {
        const first = Some<int>(42);
        const second = Some<num>(42);

        expect(identical(first, second), isFalse);
        expect(first, second);
        expect(second, first);
        expect(first.hashCode, second.hashCode);
        expect(first, isNot(const Some(0)));
        expect(first, isNot(const None()));
        expect(const None(), isNot(first));
        expect(first.toString(), 'Option.Some(42)');
      });

      test('Some(null) is equal across generic type arguments', () {
        const first = Some<Null>(null);
        const second = Some<String?>(null);
        const third = Some<Object?>(null);

        expect(first, second);
        expect(second, first);
        expect(second, third);
        expect(third, second);
        expect(first.hashCode, second.hashCode);
        expect(second.hashCode, third.hashCode);
        expect(first.hashCode, null.hashCode);
        expect(first, isNot(const None()));
        expect(first.toString(), 'Option.Some(null)');
      });

      test('all None values are equal and share a non-zero hash code', () {
        // These calls intentionally omit `const` to create distinct instances.
        // ignore: prefer_const_constructors
        final first = Option<int>.none();
        // This call also omits `const` so it is not identical to `first`.
        // ignore: prefer_const_constructors
        final second = Option<String>.none();

        expect(identical(first, second), isFalse);
        expect(first, second);
        expect(second, first);
        expect(first.hashCode, second.hashCode);
        expect(first.hashCode, isNot(0));
        expect(first.toString(), 'Option.None');
      });
    });
  });
}

T? _nullable<T extends Object>(T? value) => value;
