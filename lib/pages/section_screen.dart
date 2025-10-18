import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:office_archiving/cubit/item_section_cubit/item_section_cubit.dart';
import 'package:office_archiving/models/section.dart';
import 'package:office_archiving/pages/ItemSearchPage.dart';
import 'package:office_archiving/widgets/floating_action_button_section.dart';
import 'package:office_archiving/widgets/grid_view_items_success.dart';
import '../service/sqlite_service.dart';
import 'package:office_archiving/theme/app_icons.dart';
import 'package:office_archiving/widgets/shimmers.dart';

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
          leadingWidth: 72,
          leading: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ItemSearchPage(sectionId: widget.section.id),
                  ),
                );
              },
              icon: Icon(AppIcons.search, color: Theme.of(context).colorScheme.primary),
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          title: Text(widget.section.name),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Transform.flip(
                  flipX: true,
                  child: Icon(AppIcons.back, color: Theme.of(context).colorScheme.onSurface),
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),

        /////
        body: Column(
          children: [
            FutureBuilder<String?>(
              future: DatabaseService.instance.getSectionCoverOrLatest(widget.section.id),
              builder: (context, snap) {
                final scheme = Theme.of(context).colorScheme;
                final path = snap.data;
                final hasImage = path != null && path.isNotEmpty && File(path).existsSync();
                if (!hasImage) {
                  return const SizedBox.shrink();
                }
                return Container(
                  height: 200,
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        File(path),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                      Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: scheme.primary.withOpacity(0.22),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(AppIcons.image, color: Colors.white, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'صورة غلاف',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  itemCubit.fetchItemsBySectionId(widget.section.id);
                  await Future.delayed(const Duration(milliseconds: 200));
                },
                child: BlocBuilder<ItemSectionCubit, ItemSectionState>(
                  builder: (context, state) {
                    if (state is ItemSectionLoading) {
                      log('ItemSectionLoading');
                      return buildItemsShimmerGrid(context);
                    } else if (state is ItemSectionLoaded) {
                      log('ItemSectionLoaded');
                      return GridViewItemsSuccess(
                        items: state.items,
                        itemSectionCubit: itemCubit,
                      );
                    } else if (state is ItemSectionError) {
                      return const SingleChildScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 80),
                          child: Center(child: Text('فشل في تحميل العناصر')),
                        ),
                      );
                    } else {
                      log("else section screen state :$state");
                      return buildItemsShimmerGrid(context);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //
}
