import 'package:flutter/material.dart';
import 'package:office_archiving/l10n/app_localizations.dart';
import 'package:office_archiving/widgets/settings_sheet.dart' show SettingsContent;

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).app_settings_title),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: const SettingsContent(),
          ),
        ),
      ),
    );
  }
}
