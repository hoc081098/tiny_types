# Repository Guidelines

## Project Structure & Module Organization

This repository is a focused Dart package for small, reusable utility types.
Public implementations live in `lib/src/` (for example, `option.dart` and
`unit.dart`). Export supported APIs from the package barrel,
`lib/tiny_types.dart`; a type in `lib/src/` is not part of the normal public
import until it is exported there. Tests live in `test/` and should mirror the
feature they exercise, such as `test/unit_test.dart`. Package metadata and SDK
constraints are defined in `pubspec.yaml`, while lint and formatter policy is
in `analysis_options.yaml`.

## Build, Test, and Development Commands

- `dart pub get` installs package and development dependencies.
- `dart analyze` runs the strict analyzer and configured lint rules.
- `dart format --output=none --set-exit-if-changed .` checks formatting without
  modifying files; use `dart format .` to apply it.
- `dart test` runs the complete test suite.
- `dart test test/unit_test.dart` runs one test file while iterating.
- `dart pub publish --dry-run` validates package contents before a release.

Run analysis and tests before opening a pull request.

## Coding Style & Naming Conventions

Use standard Dart formatting (two-space indentation) and keep lines within 80
characters. The project enables strict casts, inference, and raw-type checks,
plus `package:lints/recommended.yaml`. Use `lower_snake_case.dart` for files,
`UpperCamelCase` for types, `lowerCamelCase` for members, and single quotes for
strings. Prefer final locals, explicit public API types, exhaustive sealed-type
switches, and trailing commas in multiline declarations. Document every public
member with Dartdoc and keep imports ordered; use relative imports inside
`lib/src/` and package imports from tests or consumers.

### Result-use annotations

Use `@useResult` when ignoring a synchronous API's return value is always a
mistake. This includes `Option`-returning transformations, boolean state
getters, and value conversions such as `getOrNull` and `toList`.

Do not use `@useResult` on:

- Methods returning `Future<Option<...>>`; callers may only need to await them.
- Fire-and-forget side-effect helpers whose returned value exists only for
  chaining, such as `onSome` and `onNone`.
- Methods with a generic result that may be `void`, such as `fold` or a future
  `when` API. These methods may intentionally be used as statements when their
  callbacks perform side effects.
- Constructors or factory constructors.

When adding an annotation, include analyzer-clean coverage for both using and,
where intentionally supported, ignoring the result.

## Testing Guidelines

Tests use `package:test`. Group cases by type or feature and name tests after
observable behavior, following the existing `group('Unit', ...)` pattern. Add
tests for success, absence, equality, conversion, and edge cases when changing
value types. Keep tests deterministic and assert public behavior rather than
private implementation details. No numeric coverage threshold is configured,
but new behavior should arrive with regression coverage.

## Commit & Pull Request Guidelines

Recent history uses short, imperative subjects with Conventional Commit-style
prefixes, for example `refactor: enhance documentation` or
`feat(option): add conversion helpers`. Keep each commit focused. Pull requests
should explain the motivation and API impact, list validation commands run, and
link related issues. Include migration notes for breaking public API changes;
screenshots are unnecessary unless documentation gains visual assets.
