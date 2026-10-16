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

## 1. Installation

```yaml
dependencies:
  tiny_types: ^1.0.0
```

## 2. Option

Use `Option<T>` when absence is part of the API: `Some<T>` contains a value,
and `None` contains no value.

### 2.1. Creation and nullability

**Presence and nullability are independent.** `Option<String>` has a
non-nullable payload; `Option<String?>` may contain `null`.

`Option.some(value)` and `value.some()` wrap a value unchanged.
`Option.fromNullable(value)` and `value.toOption()` treat `null` as absence.
Use `Option.none()` to create an absent option explicitly.

```dart
const Option<String?> note = Option.some(null); // Present: Some(null)
final Option<String> name = Option.fromNullable(null); // Absent: None
```

### 2.2. Transforming and consuming

- `map` transforms the contained value while preserving absence.
- `flatMap` chains an option-returning operation.
- `filter` keeps the contained value when its predicate returns `true`;
  otherwise, it returns `None`.

```dart
String displayName(String? input) => input
    .toOption()
    .map((value) => value.trim())
    .filter((value) => value.isNotEmpty)
    .getOrElse(() => 'Guest');

displayName(' Ada '); // Ada
displayName(null); // Guest
```

- `fold` produces a value by handling both variants.
- `getOrElse` returns the contained value or a lazily computed fallback for
  `None`.
- `or` returns this option when it is `Some`, or an eagerly evaluated
  alternative when it is `None`.
- `orElse` lazily computes an alternative `Option` for `None`.
- `getOrNull()` returns the contained value, or `null` for `None`. It cannot
  distinguish `Some(null)` from `None`.

### 2.3. Collection lookups

Lookups preserve presence, even when the selected value is `null`:

```dart
<int?>[null].firstOrNone; // Option.Some(null)
<int?>[].firstOrNone; // Option.None

final fields = <String, String?>{'note': null};
fields.getOrNone('note'); // Option.Some(null)
fields.getOrNone('missing'); // Option.None
```

- `Iterable.firstOrNone`, `lastOrNone`, and `singleOrNone` are getters.
- `Iterable.firstWhereOrNone`, `lastWhereOrNone`, and `singleWhereOrNone`
  accept a predicate.
- `Map.getOrNone(key)` uses the map's own key equality rules.

The `single` lookups return `None` unless exactly one element or match exists.
Iterable lookups do not materialize a collection. Iterator and predicate
exceptions propagate.

## 3. Unit

Use `Unit` when a successful result has no payload but must remain a value,
for example in `Option<Unit>` or `Future<Unit>`. Use `void` when callers should
simply discard the result.

```dart
final Option<Unit> saved = Option.some(Unit.value);
```

## 4. Non-empty collections

### 4.1. Choose a collection

| Type | Guarantee and iteration |
| --- | --- |
| `NonEmptyList<T>` | Non-empty; keeps order and duplicates. |
| `NonEmptySet<T>` | Non-empty; unique values in first-occurrence order. |
| `NonEmptyMap<K, V>` | Non-empty; keeps key insertion order. |

`NonEmptyList` and `NonEmptySet` share the sealed
`NonEmptyIterable<T>` base because both are `Iterable`s. `NonEmptyMap` remains
separate, like Dart's `Map`, and exposes its keys, values, and entries
explicitly.

```dart
final cart = NonEmptyList.of('coffee', tail: ['tea', 'coffee']);
final products = cart.toNonEmptySet(); // {coffee, tea}
final prices = NonEmptyMap.of(('coffee', 4.50), tail: {'tea': 3.00});
```

### 4.2. Convert possibly empty inputs

Use conversion extensions and choose how to handle an empty input: `OrNull`
returns `null`, `OrNone` returns `None`, and `OrThrow` throws a `StateError`.

```dart
[1, 2].toNonEmptyListOrNull(); // [1, 2]
[1, 2, 1].toNonEmptySetOrNone(); // Option.Some({1, 2})
<String, int>{'a': 1}.toNonEmptyMapOrThrow(); // {a: 1}
```

All three suffixes are available for each conversion:

- `Iterable.toNonEmptyListOr...()` preserves order and duplicates.
- `Iterable.toNonEmptySetOr...()` keeps the first occurrence of each value.
- `Map.toNonEmptyMapOr...()` copies entries into an insertion-ordered map.

Use `OrNull` or `OrNone` when emptiness is expected. Use `OrThrow` when an
empty input indicates invalid program state.

### 4.3. Read-only by design

The types do not implement `List`, `Set`, or `Map`, whose interfaces include
mutating members. `plus` and `plusAll` return new non-empty collections
without changing the originals.

All three expose a `head` that cannot fail due to an empty collection and a
lazy `tail` containing the remaining elements or entries. The `tail` may be
empty. For a `NonEmptyMap`, `head` and `tail` contain `MapEntry` values.

- `NonEmptyList` provides indexing and list searches.
- `NonEmptySet` provides `containsAll`, `lookup`, and non-empty `union`.
- `NonEmptyMap` provides key and value lookup plus lazy entry views. When
  values may be `null`, use `containsKey()` to distinguish a missing key.

Use `asList()`, `asSet()`, or `asMap()` for an unmodifiable view when another
interface requires the plain Dart type. Use `toList()`, `toSet()`, or
`toMap()` for a modifiable copy. Operations that may become empty return plain
Dart collection types.

Equality follows each collection's meaning: list equality considers order;
set and map equality do not. Plain Dart collections are not equal to their
non-empty counterparts.

### 4.4. Lazy and guaranteed transformations

For `NonEmptyList` and `NonEmptySet`, standard `Iterable` transformations
such as `map`, `where`, and `expand` stay lazy and return `Iterable`. Choose an
eager `ToNonEmptyList` or `ToNonEmptySet` method when the result must retain
the non-empty guarantee:

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

`NonEmptyMap.map` is eager and returns another `NonEmptyMap`. If transformed
keys are equal, the last value wins without moving the key's first position.

### 4.5. Widen runtime types

Dart retains generic types at runtime. Viewing a `NonEmptyList<int>` as
`NonEmptyIterable<num>` does not let its backing list accept a `double` via
`plus` or `plusAll`. Make a checked copy with the desired runtime type first:

```dart
final NonEmptyIterable<num> widened = NonEmptyList<int>.of(1);
final numbers = widened.castToNonEmptyList<num>().plus(1.5);
// [1, 1.5]
```

Use `castToNonEmptySet<R>()` for a set. Both conversions check existing
elements eagerly and throw a `TypeError` if a cast fails. For maps, use
`castToNonEmptyMap<RK, RV>()` before adding wider key or value types.

See the [runnable checkout example][checkout-example] for all five types
together.

See the [roadmap] for the package's scope and planned value types.

## 5. License

```
MIT License

Copyright (c) 2026 Petrus Nguyễn Thái Học
```

[checkout-example]:
  https://github.com/hoc081098/tiny_types/blob/main/example/tiny_types_example.dart
[roadmap]: https://github.com/hoc081098/tiny_types/blob/main/ROADMAP.md
