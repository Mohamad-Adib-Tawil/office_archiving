import 'package:flutter/material.dart';
import 'package:office_archiving/l10n/app_localizations.dart';
import 'package:office_archiving/pages/professional_tools_page.dart';
import 'package:office_archiving/pages/document_management_page.dart';

class ToolsDocumentsCenterPage extends StatefulWidget {
  const ToolsDocumentsCenterPage({super.key});

  @override
  State<ToolsDocumentsCenterPage> createState() => _ToolsDocumentsCenterPageState();
}

class _ToolsDocumentsCenterPageState extends State<ToolsDocumentsCenterPage>
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
        title: Text(AppLocalizations.of(context).tools_docs_center_title),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: AppLocalizations.of(context).tab_professional_tools),
            Tab(text: AppLocalizations.of(context).doc_manage_title),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ProfessionalToolsPage(embedded: true),
          DocumentManagementPage(embedded: true),
        ],
      ),
    );
  }
}
