import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:office_archiving/cubit/section_cubit/section_cubit.dart';
import 'package:office_archiving/widgets/custom_appbar_widget_app.dart';
import 'package:office_archiving/widgets/home_floating_action_button_widget_app.dart';
import 'package:office_archiving/widgets/section_list_view.dart';

import '../service/sqlite_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DatabaseService sqlDB;
  late SectionCubit sectionCubit;

  @override
  void initState() {
    sqlDB = DatabaseService.instance;
    sectionCubit = BlocProvider.of<SectionCubit>(context);
    sectionCubit.loadSections();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    log('.............................Building HomeScreen......................................');
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: CustomAppBarWidgetApp(),
        floatingActionButton: const HomeFloatingActionButtonWidgetApp(
            // sectionCubit: sectionCubit,
            ),
        body: BlocBuilder<SectionCubit, SectionState>(
          builder: (context, state) {
            if (state is SectionInitial) {
              log('HomeScreen SectionInitial Received  state');
              sectionCubit.loadSections();
              return const Center(child: CircularProgressIndicator());
            } else if (state is SectionLoaded) {
              log('Sections loaded successfully: ${state.sections}');
              return SectionListView(
                  sections: state.sections, sectionCubit: sectionCubit);
            } else if (state is SectionError) {
              log('Failed to load sections: ${state.message}');
              return Center(
                  child: Text('Failed to load sections: ${state.message}'));
            } else {
              log('else  $state');
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }
}
