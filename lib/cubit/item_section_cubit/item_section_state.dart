part of 'item_section_cubit.dart';

abstract class ItemSectionState {}

class ItemSectionLoading extends ItemSectionState {}

class ItemSectionLoaded extends ItemSectionState {
  final List<ItemSection> items;

  ItemSectionLoaded(this.items);
}

class ItemSectionError extends ItemSectionState {
  final String message;

  ItemSectionError(this.message);
}

class ItemAdded extends ItemSectionState {
  final ItemSection itemId;

  ItemAdded(this.itemId);
}
class ItemDeleted extends ItemSectionState {
  final int itemId;

  ItemDeleted(this.itemId);
}

class ItemNameUpdated extends ItemSectionState {
  final int itemId;
  final String newName;

  ItemNameUpdated(this.itemId, this.newName);
}