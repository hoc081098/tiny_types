## 1.0.0 - TBD

- Initial version.
- Add the sealed `NonEmptyCollection<T>` and its two implementations,
  `NonEmptyList<T>` and `NonEmptySet<T>`. Both are `Iterable<T>` and neither
  implements `List<T>` or `Set<T>`, so no member can be reached that would
  throw at run time; `asList()` and `asSet()` return an unmodifiable view for
  APIs that need the plain type.
- Add `Iterable` conversions (`toNonEmptyListOrNull`, `toNonEmptyListOrNone`,
  `toNonEmptyListOrThrow`, and their `NonEmptySet` counterparts).
- Keep inherited `Iterable` transformations lazy, and add eager transformations
  that materialize a `NonEmptyList` or `NonEmptySet` while preserving the
  non-empty guarantee.
