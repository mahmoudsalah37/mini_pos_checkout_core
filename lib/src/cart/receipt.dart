import 'package:equatable/equatable.dart';
import 'models.dart';
class ReceiptHeader extends Equatable {
  const ReceiptHeader({required this.timestamp, required this.receiptNumber});
  final DateTime timestamp;
  final String receiptNumber;
  @override
  List<Object?> get props => [timestamp, receiptNumber];
}
class ReceiptLine extends Equatable {
  const ReceiptLine({
    required this.itemId,
    required this.itemName,
    required this.unitPrice,
    required this.quantity,
    required this.discountPercent,
    required this.netAmount,
  });
  factory ReceiptLine.fromCartLine(CartLine cartLine) {
    return ReceiptLine(
      itemId: cartLine.item.id,
      itemName: cartLine.item.name,
      unitPrice: cartLine.item.price,
      quantity: cartLine.quantity,
      discountPercent: cartLine.discountPercent,
      netAmount: cartLine.netAmount,
    );
  }
  final String itemId;
  final String itemName;
  final double unitPrice;
  final int quantity;
  final double discountPercent;
  final double netAmount;
  @override
  List<Object?> get props => [
    itemId,
    itemName,
    unitPrice,
    quantity,
    discountPercent,
    netAmount,
  ];
}
class ReceiptTotals extends Equatable {
  const ReceiptTotals({
    required this.subtotal,
    required this.vatAmount,
    required this.grandTotal,
  });
  factory ReceiptTotals.fromCartTotals(CartTotals cartTotals) {
    return ReceiptTotals(
      subtotal: cartTotals.subtotal,
      vatAmount: cartTotals.vatAmount,
      grandTotal: cartTotals.grandTotal,
    );
  }
  final double subtotal;
  final double vatAmount;
  final double grandTotal;
  @override
  List<Object?> get props => [subtotal, vatAmount, grandTotal];
}
class Receipt extends Equatable {
  const Receipt({
    required this.header,
    required this.lines,
    required this.totals,
  });
  final ReceiptHeader header;
  final List<ReceiptLine> lines;
  final ReceiptTotals totals;
  @override
  List<Object?> get props => [header, lines, totals];
}
Receipt buildReceipt(CartState cartState, DateTime timestamp) {
  final receiptNumber = _generateReceiptNumber(timestamp);
  final header = ReceiptHeader(
    timestamp: timestamp,
    receiptNumber: receiptNumber,
  );
  final lines = cartState.lines
      .map((cartLine) => ReceiptLine.fromCartLine(cartLine))
      .toList();
  final totals = ReceiptTotals.fromCartTotals(cartState.totals);
  return Receipt(header: header, lines: lines, totals: totals);
}
String _generateReceiptNumber(DateTime timestamp) {
  final year = timestamp.year.toString().substring(2);
  final month = timestamp.month.toString().padLeft(2, '0');
  final day = timestamp.day.toString().padLeft(2, '0');
  final hour = timestamp.hour.toString().padLeft(2, '0');
  final minute = timestamp.minute.toString().padLeft(2, '0');
  final second = timestamp.second.toString().padLeft(2, '0');
  return 'R$year$month$day$hour$minute$second';
}