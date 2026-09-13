## 1.0.0 - TBD

- Initial version.
- Add the sealed `NonEmptyIterable<T>` and its two implementations,
  `NonEmptyList<T>` and `NonEmptySet<T>`. Both implement `Iterable<T>` and
  provide read-only list-like or set-like operations without implementing
  `List<T>` or `Set<T>`. Updates return new collections; `asList()` and
  `asSet()` provide unmodifiable views, while `toList()` and `toSet()` create
  modifiable copies.
- Add `Iterable` conversions (`toNonEmptyListOrNull`, `toNonEmptyListOrNone`,
  `toNonEmptyListOrThrow`, and their `NonEmptySet` counterparts).
- Keep inherited `Iterable` transformations lazy, and add eager transformations
  that materialize a `NonEmptyList` or `NonEmptySet` while preserving the
  non-empty guarantee.
- Delegate common `Iterable` operations to the backing list or set, and expose
  the read-only `NonEmptySet.containsAll` query directly.
