# tiny_types roadmap

> Small types, explicit invariants, practical Dart APIs.

This document records the agreed design direction, not a release schedule.
Proposed APIs are not necessarily available yet; see the README and API
reference for implemented features.

## 1. Scope

Keep `tiny_types` small and focused on reusable foundational and value types,
plus utilities directly related to them. Add a type only when it expresses a
widely applicable invariant that is easy to understand and valuable to reuse.

The package is not intended to become a full functional programming framework.
Do not add `Either`, `Reader`, `Writer`, `State`, `IO`, `Validated`, or tuple
types just to complete a functional programming toolkit.

## 2. Core foundation

The existing foundation is:

- `Unit`: one meaningful value with no payload.
- `Option<T>`: an explicitly present or absent non-nullable value.
- `NonEmptyIterable<T>`: the sealed base for non-empty lists and sets.
- `NonEmptyList<T>`: an immutable, ordered list with at least one element.
- `NonEmptySet<T>`: an immutable set with at least one element, keeping unique
  values in first-occurrence order.
- `NonEmptyMap<K, V>`: an immutable, insertion-ordered map with at least one
  entry.

`NonEmptyMap` remains separate from `NonEmptyIterable`, just as Dart's `Map`
is not an `Iterable`. It exposes keys, values, and entries explicitly.

## 3. Planned value types

| Type | Representation | Invariant |
| --- | --- | --- |
| `PositiveInt` | `int` | `value > 0` |
| `NonNegativeInt` | `int` | `value >= 0` |
| `NonEmptyString` | `String` | `value.isNotEmpty` |
| `NonBlankString` | `String` | `value.trim().isNotEmpty` |
| `Percentage` | `double` | Finite; `0 <= value && value <= 100` |

`Percentage` uses the inclusive range `0..100`, not the ratio range `0..1`.
It rejects `NaN` and both infinities. Validation and normalization are separate
concerns: a trimmed-string predicate does not imply silently trimming the
stored value.

## 4. Implementation and creation

Use ordinary Dart classes throughout:

- Keep sealed classes where variants or a closed hierarchy are needed, such
  as `Option` and `NonEmptyIterable`.
- Use immutable final classes with private constructors for the planned value
  types. Each value type has a distinct runtime type.
- Do not use extension types. Their erased representation cannot provide the
  runtime type distinction required by this design.

Prefer safe static factory methods that return `Option`:

```dart
PositiveInt.from(1); // Option<PositiveInt>
NonEmptyString.from('Dart'); // Option<NonEmptyString>
```

These are proposed static methods, not Dart factory constructors. A valid
input returns `Some` containing the validated value; an invalid input returns
`None`. Private constructors must only receive already-validated values.
Validation must work in release builds, not rely on assertions.

Start without throwing or unsafe creation APIs. Consider additional entry
points only when a concrete use case justifies them, with explicit contracts.
An operation returns the same value type only if it preserves its invariant;
otherwise, expose the underlying result or validate it into an `Option`.

## 5. Acceptance criteria

For every new type:

- Document validation, representation access, equality, hashing, and any
  normalization or arithmetic behavior.
- Test valid inputs, invalid inputs, boundaries, and value semantics. Include
  empty and whitespace-only strings, and non-finite percentage inputs.
- Export the API through `lib/tiny_types.dart` and update the README, example,
  and changelog as the type becomes available.
- Keep APIs practical and focused; do not mirror every underlying operation.

## 6. Shared foundation for dart_either

`dart_either` will depend on `tiny_types` to share `Unit`, `Option`, and the
other foundational types as needed. Keep the dependency one-way:
`dart_either` depends on `tiny_types`, never the reverse. Implementation and
migration in `dart_either` are separate follow-up work.
