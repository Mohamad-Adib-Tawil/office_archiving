import 'package:flutter/material.dart';
import 'package:office_archiving/l10n/app_localizations.dart';
import 'package:office_archiving/pages/analytics_page.dart';
import 'package:office_archiving/pages/file_cleanup_page.dart';

class StorageCenterPage extends StatefulWidget {
  const StorageCenterPage({super.key});

  @override
  State<StorageCenterPage> createState() => _StorageCenterPageState();
}

class _StorageCenterPageState extends State<StorageCenterPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).storage_center_title),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: AppLocalizations.of(context).analytics_title),
            Tab(text: AppLocalizations.of(context).file_cleanup_title),
          ],
        ),
      ),
      body: AnimatedBuilder(
        animation: _tabController.animation!,
        builder: (context, _) {
          final index = _tabController.index;
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: KeyedSubtree(
              key: ValueKey<int>(index),
              child: index == 0
                  ? const AnalyticsPage(embedded: true)
                  : const FileCleanupPage(embedded: true),
            ),
          );
        },
      ),
    );
  }
}
