import 'package:tiny_types/tiny_types.dart';

Future<void> main() async {
  // --------- Checkout form input ---------
  final customerName = _customerNameFromForm();
  final rawItems = <String>['coffee', 'tea', 'coffee'];
  final deliveryFields = <String, String?>{'note': null};

  // --------- Optional customer details ---------
  final displayName = customerName
      .toOption()
      .map((name) => name.trim())
      .filter((name) => name.isNotEmpty)
      .getOrElse(() => 'Guest');

  // A missing note uses the default; an explicit null clears the note.
  final deliveryNote = deliveryFields.getOrNone('note').fold(
        ifSome: (n) => n ?? '<cleared>',
        ifNone: () => 'Leave at reception',
      );

  // --------- Non-empty cart ---------
  final cart = rawItems.toNonEmptyListOrNull();
  if (cart == null) {
    _log('Cart is empty; nothing to save.');
    return;
  }

  final lines = cart.mapIndexedToNonEmptyList(
    (index, item) => '${index + 1}. $item',
  );
  final uniqueProducts = cart.toNonEmptySet();
  final teaInCart = cart.firstWhereOrNone((item) => item == 'tea');

  // --------- Prices and order total ---------
  final prices = NonEmptyMap.of(
    ('coffee', 4.50),
    tail: const {'tea': 3.00},
  );
  final total = cart.fold<double>(0, (sum, item) {
    final price = prices[item] ?? (throw StateError('Unknown product: $item'));
    return sum + price;
  });

  // --------- Order summary ---------
  _log('Customer: $displayName');
  _log('Delivery note: $deliveryNote');
  _log('Items: ${lines.join(', ')}');
  _log('Unique products: ${uniqueProducts.join(', ')}');
  _log('Tea discount eligible: ${teaInCart.isSome}');
  _log('Total: \$${total.toStringAsFixed(2)}');

  // --------- Save the order ---------
  final saved = await _saveOrder(cart);
  _log('Saved: $saved');
}

// --------- Sample form data ---------
String? _customerNameFromForm() => ' Ada ';

// --------- In-memory order store ---------
final _savedOrders = <List<String>>[];

Future<Unit> _saveOrder(NonEmptyList<String> cart) {
  _savedOrders.add(cart.toList());
  return Unit.future;
}

void _log(String message) {
  // Example output is intentionally written to the console.
  // ignore: avoid_print
  print(message);
}
