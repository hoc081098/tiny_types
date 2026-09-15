# tiny_types

`tiny_types` provides lightweight, reusable types that are useful in everyday
Dart applications without requiring a full functional programming library.

- `Option<T>` represents a value that **may be absent**.
- `Unit` represents a **meaningful result with no payload**.
- `NonEmptyList<T>` preserves **order and duplicates** while guaranteeing
  **at least one element**.
- `NonEmptySet<T>` keeps **unique elements in first-occurrence order** while
  guaranteeing **at least one element**.
- `NonEmptyMap<K, V>` keeps **key-value pairs in insertion order** while
  guaranteeing **at least one entry**.

## Installation

```yaml
dependencies:
  tiny_types: ^1.0.0
```

## Option

Use `Option<T>` when absence is part of the API instead of passing `null`
through every step.

```dart
String displayName(String? input) => input
    .toOption()
    .map((value) => value.trim())
    .filter((value) => value.isNotEmpty)
    .getOrElse(() => 'Guest');

displayName(' Ada '); // Ada
displayName(null); // Guest
```

`fold` handles both `Some` and `None` when each case needs different behavior.

## Unit

Use `Unit` when a successful result has no payload but must remain a value,
for example in `Option<Unit>` or `Future<Unit>`. Use `void` when callers should
simply discard the result.

```dart
final Option<Unit> saved = Option.some(Unit.value);
```

## Non-empty collections

`NonEmptyList` and `NonEmptySet` guarantee at least one element. Their shared
sealed base, `NonEmptyIterable<T>`, lets an API accept either kind. `head` and
`reduce` cannot fail due to an empty collection.

```dart
final cart = NonEmptyList.of('coffee', tail: ['tea', 'coffee']);
final products = cart.toNonEmptySet(); // {coffee, tea}
```

For an existing `Iterable` that might be empty, use
`toNonEmptyListOrNull()`, `toNonEmptyListOrNone()`, or
`toNonEmptyListOrThrow()`. The matching `toNonEmptySetOrNull()`,
`toNonEmptySetOrNone()`, and `toNonEmptySetOrThrow()` conversions deduplicate
elements.

### Read-only by design

Both types are `Iterable`s, not `List`s or `Set`s: their mutable members are
not available. `plus` and `plusAll` return new non-empty collections.
`NonEmptyList` also provides indexing and list searches; `NonEmptySet`
provides `containsAll`, `lookup`, and a non-empty `union`.
`NonEmptyList` equality considers order; `NonEmptySet` equality does not.

Use `asList()` or `asSet()` for an unmodifiable view when another API requires
a `List` or `Set`. Standard `toList()` and `toSet()` create modifiable copies.
Operations that may become empty, such as `where` or set difference, return
plain Dart collection types.

### Lazy or guaranteed non-empty

Standard `Iterable` transformations (`map`, `where`, `expand`) stay lazy and
return `Iterable`. Choose an eager `ToNonEmptyList` or `ToNonEmptySet` method
when the result must retain the non-empty guarantee:

```dart
final labels = cart.mapIndexedToNonEmptyList(
  (index, item) => '${index + 1}. $item',
); // [1. coffee, 2. tea, 3. coffee]

final uniqueLabels = cart.mapToNonEmptySet((item) => item.toUpperCase());
// {COFFEE, TEA}
```

The eager variants are `mapToNonEmptyList`, `mapToNonEmptySet`,
`mapIndexedToNonEmptyList`, `mapIndexedToNonEmptySet`,
`flatMapToNonEmptyList`, and `flatMapToNonEmptySet`. The flat-map callbacks
return `NonEmptyIterable`s. List variants preserve duplicates; set variants
deduplicate. `distinct`, `distinctBy`, and `zip` also keep the result non-empty.

### Widening the element type

Dart retains generic types at runtime. Viewing a `NonEmptyList<int>` as
`NonEmptyIterable<num>` does not let its backing list accept a `double` via
`plus` or `plusAll`. Make a checked copy with the desired runtime type first:

```dart
final NonEmptyIterable<num> widened = NonEmptyList<int>.of(1);
final numbers = widened.castToNonEmptyList<num>().plus(1.5);
// [1, 1.5]
```

Use `castToNonEmptySet<R>()` for a set. Both conversions check existing
elements eagerly and throw a `TypeError` if a cast fails.

## NonEmptyMap

Use `NonEmptyMap<K, V>` when at least one key-value pair is required. Supply
the first pair explicitly; later entries with the same key replace its value
without moving the key.

```dart
final prices = NonEmptyMap.of(('coffee', 4.50), tail: {'tea': 3.00});
final updated = prices.plus(('coffee', 5.00));

prices['coffee']; // 4.5 (unchanged)
updated.head; // MapEntry(coffee: 5.0)
```

It is not a `Map` or a `NonEmptyIterable`. `plus`, `plusAll`, and the eager
`map` return new non-empty maps; `asMap()` gives an unmodifiable `Map` view,
and `toMap()` gives a modifiable copy. `head` is always available; `tail`
lazily exposes the remaining entries and may be empty. For a possibly empty
`Map`, use `toNonEmptyMapOrNull()`, `toNonEmptyMapOrNone()`, or
`toNonEmptyMapOrThrow()`; each copies the input. If values may be `null`, use
`containsKey()` to distinguish an absent key from a present `null` value.
Use `castToNonEmptyMap<RK, RV>()` to make an eagerly checked copy before
adding wider key or value types to a covariantly widened receiver.

See the [runnable checkout example](example/tiny_types_example.dart) for all
five types together.

## License

```
MIT License

Copyright (c) 2026 Petrus Nguyễn Thái Học
```
