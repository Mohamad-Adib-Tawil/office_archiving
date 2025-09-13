
 import 'package:flutter/material.dart';
import 'package:office_archiving/cubit/section_cubit/section_cubit.dart';
import 'package:office_archiving/models/section.dart';
import 'package:office_archiving/widgets/rename_section_dailog.dart';

void handleRenameSection(
    BuildContext context, SectionCubit sectionCubit, Section section) async {
  String? newName = await showDialog<String>(
    context: context,
    builder: (context) => const RenameSectionDialog(),
  );

  if (newName != null) {
    sectionCubit.updateSectionName(section.id, newName);
  }
}
