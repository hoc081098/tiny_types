import 'dart:io';

import 'package:tiny_types/tiny_types.dart';

void main() async {
  final rawName = _readName();

  rawName
      .toOption()
      .map((name) => name.trim())
      .filter((name) => name.isNotEmpty)
      .map((name) => 'Hello, $name!')
      .orElse(() => const Option.some('Hello!'))
      .onSome(_log);

  final result = await _saveSettings();
  _log('Settings saved: $result');
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
