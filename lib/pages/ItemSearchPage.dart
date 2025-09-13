import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:office_archiving/cubit/item_section_cubit/item_section_cubit.dart';
import 'package:office_archiving/widgets/grid_view_items_success.dart';

class ItemSearchPage extends StatefulWidget {
  final int sectionId;

  const ItemSearchPage({super.key, required this.sectionId});

  @override
  State<ItemSearchPage> createState() => _ItemSearchPageState();
}

class _ItemSearchPageState extends State<ItemSearchPage> {
  late ItemSectionCubit _itemSectionCubit;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _itemSectionCubit = context.read<ItemSectionCubit>();
    _itemSectionCubit.fetchItemsBySectionId(widget.sectionId);

    _searchController.addListener(() {
      _itemSectionCubit.searchItems(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Items'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<ItemSectionCubit, ItemSectionState>(
              builder: (context, state) {
                if (state is ItemSectionLoading) {
                  return Center(child: CircularProgressIndicator());
                } else if (state is ItemSectionLoaded) {
                  if (state.items.isEmpty) {
                    return Center(child: Text('No items found.'));
                  }
                  return GridViewItemsSuccess(
                    items: state.items,
                    itemSectionCubit: _itemSectionCubit,
                  );
                } else if (state is ItemSectionError) {
                  return Center(child: Text(state.message));
                } else {
                  return Container();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
