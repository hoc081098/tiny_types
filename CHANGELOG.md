## 1.0.0 - 2026-10-16

Initial stable release. Requires Dart `^3.0.0`.

- **Option:** add sealed `Option<T>` with `Some<T>` and `None`, supporting
  pattern matching, value equality, transformations, composition, lazy
  fallbacks, and side effects. `Some(null)` remains present;
  `Option.fromNullable` and `toOption()` treat `null` as absence.

- **Collection lookups:** add presence-preserving `OrNone` lookups for
  iterables and maps. Selected `null` values remain present. Single-element
  lookups return `None` for zero or multiple elements or matches; map lookups
  respect the map's own key equality rules.

- **Unit:** add `Unit.value` for a meaningful result with no payload, plus
  a shared `Unit.future` that completes with that value.

- **Non-empty collections:** add immutable `NonEmptyList<T>`,
  `NonEmptySet<T>`, and `NonEmptyMap<K, V>`, with a sealed
  `NonEmptyIterable<T>` base for lists and sets. Each collection guarantees at
  least one element or entry. Lists preserve order and duplicates, sets keep
  first-occurrence order, and maps keep key insertion order. Provide structural
  equality, unmodifiable views, and modifiable copies.

- **Collection operations:** add non-mutating additions, non-empty-preserving
  transformations, deduplication, zip/unzip, flattening, and checked casts.
  Standard iterable transformations stay lazy; non-empty-preserving
  transformations are eager. Conversions from possibly empty inputs offer
  `OrNull`, `OrNone`, and `OrThrow` variants, with `StateError` for empty input
  in throwing conversions.
