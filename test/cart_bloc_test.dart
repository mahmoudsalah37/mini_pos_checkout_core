import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mini_pos_checkout_core/src/cart/cart_bloc.dart';
import 'package:mini_pos_checkout_core/src/cart/models.dart';
import 'package:mini_pos_checkout_core/src/cart/receipt.dart';
import 'package:mini_pos_checkout_core/src/catalog/item.dart';
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('CartBloc', () {
    late CartBloc cartBloc;
    late Item coffeeItem;
    late Item bagelItem;
    setUp(() {
      cartBloc = CartBloc();
      coffeeItem = const Item(id: 'p01', name: 'Coffee', price: 2.50);
      bagelItem = const Item(id: 'p02', name: 'Bagel', price: 3.20);
    });
    tearDown(() {
      cartBloc.close();
    });
    test('initial state is empty cart', () {
      expect(cartBloc.state, const CartState.empty());
      expect(cartBloc.state.lines, isEmpty);
      expect(cartBloc.state.totals.subtotal, 0.0);
      expect(cartBloc.state.totals.vatAmount, 0.0);
      expect(cartBloc.state.totals.grandTotal, 0.0);
    });
    group('AddItem', () {
      blocTest<CartBloc, CartState>(
        'adds new item to empty cart',
        build: () => cartBloc,
        act: (bloc) => bloc.add(AddItem(coffeeItem)),
        expect: () => [
          isA<CartState>()
              .having((state) => state.lines.length, 'lines length', 1)
              .having(
                (state) => state.lines.first.item,
                'first item',
                coffeeItem,
              )
              .having(
                (state) => state.lines.first.quantity,
                'first item quantity',
                1,
              ),
        ],
      );
      blocTest<CartBloc, CartState>(
        'increments quantity when adding existing item',
        build: () => cartBloc,
        act: (bloc) {
          bloc.add(AddItem(coffeeItem));
          bloc.add(AddItem(coffeeItem));
        },
        expect: () => [
          isA<CartState>().having(
            (state) => state.lines.first.quantity,
            'quantity after first add',
            1,
          ),
          isA<CartState>().having(
            (state) => state.lines.first.quantity,
            'quantity after second add',
            2,
          ),
        ],
      );
    });
    group('Business Rules - Two different items with correct totals', () {
      blocTest<CartBloc, CartState>(
        'calculates correct totals for two different items',
        build: () => cartBloc,
        act: (bloc) {
          bloc.add(AddItem(coffeeItem)); 
          bloc.add(AddItem(bagelItem)); 
        },
        verify: (bloc) {
          final state = bloc.state;
          expect(state.lines.length, 2);
          expect(state.totals.subtotal, 5.70);
          expect(state.totals.vatAmount, closeTo(0.85, 0.01));
          expect(state.totals.grandTotal, closeTo(6.55, 0.01));
        },
      );
    });
    group('ChangeQuantity and ChangeDiscount - Updates totals correctly', () {
      blocTest<CartBloc, CartState>(
        'updates totals when quantity and discount change',
        build: () => cartBloc,
        act: (bloc) {
          bloc.add(AddItem(coffeeItem));
          bloc.add(const ChangeQuantity('p01', 2));
          bloc.add(const ChangeDiscount('p01', 0.1));
        },
        verify: (bloc) {
          final state = bloc.state;
          final coffeeLine = state.lines.first;
          expect(coffeeLine.quantity, 2);
          expect(coffeeLine.discountPercent, 0.1);
          expect(coffeeLine.netAmount, 4.50);
          expect(state.totals.subtotal, 4.50);
          expect(state.totals.vatAmount, closeTo(0.67, 0.01));
          expect(state.totals.grandTotal, closeTo(5.17, 0.01));
        },
      );
    });
    group('ClearCart - Resets state', () {
      blocTest<CartBloc, CartState>(
        'clears cart and resets state to empty',
        build: () => cartBloc,
        act: (bloc) {
          bloc.add(AddItem(coffeeItem));
          bloc.add(AddItem(bagelItem));
          bloc.add(const ClearCart());
        },
        verify: (bloc) {
          final state = bloc.state;
          expect(state.lines, isEmpty);
          expect(state.totals.subtotal, 0.0);
          expect(state.totals.vatAmount, 0.0);
          expect(state.totals.grandTotal, 0.0);
        },
      );
    });
    group('RemoveItem', () {
      blocTest<CartBloc, CartState>(
        'removes item from cart',
        build: () => cartBloc,
        act: (bloc) {
          bloc.add(AddItem(coffeeItem));
          bloc.add(AddItem(bagelItem));
          bloc.add(const RemoveItem('p01'));
        },
        verify: (bloc) {
          final state = bloc.state;
          expect(state.lines.length, 1);
          expect(state.lines.first.item.id, 'p02');
        },
      );
    });
    group('Edge Cases', () {
      blocTest<CartBloc, CartState>(
        'changing quantity to 0 removes item',
        build: () => cartBloc,
        act: (bloc) {
          bloc.add(AddItem(coffeeItem));
          bloc.add(const ChangeQuantity('p01', 0));
        },
        verify: (bloc) {
          expect(bloc.state.lines, isEmpty);
        },
      );
      blocTest<CartBloc, CartState>(
        'discount is clamped between 0 and 1',
        build: () => cartBloc,
        act: (bloc) {
          bloc.add(AddItem(coffeeItem));
          bloc.add(const ChangeDiscount('p01', 1.5)); 
        },
        verify: (bloc) {
          final line = bloc.state.lines.first;
          expect(line.discountPercent, 1.0);
        },
      );
    });
  });
  group('CartLine', () {
    test('calculates net amount correctly', () {
      const item = Item(id: 'p01', name: 'Coffee', price: 2.50);
      const line = CartLine(item: item, quantity: 2, discountPercent: 0.1);
      expect(line.netAmount, 4.50);
    });
    test('copyWith creates new instance with updated values', () {
      const item = Item(id: 'p01', name: 'Coffee', price: 2.50);
      const originalLine = CartLine(item: item, quantity: 1);
      final updatedLine = originalLine.copyWith(
        quantity: 3,
        discountPercent: 0.2,
      );
      expect(updatedLine.quantity, 3);
      expect(updatedLine.discountPercent, 0.2);
      expect(updatedLine.item, item); 
    });
  });
  group('Receipt Builder', () {
    test('buildReceipt creates correct receipt from cart state', () {
      const coffeeItem = Item(id: 'p01', name: 'Coffee', price: 2.50);
      const bagelItem = Item(id: 'p02', name: 'Bagel', price: 3.20);
      final cartLines = [
        const CartLine(item: coffeeItem, quantity: 2, discountPercent: 0.1),
        const CartLine(item: bagelItem, quantity: 1),
      ];
      const cartTotals = CartTotals(
        subtotal: 7.70,
        vatAmount: 1.16,
        grandTotal: 8.86,
      );
      final cartState = CartState(lines: cartLines, totals: cartTotals);
      final timestamp = DateTime(2025, 6, 28, 14, 30, 0);
      final receipt = buildReceipt(cartState, timestamp);
      expect(receipt.header.timestamp, timestamp);
      expect(receipt.header.receiptNumber, 'R250628143000');
      expect(receipt.lines.length, 2);
      final firstLine = receipt.lines.first;
      expect(firstLine.itemName, 'Coffee');
      expect(firstLine.quantity, 2);
      expect(firstLine.discountPercent, 0.1);
      expect(receipt.totals.subtotal, 7.70);
      expect(receipt.totals.vatAmount, 1.16);
      expect(receipt.totals.grandTotal, 8.86);
    });
  });
}