import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'item.dart';
typedef AssetLoader = Future<String> Function(String assetPath);
abstract class CatalogEvent extends Equatable {
  const CatalogEvent();
  @override
  List<Object?> get props => [];
}
class LoadCatalog extends CatalogEvent {
  const LoadCatalog();
}
abstract class CatalogState extends Equatable {
  const CatalogState();
  @override
  List<Object?> get props => [];
}
class CatalogInitial extends CatalogState {
  const CatalogInitial();
}
class CatalogLoading extends CatalogState {
  const CatalogLoading();
}
class CatalogLoaded extends CatalogState {
  const CatalogLoaded(this.items);
  final List<Item> items;
  @override
  List<Object?> get props => [items];
}
class CatalogError extends CatalogState {
  const CatalogError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
class CatalogBloc extends Bloc<CatalogEvent, CatalogState> {
  CatalogBloc({AssetLoader? assetLoader})
      : _loadAsset = assetLoader ?? _defaultAssetLoader,
        super(const CatalogInitial()) {
    on<LoadCatalog>(_onLoadCatalog);
  }
  final AssetLoader _loadAsset;
  static Future<String> _defaultAssetLoader(String assetPath) {
    return rootBundle.loadString(assetPath);
  }
  Future<void> _onLoadCatalog(
    LoadCatalog event,
    Emitter<CatalogState> emit,
  ) async {
    emit(const CatalogLoading());
    try {
      final catalogData = await _loadCatalogFromAssets();
      final items = _parseCatalogData(catalogData);
      emit(CatalogLoaded(items));
    } catch (error) {
      emit(CatalogError('Failed to load catalog: $error'));
    }
  }
  Future<String> _loadCatalogFromAssets() async {
    return await _loadAsset('assets/catalog.json');
  }
  List<Item> _parseCatalogData(String catalogData) {
    final List<dynamic> jsonList = json.decode(catalogData) as List<dynamic>;
    return jsonList
        .map((json) => Item.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}