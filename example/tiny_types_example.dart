import 'dart:io';

import 'package:tiny_types/tiny_types.dart';

void main() async {
  final rawName = _readName();

  final greeting = rawName
      .toOption()
      .map((name) => name.trim())
      .filter((name) => name.isNotEmpty)
      .map((name) => 'Hello, $name!')
      .getOrElse(() => 'Hello!');
  _log(greeting);

  final result = await _saveSettings();
  _log('Settings saved: $result');

  _reportScores([7, 3, 9]);
  _reportScores([]);
}

void _reportScores(List<int> rawScores) {
  final scores = rawScores.toNonEmptyListOrNone();

  final report = scores.fold(
    ifSome: _describeScores,
    ifNone: () => 'No scores recorded',
  );
  _log(report);
}

String _describeScores(NonEmptyList<int> scores) {
  // `head`, `reduce`, and `min` cannot fail for a non-empty list.
  final total = scores.reduce((left, right) => left + right);
  final labels = scores.map((score) => 'score: $score');

  return '${labels.head}, lowest: ${scores.min()}, total: $total';
}

String? _readName() {
  // Example output is intentionally written to the console.
  // ignore: avoid_print
  print('Enter your name:');
  return stdin.readLineSync();
}

Future<Unit> _saveSettings() async {
  await Future<void>.value();
  return Unit.value;
}

void _log(String message) {
  // Example output is intentionally written to the console.
  // ignore: avoid_print
  print(message);
}
