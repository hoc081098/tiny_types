# tiny_types

Small, focused utility types for Dart.

`tiny_types` provides lightweight, reusable types that are useful in everyday
Dart applications without requiring a full functional programming library.

## Features

- `Option<T>` — represents the presence or absence of a value.
- `Unit` — represents a meaningful value when no data needs to be returned.
- `NonEmptyIterable<T>` — common abstraction for iterables guaranteed
  to contain at least one element.
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

### Not a `List`, not a `Set`

Both types are `Iterable<T>`, and neither implements `List<T>` or `Set<T>` on
purpose. In Dart those interfaces declare mutating members, so an immutable
collection can only implement them by throwing at run time, which would put
the invariant back to something a call site can only discover by crashing.

```dart
final NonEmptyList<User> users = ...;

users.add(newUser); // Does not compile at all.
```

`asList()` and `asSet()` return an unmodifiable view in constant time, while
`toList()` and `toSet()` return a modifiable copy. Operations that can produce
an empty result return their normal Dart collection type.

```dart
render(users.asList()); // For an API that needs a `List<User>`.
users.asList().sublist(1); // Possibly empty, so it is a plain `List`.
tags.containsAll(['dart']); // Read-only set queries stay directly available.
tags.asSet().difference(banned); // Possibly empty, so it is a plain `Set`.
```

`plus`, `plusAll`, `distinct`, and `distinctBy` preserve the concrete non-empty
kind. `operator +` provides the corresponding shorthand for `NonEmptyList`.

`NonEmptyIterable<T>` is a sealed type, so `NonEmptyList` and `NonEmptySet`
are its only implementations and a switch over them is exhaustive.

Because at least one element always exists, operations that are partial on a
regular collection become total.

```dart
final scores = NonEmptyList.of(7, [3, 9]);

scores.head; // 7, and it can never throw
scores.reduce((left, right) => left + right); // 19
```

Inherited `Iterable` transformations keep Dart's standard lazy behavior and
return an `Iterable`. This includes `map`, `where`, and `expand`.

```dart
final Iterable<String> lazyLabels =
    scores.map((score) => 'score: $score');

final Iterable<int> positive = scores.where((score) => score > 0);
// `positive` can be empty.
```

Use an eager non-empty-preserving transformation when the result should be
materialized immediately. List-producing operations preserve order and
duplicates; explicitly choose a set-producing variant to collapse equal
results.

```dart
final NonEmptyList<String> labels =
    scores.mapToNonEmptyList((score) => 'score: $score');

final NonEmptySet<bool> parity =
    scores.mapToNonEmptySet((score) => score.isEven);

final NonEmptyList<int> doubled =
    scores.flatMapToNonEmptyList(
      (score) => NonEmptyList.of(score, [score]),
    );
```

The available materializing transformations are `mapToNonEmptyList`,
`mapToNonEmptySet`, `mapIndexedToNonEmptyList`,
`mapIndexedToNonEmptySet`, `flatMapToNonEmptyList`, and
`flatMapToNonEmptySet`. Both flat-mapping methods require each callback result
to be a `NonEmptyIterable`, so the combined result cannot be empty.

The explicit `mapIndexedToNonEmptyList` name avoids changing the lazy
`mapIndexed` semantics supplied by `package:collection` when that extension is
imported. The `flatMapToNonEmptyList` and `flatMapToNonEmptySet` names likewise
make the materialized result type explicit.

### Converting from an existing collection

A collection whose length is only known at runtime is converted with the
`Iterable` extensions, which never throw away the empty case silently.

```dart
final List<User> selected = readSelection();

final NonEmptyList<User>? orNull = selected.toNonEmptyListOrNull();
final Option<NonEmptyList<User>> orNone = selected.toNonEmptyListOrNone();
final NonEmptyList<User> orThrow = selected.toNonEmptyListOrThrow();
```

`toNonEmptySetOrNull`, `toNonEmptySetOrNone`, and `toNonEmptySetOrThrow` do the
same for `NonEmptySet<T>`.

### Choosing between the two

Use `NonEmptyList<T>` to preserve order and duplicates, and `NonEmptySet<T>`
for unique elements. `NonEmptyIterable<T>` is the shared abstraction to
accept either one.

```dart
int total(NonEmptyIterable<int> scores) =>
    scores.reduce((left, right) => left + right);

total(NonEmptyList.of(1, [2, 2])); // 5
total(NonEmptySet.of(1, [2, 2])); // 3
```

`mapToNonEmptyList`, `mapIndexedToNonEmptyList`, and
`flatMapToNonEmptyList` preserve iteration order and duplicates. Their
`ToNonEmptySet` counterparts preserve first-occurrence order and collapse equal
values.

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
MIT License

Copyright (c) 2026 Petrus Nguyễn Thái Học
```
