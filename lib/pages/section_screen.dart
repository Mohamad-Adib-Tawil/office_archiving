import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:office_archiving/cubit/item_section_cubit/item_section_cubit.dart';
import 'package:office_archiving/models/section.dart';
import 'package:office_archiving/pages/ItemSearchPage.dart';
import 'package:office_archiving/widgets/floating_action_button_section.dart';
import 'package:office_archiving/widgets/grid_view_items_success.dart';
import '../service/sqlite_service.dart';

class SectionScreen extends StatefulWidget {
  final Section section;
  const SectionScreen({super.key, required this.section});

  @override
  State<SectionScreen> createState() => _SectionScreenState();
}

class _SectionScreenState extends State<SectionScreen> {
  late DatabaseService sqlDB;
  late ItemSectionCubit itemCubit;

  @override
  void initState() {
    sqlDB = DatabaseService.instance;
    itemCubit = BlocProvider.of<ItemSectionCubit>(context);
    log('SectionScreen widget.section.id ${widget.section.id}');
    itemCubit.fetchItemsBySectionId(widget.section.id);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    log('|||||||||||||||||||||||||||||||||||||||||| SectionScreen widget.section.id ${widget.section.id} |||||||||||||||||||||||||||||||||||||||||| ');

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        ///
        ///
        floatingActionButton:
            FloatingActionButtonSection(widget: widget, itemCubit: itemCubit),

        ///
        ///
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ItemSearchPage(
                        sectionId: widget.section.id,
                      ),
                    ));
              },
              icon: Icon(Icons.search)),
          title: Text(widget.section.name),
          centerTitle: true,
          // automaticallyImplyLeading: false,
        ),

        /////
        body: BlocBuilder<ItemSectionCubit, ItemSectionState>(
          builder: (context, state) {
            if (state is ItemSectionLoading) {
              log('ItemSectionLoading');
              return const Center(child: CircularProgressIndicator());
            } else if (state is ItemSectionLoaded) {
              log('ItemSectionLoaded');

              return GridViewItemsSuccess(
                items: state.items,
                itemSectionCubit: itemCubit,
              );
            } else if (state is ItemSectionError) {
              return const Center(child: Text('Failed to load items'));
            } else {
              log("else section screen state :$state");
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }

//
}
