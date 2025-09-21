import 'package:flutter/material.dart';
import 'package:office_archiving/cubit/item_section_cubit/item_section_cubit.dart';
import 'package:office_archiving/cubit/section_cubit/section_cubit.dart';
import 'package:office_archiving/pages/splash.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:office_archiving/l10n/app_localizations.dart';
import 'package:office_archiving/cubit/locale_cubit/locale_cubit.dart';
import 'package:office_archiving/cubit/theme_cubit/theme_cubit.dart';

import 'service/sqlite_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DatabaseService.initDatabase();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => SectionCubit(DatabaseService.instance)),
        BlocProvider(create: (context) => ItemSectionCubit(DatabaseService.instance)),
        BlocProvider(create: (context) => LocaleCubit()),
        BlocProvider(create: (context) => ThemeCubit()),
      ],
      child: Builder(builder: (context) {
        final locale = context.select((LocaleCubit c) => c.state);
        final theme = context.select((ThemeCubit c) => c.themeData);
        return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        // Localization setup
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('ar'),
        ],
        locale: locale,
        onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
        home: const SplashView(),
      );
      }),
    );
  }
}

