 import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:office_archiving/cubit/section_cubit/section_cubit.dart';
import 'package:office_archiving/models/section.dart';

void handleDeleteSection(BuildContext context, Section section) {
  context.read<SectionCubit>().deleteSection(section.id);
}
