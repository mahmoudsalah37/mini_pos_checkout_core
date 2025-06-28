import 'package:equatable/equatable.dart';
import '../catalog/item.dart';
class CartLine extends Equatable {
  const CartLine({
    required this.item,
    required this.quantity,
    this.discountPercent = 0.0,
  });
  final Item item;
  final int quantity;
  final double discountPercent;
  double get netAmount {
    final grossAmount = item.price * quantity;
    final discountAmount = grossAmount * discountPercent;
    final result = grossAmount - discountAmount;
    return _roundToTwoDecimals(result);
  }
  CartLine copyWith({Item? item, int? quantity, double? discountPercent}) {
    return CartLine(
      item: item ?? this.item,
      quantity: quantity ?? this.quantity,
      discountPercent: discountPercent ?? this.discountPercent,
    );
  }
  double _roundToTwoDecimals(double value) {
    return double.parse(value.toStringAsFixed(2));
  }
  @override
  List<Object?> get props => [item, quantity, discountPercent];
}
class CartTotals extends Equatable {
  const CartTotals({
    required this.subtotal,
    required this.vatAmount,
    required this.grandTotal,
  });
  const CartTotals.zero() : subtotal = 0.0, vatAmount = 0.0, grandTotal = 0.0;
  final double subtotal;
  final double vatAmount;
  final double grandTotal;
  factory CartTotals.fromLines(List<CartLine> lines, {double vatRate = 0.15}) {
    final subtotal = lines.fold<double>(
      0.0,
      (sum, line) => sum + line.netAmount,
    );
    final vatAmount = double.parse((subtotal * vatRate).toStringAsFixed(2));
    final grandTotal = double.parse((subtotal + vatAmount).toStringAsFixed(2));
    return CartTotals(
      subtotal: double.parse(subtotal.toStringAsFixed(2)),
      vatAmount: vatAmount,
      grandTotal: grandTotal,
    );
  }
  @override
  List<Object?> get props => [subtotal, vatAmount, grandTotal];
}
class CartState extends Equatable {
  const CartState({required this.lines, required this.totals});
  const CartState.empty() : lines = const [], totals = const CartTotals.zero();
  final List<CartLine> lines;
  final CartTotals totals;
  CartState copyWith({List<CartLine>? lines, CartTotals? totals}) {
    return CartState(lines: lines ?? this.lines, totals: totals ?? this.totals);
  }
  @override
  List<Object?> get props => [lines, totals];
}