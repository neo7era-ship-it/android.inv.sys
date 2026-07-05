import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../domain/medical_item.dart';
import '../data/medical_item_repository.dart';
import '../../../core/utils/fuzzy_matcher.dart';

abstract class ItemsEvent extends Equatable { const ItemsEvent(); @override List<Object?> get props => []; }
class LoadItems extends ItemsEvent {}
class SearchItems extends ItemsEvent { final String query; const SearchItems(this.query); @override List<Object?> get props => [query]; }
class ImportItems extends ItemsEvent { final List<String> itemNames; final bool replaceExisting; const ImportItems(this.itemNames, {this.replaceExisting = true}); @override List<Object?> get props => [itemNames, replaceExisting]; }
class DeleteAllItems extends ItemsEvent {}

abstract class ItemsState extends Equatable { const ItemsState(); @override List<Object?> get props => []; }
class ItemsInitial extends ItemsState {}
class ItemsLoading extends ItemsState {}
class ItemsLoaded extends ItemsState { final List<MedicalItem> items; final List<MedicalItem> filteredItems; final String searchQuery; final int totalCount; const ItemsLoaded({required this.items, required this.filteredItems, this.searchQuery = '', this.totalCount = 0}); @override List<Object?> get props => [items, filteredItems, searchQuery, totalCount]; ItemsLoaded copyWith({List<MedicalItem>? items, List<MedicalItem>? filteredItems, String? searchQuery, int? totalCount}) => ItemsLoaded(items: items ?? this.items, filteredItems: filteredItems ?? this.filteredItems, searchQuery: searchQuery ?? this.searchQuery, totalCount: totalCount ?? this.totalCount); }
class ItemsImportSuccess extends ItemsState { final int importedCount; final int totalCount; const ItemsImportSuccess(this.importedCount, this.totalCount); @override List<Object?> get props => [importedCount, totalCount]; }
class ItemsError extends ItemsState { final String message; const ItemsError(this.message); @override List<Object?> get props => [message]; }

class ItemsBloc extends Bloc<ItemsEvent, ItemsState> {
  final MedicalItemRepository _repository;
  ItemsBloc({required MedicalItemRepository repository}) : _repository = repository, super(ItemsInitial()) {
    on<LoadItems>(_onLoadItems);
    on<SearchItems>(_onSearchItems);
    on<ImportItems>(_onImportItems);
    on<DeleteAllItems>(_onDeleteAllItems);
  }

  Future<void> _onLoadItems(LoadItems event, Emitter<ItemsState> emit) async {
    emit(ItemsLoading());
    try {
      final items = await _repository.getAllItems();
      final count = await _repository.getItemCount();
      emit(ItemsLoaded(items: items, filteredItems: items, totalCount: count));
    } catch (e) { emit(ItemsError(e.toString())); }
  }

  Future<void> _onSearchItems(SearchItems event, Emitter<ItemsState> emit) async {
    if (state is ItemsLoaded) {
      final cs = state as ItemsLoaded;
      if (event.query.isEmpty) { emit(cs.copyWith(filteredItems: cs.items, searchQuery: '')); return; }
      final sqlResults = await _repository.searchItems(event.query);
      final allNames = cs.items.map((i) => i.itemName).toList();
      final fuzzyResults = FuzzyMatcher.fuzzySearch(allNames, event.query);
      final sqlIds = sqlResults.map((i) => i.id).toSet();
      final merged = List<MedicalItem>.from(sqlResults);
      for (final f in fuzzyResults) { final item = cs.items[f.index]; if (!sqlIds.contains(item.id)) merged.add(item); }
      emit(cs.copyWith(filteredItems: merged, searchQuery: event.query));
    }
  }

  Future<void> _onImportItems(ImportItems event, Emitter<ItemsState> emit) async {
    emit(ItemsLoading());
    try {
      final now = DateTime.now().toIso8601String();
      final items = event.itemNames.map((n) => MedicalItem(itemName: n.trim(), createdAt: now, updatedAt: now)).toList();
      int importedCount;
      if (event.replaceExisting) { importedCount = await _repository.replaceAllItems(items); }
      else { importedCount = await _repository.insertItemsBatch(items); }
      final allItems = await _repository.getAllItems();
      final count = await _repository.getItemCount();
      emit(ItemsImportSuccess(importedCount, count));
      emit(ItemsLoaded(items: allItems, filteredItems: allItems, totalCount: count));
    } catch (e) { emit(ItemsError(e.toString())); }
  }

  Future<void> _onDeleteAllItems(DeleteAllItems event, Emitter<ItemsState> emit) async {
    try { await _repository.deleteAllItems(); emit(const ItemsLoaded(items: [], filteredItems: [], totalCount: 0)); }
    catch (e) { emit(ItemsError(e.toString())); }
  }
}
