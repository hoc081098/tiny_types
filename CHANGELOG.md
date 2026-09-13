## 1.0.0 - TBD

- Initial version.
- Add the sealed `NonEmptyIterable<T>` and its two implementations,
  `NonEmptyList<T>` and `NonEmptySet<T>`. Both are `Iterable<T>` and neither
  implements `List<T>` or `Set<T>`, so mutating members of those interfaces
  are not exposed directly. `asList()` and `asSet()` return unmodifiable views
  for APIs that need the plain types.
- Add `Iterable` conversions (`toNonEmptyListOrNull`, `toNonEmptyListOrNone`,
  `toNonEmptyListOrThrow`, and their `NonEmptySet` counterparts).
- Keep inherited `Iterable` transformations lazy, and add eager transformations
  that materialize a `NonEmptyList` or `NonEmptySet` while preserving the
  non-empty guarantee.
- Delegate common `Iterable` operations to the backing list or set, and expose
  the read-only `NonEmptySet.containsAll` query directly.
