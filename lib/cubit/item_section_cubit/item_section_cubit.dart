
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:office_archiving/models/item.dart';
import 'package:office_archiving/service/sqlite_service.dart';
part 'item_section_state.dart';

class ItemSectionCubit extends Cubit<ItemSectionState> {
  final DatabaseService _databaseService;

  ItemSectionCubit(this._databaseService) : super(ItemSectionLoading());
 
  Future<void> addItem(
      String name, String filePath, String fileType, int sectionId) async {
    try {
      final itemId = await _databaseService.insertItem(
          name, filePath, fileType, sectionId);
      final newItem = ItemSection(
        id: itemId,
        name: name,
        filePath: filePath,
        fileType: fileType,
        idSection: sectionId,
      );
      emit(ItemAdded(newItem));
      fetchItemsBySectionId(sectionId);
    } catch (e) {
      emit(ItemSectionError('Failed to add item: $e'));
    }
  }

  Future<void> fetchItemsBySectionId(int sectionId) async {
    try {
      final itemsData = await _databaseService.getItemsBySectionId(
          sectionId); 

      List<ItemSection> items = [];
      for (var itemData in itemsData) {
        final itemSection = ItemSection.fromMap(itemData);
        items.add(itemSection);
      }
      emit(ItemSectionLoaded(items));
    } catch (e) {
      emit(ItemSectionError('Failed to load items: $e'));
    }
  }


  Future<void> deleteItem(int itemId, int sectionId) async {
    try {
      await _databaseService.deleteItem(itemId);  
      emit(ItemDeleted(itemId));
      fetchItemsBySectionId(sectionId);
    } catch (e) {
      emit(ItemSectionError('Failed to delete item: $e'));
    }
  }

  Future<void> updateItemName(int itemId, String newName, int sectionId) async {
    try {
      await _databaseService.updateItemName(itemId, newName);
      emit(ItemNameUpdated(itemId, newName));
      fetchItemsBySectionId(sectionId);
    } catch (e) {
      emit(ItemSectionError('Failed to update item name: $e'));
    }
  }
   /// Search items by name
  Future<void> searchItems(String query) async {
    emit(ItemSectionLoading());
    try {
      final itemsData = await _databaseService.searchItemsByName(query);

      List<ItemSection> items = [];
      for (var itemData in itemsData) {
        final itemSection = ItemSection.fromMap(itemData);
        items.add(itemSection);
      }
      emit(ItemSectionLoaded(items));
    } catch (e) {
      emit(ItemSectionError('Failed to search items: ${e.toString()}'));
    }
  }
}
