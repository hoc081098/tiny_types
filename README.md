# tiny_types

Small, focused utility types for Dart.

`tiny_types` provides lightweight, reusable types that are useful in everyday
Dart applications without requiring a full functional programming library.

## Features

- `Option<T>` — represents the presence or absence of a value.
- `Unit` — represents a meaningful value when no data needs to be returned.
- `NonEmptyCollection<T>` — common abstraction for collections guaranteed to contain at least one element.
- `NonEmptyList<T>` — a list guaranteed to contain at least one element.
- `NonEmptySet<T>` — a set guaranteed to contain at least one element.
- Related constructors, transformations, extensions, and utility functions.

## Installation

```yaml
dependencies:
  tiny_types: ^1.0.0
```

## Option

Use `Option<T>` when a value may or may not exist without representing absence
with `null`.

```dart
final Option<int> some = Option.some(42);
final Option<int> none = Option.none();

final doubled = some.map((value) => value * 2);

final message = doubled.fold(
  ifSome: (value) => 'The answer is $value',
  ifNone: () => 'No answer',
);
```

## Unit

`Unit` represents a single meaningful value when an operation has no useful
result to return.

```dart
Future<Unit> saveSettings() async {
  await repository.save();
  return Unit.value;
}
```

It is useful for APIs where success itself matters but no additional value
needs to be returned. Because `Unit` is a regular value, it can also be used as
a type argument in other result types.

## Non-empty collections

TBD - Unimplemented.

Non-empty collection types guarantee at the type level that at least one
element exists.

```dart
final users = NonEmptyList.of(
  firstUser,
  [secondUser, thirdUser],
);
```

This allows APIs to express requirements such as:

```dart
void sendNotifications(NonEmptyList<User> recipients) {
  // recipients can never be empty.
}
```

instead of accepting a regular `List<User>` and validating it at runtime at
every call site.

## Design goals

`tiny_types` is intentionally small and focused.

The package aims to provide useful foundational types and their closely related
utilities without becoming a large functional programming framework.

- Small API surface
- Strong type safety
- Practical Dart-friendly APIs
- Minimal dependencies
- Predictable semantics
- Easy interoperability with other libraries

## Related packages

`tiny_types` is designed to work well as a lightweight foundation for packages
such as [`dart_either`](https://pub.dev/packages/dart_either).

For example, integrations can provide conversions such as:

```text
Either<L, R> -> Option<R>
Option<R> -> Either<L, R>
Either<L, Unit>
```

See the complete runnable
[`tiny_types` example](example/tiny_types_example.dart).

## License

```

```