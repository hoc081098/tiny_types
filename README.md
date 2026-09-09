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
final value = doubled.getOrElse(() => 0); // 84

final message = doubled.fold(
  ifSome: (value) => 'The answer is $value',
  ifNone: () => 'No answer',
);
```

## Unit

`Unit` represents a successful result with no payload.

### Why not `void`?

In Dart, `void` does not mean that no object exists at runtime. It marks a
result as meaningless and prevents callers from consuming it as an ordinary
value. A `void` result cannot be read, compared, or transformed, or passed to
an API that expects a meaningful value. The value produced by
`await Future<void>` is equally unusable.

There is another subtle difference: a `void Function()` can accept a function
with any return type and silently discard its result.

```dart
int calculate() => 42;

void Function() callback = calculate; // Valid; 42 is discarded.
```

That behavior is useful when a callback's result truly does not matter, but it
does not model a single predictable result. A `Unit Function()` has a stricter
contract: when it completes normally, it must return `Unit.value`.

```dart
Future<Unit> saveSettings() async {
  await repository.save();
  return Unit.value;
}

Future<Option<Unit>> saveAndWrap() async {
  final saved = await saveSettings();
  return Option.some(saved);
}
```

Unlike `void`, `Unit.value` can be stored, passed, compared, and transformed.
This makes types such as `Option<Unit>`, `Future<Unit>`, or
`Result<Failure, Unit>` useful for representing success without inventing a
payload.

Prefer `void` or `Future<void>` when callers should discard the result. Use
`Unit` when a no-payload result needs to remain a first-class value.

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
