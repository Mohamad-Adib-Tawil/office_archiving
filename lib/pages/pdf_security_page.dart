import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:office_archiving/l10n/app_localizations.dart';
import 'package:office_archiving/services/pdf_service.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:signature/signature.dart';
import 'package:share_plus/share_plus.dart';

class PdfSecurityPage extends StatefulWidget {
  final String? inputPdfPath;
  const PdfSecurityPage({super.key, this.inputPdfPath});

  @override
  State<PdfSecurityPage> createState() => _PdfSecurityPageState();
}

class _PdfSecurityPageState extends State<PdfSecurityPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.blue,
    exportBackgroundColor: Colors.transparent,
  );

  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _ownerPasswordController = TextEditingController();

  final bool _enablePrint = true;
  final bool _enableCopy = true;
  final bool _enableEdit = false;
  final bool _enableAnnotate = true;
  bool _isProcessing = false;

  String? _watermarkText;
  double _watermarkOpacity = 0.3;
  Color _watermarkColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _signatureController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _ownerPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).pdf_security_title),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.security),
              text: AppLocalizations.of(context).tab_security,
            ),
            Tab(
              icon: const Icon(Icons.edit),
              text: AppLocalizations.of(context).tab_signature,
            ),
            Tab(
              icon: const Icon(Icons.branding_watermark),
              text: AppLocalizations.of(context).tab_watermark,
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSecurityTab(context),
          _buildSignatureTab(context),
          _buildWatermarkTab(context),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isProcessing ? null : _processPdf,
        icon: _isProcessing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.security),
        label: Text(
          _isProcessing
              ? AppLocalizations.of(context).processing_ellipsis
              : AppLocalizations.of(context).protect_pdf_action,
        ),
        backgroundColor: _isProcessing ? Colors.grey : scheme.primary,
      ),
    );
  }

  Widget _buildSecurityTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(),
          const SizedBox(height: 16),
          Card(
            color: Colors.orange[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _text(
                        ar: 'هذه الشاشة تنشئ نسخة حماية بصرية حقيقية من المستند الأصلي عبر العلامة المائية والتوقيع. التشفير بكلمة مرور وصلاحيات قارئ الـ PDF غير مدعومين فعليًا بالحزم الحالية، لذلك تم تعطيلهما بدل تقديم سلوك مضلل.',
                        en: 'This screen creates a real visual protection copy from the original PDF using watermarking and signatures. Password encryption and viewer permissions are not actually supported by the current packages, so they are intentionally disabled instead of pretending to work.',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Opacity(
            opacity: 0.55,
            child: IgnorePointer(
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.lock, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(
                                _text(
                                  ar: 'كلمة مرور الفتح',
                                  en: 'Open password',
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: _text(
                                ar: 'كلمة المرور',
                                en: 'Password',
                              ),
                              prefixIcon: const Icon(Icons.password),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: _text(
                                ar: 'تأكيد كلمة المرور',
                                en: 'Confirm password',
                              ),
                              prefixIcon: const Icon(Icons.password),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.admin_panel_settings,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _text(
                                  ar: 'كلمة مرور المالك',
                                  en: 'Owner password',
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _text(
                              ar: 'هذا الخيار معطل إلى أن تتوفر حماية PDF مشفرة حقيقية.',
                              en: 'This option is disabled until real encrypted PDF protection is available.',
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _ownerPasswordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: _text(
                                ar: 'كلمة مرور المالك',
                                en: 'Owner password',
                              ),
                              prefixIcon: const Icon(
                                Icons.admin_panel_settings,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.settings, color: Colors.green),
                              const SizedBox(width: 8),
                              Text(
                                _text(
                                  ar: 'صلاحيات قارئ PDF',
                                  en: 'PDF viewer permissions',
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile(
                            title: Text(
                              _text(
                                ar: 'السماح بالطباعة',
                                en: 'Allow printing',
                              ),
                            ),
                            value: _enablePrint,
                            onChanged: (_) {},
                          ),
                          SwitchListTile(
                            title: Text(
                              _text(ar: 'السماح بالنسخ', en: 'Allow copying'),
                            ),
                            value: _enableCopy,
                            onChanged: (_) {},
                          ),
                          SwitchListTile(
                            title: Text(
                              _text(ar: 'السماح بالتحرير', en: 'Allow editing'),
                            ),
                            value: _enableEdit,
                            onChanged: (_) {},
                          ),
                          SwitchListTile(
                            title: Text(
                              _text(
                                ar: 'السماح بالتعليقات',
                                en: 'Allow annotations',
                              ),
                            ),
                            value: _enableAnnotate,
                            onChanged: (_) {},
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureTab(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Text(
            AppLocalizations.of(context).draw_signature_instruction,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),

        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Signature(
              controller: _signatureController,
              backgroundColor: Colors.white,
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _signatureController.clear();
                    HapticFeedback.lightImpact();
                  },
                  icon: const Icon(Icons.clear),
                  label: Text(AppLocalizations.of(context).clear_action),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _signatureController.isNotEmpty
                      ? () => _previewSignature()
                      : null,
                  icon: const Icon(Icons.preview),
                  label: Text(AppLocalizations.of(context).preview_action),
                ),
              ),
            ],
          ),
        ),

        // خيارات التوقيع
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).signature_options_title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                ListTile(
                  leading: const Icon(Icons.location_on),
                  title: Text(
                    AppLocalizations.of(context).signature_location_title,
                  ),
                  subtitle: Text(
                    AppLocalizations.of(
                      context,
                    ).signature_location_hint_last_page_br,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // TODO: فتح حوار اختيار موقع التوقيع
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.format_size),
                  title: Text(
                    AppLocalizations.of(context).signature_size_title,
                  ),
                  subtitle: Text(
                    AppLocalizations.of(context).signature_size_medium,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // TODO: فتح حوار اختيار حجم التوقيع
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWatermarkTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).watermark_settings_title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    onChanged: (value) => setState(
                      () => _watermarkText = value.isEmpty ? null : value,
                    ),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(
                        context,
                      ).watermark_text_label,
                      hintText: AppLocalizations.of(
                        context,
                      ).watermark_text_hint,
                      prefixIcon: const Icon(Icons.text_fields),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    '${AppLocalizations.of(context).transparency_label}: ${(_watermarkOpacity * 100).round()}%',
                  ),
                  Slider(
                    value: _watermarkOpacity,
                    onChanged: (v) => setState(() => _watermarkOpacity = v),
                    min: 0.1,
                    max: 0.8,
                  ),

                  const SizedBox(height: 16),

                  Text('${AppLocalizations.of(context).color_label}:'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children:
                        [
                              Colors.grey,
                              Colors.red,
                              Colors.blue,
                              Colors.green,
                              Colors.orange,
                              Colors.purple,
                            ]
                            .map(
                              (color) => GestureDetector(
                                onTap: () =>
                                    setState(() => _watermarkColor = color),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _watermarkColor == color
                                          ? Colors.black
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // معاينة العلامة المائية
          if (_watermarkText != null) ...[
            Card(
              child: Container(
                width: double.infinity,
                height: 200,
                padding: const EdgeInsets.all(16),
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context).document_content_preview,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ),
                    ),
                    Center(
                      child: Transform.rotate(
                        angle: -0.5,
                        child: Text(
                          _watermarkText!,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _watermarkColor.withValues(
                              alpha: _watermarkOpacity,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // قوالب العلامة المائية
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).watermark_templates_title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        [
                              'سري',
                              'مسودة',
                              'نسخة أولية',
                              'للمراجعة',
                              'معتمد',
                              'أرشيف الشركة',
                            ]
                            .map(
                              (template) => ActionChip(
                                label: Text(template),
                                onPressed: () {
                                  setState(() => _watermarkText = template);
                                },
                              ),
                            )
                            .toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  _text(
                    ar: 'حماية بصرية للمستندات',
                    en: 'Visual document protection',
                  ),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _text(
                ar:
                    '• إنشاء نسخة جديدة من نفس المستند الأصلي\n'
                    '• إضافة علامة مائية فعلية فوق المحتوى\n'
                    '• إضافة توقيع في الصفحة الأخيرة\n'
                    '• مشاركة النسخة الناتجة فورًا\n'
                    '• لا يتم ادعاء أي تشفير غير مطبق فعليًا',
                en:
                    '• Create a new copy from the original PDF\n'
                    '• Apply a real watermark over the content\n'
                    '• Add a signature to the last page\n'
                    '• Share the resulting copy immediately\n'
                    '• No unsupported encryption is falsely claimed',
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _previewSignature() async {
    if (_signatureController.isEmpty) return;

    final signatureBytes = await _signatureController.toPngBytes();
    if (signatureBytes == null) return;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).signature_preview_title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.memory(signatureBytes),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).signature_preview_hint,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _processPdf();
            },
            child: Text(AppLocalizations.of(context).ok_action),
          ),
        ],
      ),
    );
  }

  Future<void> _processPdf() async {
    if (widget.inputPdfPath == null) {
      _showError(
        _text(
          ar: 'لم يتم تحديد ملف PDF للمعالجة',
          en: 'No PDF file was selected for processing.',
        ),
      );
      return;
    }

    final normalizedWatermark = _watermarkText?.trim();
    final hasSignature = _signatureController.isNotEmpty;

    if ((normalizedWatermark == null || normalizedWatermark.isEmpty) &&
        !hasSignature) {
      _showError(
        _text(
          ar: 'أضف علامة مائية أو توقيعًا واحدًا على الأقل قبل إنشاء النسخة المحمية.',
          en: 'Add at least a watermark or a signature before creating the protected copy.',
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final signatureBytes = hasSignature
          ? await _signatureController.toPngBytes()
          : null;
      final sourceFile = File(widget.inputPdfPath!);
      final protectedFile = await PdfService().createProtectedCopy(
        source: sourceFile,
        watermark: normalizedWatermark,
        signatureBytes: signatureBytes,
        fileName:
            '${p.basenameWithoutExtension(sourceFile.path)}_visual_protection_${DateTime.now().millisecondsSinceEpoch}.pdf',
        watermarkColor: PdfColor.fromInt(_watermarkColor.toARGB32()),
        watermarkOpacity: _watermarkOpacity.clamp(0.1, 0.8),
      );

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            _text(
              ar: 'تم إنشاء النسخة المحمية بصريًا',
              en: 'Visual protection copy created',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              Text(
                _text(
                  ar: 'الملف: ${p.basename(protectedFile.path)}',
                  en: 'File: ${p.basename(protectedFile.path)}',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _text(
                  ar: 'الحجم: ${(protectedFile.lengthSync() / 1024).toStringAsFixed(2)} KB',
                  en: 'Size: ${(protectedFile.lengthSync() / 1024).toStringAsFixed(2)} KB',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _text(
                  ar: 'تم تطبيق التوقيع والعلامة المائية فوق محتوى المستند الأصلي، دون ادعاء تشفير غير مدعوم.',
                  en: 'The watermark and signature were applied over the original document content without claiming unsupported encryption.',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(_text(ar: 'إغلاق', en: 'Close')),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                Share.shareXFiles([XFile(protectedFile.path)]);
              },
              child: Text(_text(ar: 'مشاركة', en: 'Share')),
            ),
          ],
        ),
      );
    } catch (e) {
      _showError(
        _text(ar: 'خطأ في معالجة PDF: $e', en: 'PDF processing failed: $e'),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  String _text({required String ar, required String en}) {
    return Localizations.localeOf(context).languageCode == 'ar' ? ar : en;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
