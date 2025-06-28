import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mini_pos_checkout_core/src/catalog/catalog_bloc.dart';
import 'package:mini_pos_checkout_core/src/catalog/item.dart';
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('CatalogBloc', () {
    late CatalogBloc catalogBloc;
    setUp(() {
      catalogBloc = CatalogBloc();
    });
    tearDown(() {
      catalogBloc.close();
    });
    test('initial state is CatalogInitial', () {
      expect(catalogBloc.state, const CatalogInitial());
    });
    group('LoadCatalog', () {
      const mockCatalogJson =
          '[{"id":"p01","name":"Coffee","price":2.50},{"id":"p02","name":"Bagel","price":3.20}]';
      late CatalogBloc catalogBlocWithMock;
      setUp(() {
        catalogBlocWithMock = CatalogBloc(
          assetLoader: (_) => Future.value(mockCatalogJson),
        );
      });
      tearDown(() {
        catalogBlocWithMock.close();
      });
      blocTest<CatalogBloc, CatalogState>(
        'emits [CatalogLoading, CatalogLoaded] when LoadCatalog is successful',
        build: () => catalogBlocWithMock,
        act: (bloc) => bloc.add(const LoadCatalog()),
        expect: () => [
          const CatalogLoading(),
          isA<CatalogLoaded>().having(
            (state) => state.items.length,
            'items length',
            2,
          ),
        ],
      );
blocTest<CatalogBloc, CatalogState>(
        'loaded catalog contains correct items',
        build: () => catalogBlocWithMock,
        act: (bloc) => bloc.add(const LoadCatalog()),
        verify: (bloc) {
          final state = bloc.state;
          if (state is! CatalogLoaded) {
            fail('Expected CatalogLoaded, but got $state');
          }
          expect(state.items, hasLength(2));
          final firstItem = state.items.first;
          expect(firstItem.id, 'p01');
          expect(firstItem.name, 'Coffee');
          expect(firstItem.price, 2.50);
          final secondItem = state.items.last;
          expect(secondItem.id, 'p02');
          expect(secondItem.name, 'Bagel');
          expect(secondItem.price, 3.20);
        },
      );
    });
    group('Item model', () {
      test('fromJson creates correct Item', () {
        final json = {'id': 'p01', 'name': 'Coffee', 'price': 2.50};
        final item = Item.fromJson(json);
        expect(item.id, 'p01');
        expect(item.name, 'Coffee');
        expect(item.price, 2.50);
      });
      test('toJson creates correct map', () {
        const item = Item(id: 'p01', name: 'Coffee', price: 2.50);
        final json = item.toJson();
        expect(json['id'], 'p01');
        expect(json['name'], 'Coffee');
        expect(json['price'], 2.50);
      });
      test('equality works correctly', () {
        const item1 = Item(id: 'p01', name: 'Coffee', price: 2.50);
        const item2 = Item(id: 'p01', name: 'Coffee', price: 2.50);
        const item3 = Item(id: 'p02', name: 'Tea', price: 2.00);
        expect(item1, equals(item2));
        expect(item1, isNot(equals(item3)));
      });
    });
  });
}