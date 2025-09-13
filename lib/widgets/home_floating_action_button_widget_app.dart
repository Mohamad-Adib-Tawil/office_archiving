import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:office_archiving/constants.dart';
import 'package:office_archiving/cubit/section_cubit/section_cubit.dart';
import 'package:office_archiving/functions/show_addSection_ialog.dart';

class HomeFloatingActionButtonWidgetApp extends StatefulWidget {
  const HomeFloatingActionButtonWidgetApp({
    super.key,
  });

  @override
  State<HomeFloatingActionButtonWidgetApp> createState() =>
      _HomeFloatingActionButtonWidgetAppState();
}

class _HomeFloatingActionButtonWidgetAppState
    extends State<HomeFloatingActionButtonWidgetApp> {
  late SectionCubit sectionCubit;
  @override
  void initState() {
    super.initState();
    sectionCubit = context.read<SectionCubit>();
  }

  final TextEditingController sectionNameController = TextEditingController();

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
        onPressed: () async {
          showAddSectionDialog(context, sectionNameController, sectionCubit);
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        splashColor: Colors.transparent,
        child: const Icon(Icons.my_library_add_rounded, color: kWhiteColor),
      ),
    );
  }
}
