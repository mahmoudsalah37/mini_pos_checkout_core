import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../catalog/item.dart';
import 'models.dart';
abstract class CartEvent extends Equatable {
  const CartEvent();
  @override
  List<Object?> get props => [];
}
class AddItem extends CartEvent {
  const AddItem(this.item);
  final Item item;
  @override
  List<Object?> get props => [item];
}
class RemoveItem extends CartEvent {
  const RemoveItem(this.itemId);
  final String itemId;
  @override
  List<Object?> get props => [itemId];
}
class ChangeQuantity extends CartEvent {
  const ChangeQuantity(this.itemId, this.newQuantity);
  final String itemId;
  final int newQuantity;
  @override
  List<Object?> get props => [itemId, newQuantity];
}
class ChangeDiscount extends CartEvent {
  const ChangeDiscount(this.itemId, this.discountPercent);
  final String itemId;
  final double discountPercent;
  @override
  List<Object?> get props => [itemId, discountPercent];
}
class ClearCart extends CartEvent {
  const ClearCart();
}
class CartBloc extends Bloc<CartEvent, CartState> {
  static const double vatRate = 0.15;
  CartBloc() : super(const CartState.empty()) {
    on<AddItem>(_onAddItem);
    on<RemoveItem>(_onRemoveItem);
    on<ChangeQuantity>(_onChangeQuantity);
    on<ChangeDiscount>(_onChangeDiscount);
    on<ClearCart>(_onClearCart);
  }
  void _onAddItem(AddItem event, Emitter<CartState> emit) {
    final updatedLines = List<CartLine>.from(state.lines);
    final existingIndex = _findItemIndex(event.item.id);
    if (existingIndex != -1) {
      final existingLine = updatedLines[existingIndex];
      updatedLines[existingIndex] = existingLine.copyWith(
        quantity: existingLine.quantity + 1,
      );
    } else {
      updatedLines.add(CartLine(item: event.item, quantity: 1));
    }
    final newTotals = _calculateTotals(updatedLines);
    emit(CartState(lines: updatedLines, totals: newTotals));
  }
  void _onRemoveItem(RemoveItem event, Emitter<CartState> emit) {
    final updatedLines = List<CartLine>.from(state.lines);
    updatedLines.removeWhere((line) => line.item.id == event.itemId);
    final newTotals = _calculateTotals(updatedLines);
    emit(CartState(lines: updatedLines, totals: newTotals));
  }
  void _onChangeQuantity(ChangeQuantity event, Emitter<CartState> emit) {
    if (event.newQuantity <= 0) {
      add(RemoveItem(event.itemId));
      return;
    }
    final updatedLines = List<CartLine>.from(state.lines);
    final itemIndex = _findItemIndex(event.itemId);
    if (itemIndex != -1) {
      updatedLines[itemIndex] = updatedLines[itemIndex].copyWith(
        quantity: event.newQuantity,
      );
      final newTotals = _calculateTotals(updatedLines);
      emit(CartState(lines: updatedLines, totals: newTotals));
    }
  }
  void _onChangeDiscount(ChangeDiscount event, Emitter<CartState> emit) {
    final updatedLines = List<CartLine>.from(state.lines);
    final itemIndex = _findItemIndex(event.itemId);
    if (itemIndex != -1) {
      final clampedDiscount = event.discountPercent.clamp(0.0, 1.0);
      updatedLines[itemIndex] = updatedLines[itemIndex].copyWith(
        discountPercent: clampedDiscount,
      );
      final newTotals = _calculateTotals(updatedLines);
      emit(CartState(lines: updatedLines, totals: newTotals));
    }
  }
  void _onClearCart(ClearCart event, Emitter<CartState> emit) {
    emit(const CartState.empty());
  }
  int _findItemIndex(String itemId) {
    return state.lines.indexWhere((line) => line.item.id == itemId);
  }
  CartTotals _calculateTotals(List<CartLine> lines) {
    final subtotal = lines.fold<double>(
      0.0,
      (sum, line) => sum + line.netAmount,
    );
    final vatAmount = subtotal * vatRate;
    final grandTotal = subtotal + vatAmount;
    return CartTotals(
      subtotal: _roundToTwoDecimals(subtotal),
      vatAmount: _roundToTwoDecimals(vatAmount),
      grandTotal: _roundToTwoDecimals(grandTotal),
    );
  }
  double _roundToTwoDecimals(double value) {
    return double.parse(value.toStringAsFixed(2));
  }
}