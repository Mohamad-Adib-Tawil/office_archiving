
import 'package:flutter/material.dart';
import 'package:office_archiving/constants.dart';
import 'package:office_archiving/cubit/item_section_cubit/item_section_cubit.dart';
import 'package:office_archiving/functions/show_add_item_dialog.dart';
import 'package:office_archiving/pages/section_screen.dart';


class FloatingActionButtonSection extends StatelessWidget {
  const FloatingActionButtonSection({
    super.key,
    required this.widget,
    required this.itemCubit,
  });

  final SectionScreen widget;
  final ItemSectionCubit itemCubit;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            kPrimaryColor.withOpacity(.6),
            kPrimaryColor.withOpacity(.15),
          ],
        ),
      ),
      child: FloatingActionButton(
        onPressed: () {
          showAddItemDialog(context, widget.section.id, itemCubit);
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),

          // Apply gradient
          side: BorderSide.none,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        splashColor: Colors.transparent,
        child: const Icon(Icons.note_add_rounded),
      ),
    );
  }
}
