import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:office_archiving/pages/document_scanner_page.dart';
import 'package:office_archiving/pages/qr_barcode_scanner.dart';
import 'package:office_archiving/pages/business_card_scanner.dart';
import 'package:office_archiving/pages/pdf_security_page.dart';
import 'package:office_archiving/pages/pdf_editor_page.dart';

class ProfessionalToolsPage extends StatelessWidget {
  const ProfessionalToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('أدوات احترافية'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(context),
            const SizedBox(height: 24),
            
            const Text(
              'أدوات المسح والالتقاط',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            _buildToolGrid(context, [
              ToolItem(
                title: 'ماسح المستندات',
                subtitle: 'مسح متقدم مع فلاتر وتحسين',
                icon: Icons.document_scanner,
                color: Colors.blue,
                page: const DocumentScannerPage(),
              ),
              ToolItem(
                title: 'ماسح بطاقات العمل',
                subtitle: 'استخراج معلومات الاتصال تلقائياً',
                icon: Icons.credit_card,
                color: Colors.green,
                page: const BusinessCardScannerPage(),
              ),
              ToolItem(
                title: 'ماسح الرموز والباركود',
                subtitle: 'مسح وإنشاء رموز QR والباركود',
                icon: Icons.qr_code_scanner,
                color: Colors.orange,
                page: const QRBarcodeScannerPage(),
              ),
            ]),
            
            const SizedBox(height: 24),
            
            const Text(
              'أدوات PDF المتقدمة',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            _buildToolGrid(context, [
              ToolItem(
                title: 'حماية PDF',
                subtitle: 'كلمات مرور وتوقيع إلكتروني',
                icon: Icons.security,
                color: Colors.red,
                page: const PdfSecurityPage(),
              ),
              ToolItem(
                title: 'محرر PDF',
                subtitle: 'إضافة تعليقات وتمييز النصوص',
                icon: Icons.edit_document,
                color: Colors.purple,
                page: const PdfEditorPage(pdfPath: ''),
              ),
              ToolItem(
                title: 'دمج وتقسيم PDF',
                subtitle: 'أدوات متقدمة لإدارة PDF',
                icon: Icons.merge,
                color: Colors.teal,
                onTap: () => _showComingSoon(context),
              ),
            ]),
            
            const SizedBox(height: 24),
            
            const Text(
              'أدوات إضافية',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            _buildToolGrid(context, [
              ToolItem(
                title: 'مولد التقارير',
                subtitle: 'إنشاء تقارير احترافية',
                icon: Icons.assessment,
                color: Colors.indigo,
                onTap: () => _showComingSoon(context),
              ),
              ToolItem(
                title: 'النسخ الاحتياطي السحابي',
                subtitle: 'مزامنة مع الخدمات السحابية',
                icon: Icons.cloud_sync,
                color: Colors.lightBlue,
                onTap: () => _showComingSoon(context),
              ),
              ToolItem(
                title: 'مشاركة متقدمة',
                subtitle: 'مشاركة مع تحكم في الصلاحيات',
                icon: Icons.share_outlined,
                color: Colors.amber,
                onTap: () => _showComingSoon(context),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 8,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [scheme.primary, scheme.primary.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'أدوات احترافية لإدارة المستندات',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'مجموعة شاملة من الأدوات المتقدمة لمسح وتحرير وحماية وإدارة المستندات بطريقة احترافية',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolGrid(BuildContext context, List<ToolItem> tools) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: tools.length,
      itemBuilder: (context, index) {
        final tool = tools[index];
        return _buildToolCard(context, tool);
      },
    );
  }

  Widget _buildToolCard(BuildContext context, ToolItem tool) {
    return Card(
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          HapticFeedback.lightImpact();
          if (tool.page != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => tool.page!),
            );
          } else if (tool.onTap != null) {
            tool.onTap!();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tool.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  tool.icon,
                  color: tool.color,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                tool.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  tool.subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showComingSoon(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.schedule, color: Colors.orange),
            SizedBox(width: 8),
            Text('قريباً'),
          ],
        ),
        content: const Text('هذه الميزة قيد التطوير وستكون متاحة في التحديث القادم'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }
}

class ToolItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget? page;
  final VoidCallback? onTap;

  ToolItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.page,
    this.onTap,
  });
}
