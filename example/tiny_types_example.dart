import 'package:tiny_types/tiny_types.dart';

final _savedOrders = <List<String>>[];

Future<void> main() async {
  // --------- Input from a checkout form ---------
  final customerName = _customerNameFromForm();
  final rawItems = <String>['coffee', 'tea', 'coffee'];

  // --------- Optional customer name ---------
  final displayName = customerName
      .toOption()
      .map((name) => name.trim())
      .filter((name) => name.isNotEmpty)
      .getOrElse(() => 'Guest');

  // --------- Non-empty cart ---------
  final cart = rawItems.toNonEmptyListOrNull();
  if (cart == null) {
    _log('Cart is empty; nothing to save.');
    return;
  }

  final lines = cart.mapIndexedToNonEmptyList(
    (index, item) => '${index + 1}. $item',
  );
  final products = cart.toNonEmptySet();

  // --------- Price catalog and order total ---------
  final prices = NonEmptyMap.of(('coffee', 4.50), tail: const {'tea': 3.00});
  final total = cart.fold<double>(
    0,
    (sum, item) =>
        sum + (prices[item] ?? (throw StateError('Unknown product: $item'))),
  );

  _log('Customer: $displayName');
  _log('Items: ${lines.join(', ')}');
  _log('Unique products: ${products.join(', ')}');
  _log('Total: \$${total.toStringAsFixed(2)}');

  // --------- Save the order ---------
  final saved = await _saveOrder(cart);
  _log('Saved: $saved');
}

// --------- Sample form data ---------
String? _customerNameFromForm() => ' Ada ';

// --------- In-memory order store ---------
Future<Unit> _saveOrder(NonEmptyList<String> cart) {
  _savedOrders.add(cart.toList());
  return Unit.future;
}

void _log(String message) {
  // Example output is intentionally written to the console.
  // ignore: avoid_print
  print(message);
}
