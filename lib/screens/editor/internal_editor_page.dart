// شاشة المحرر الداخلي للصور والمستندات
// - فتح صورة
// - تحرير (قص/فلاتر) باستخدام image_editor_plus
// - توقيع رقمي
// - OCR
// - تصدير إلى PDF

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_editor_plus/image_editor_plus.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:office_archiving/services/ocr_service.dart';
import 'package:office_archiving/services/pdf_service.dart';
import 'package:office_archiving/screens/editor/signature_pad.dart';
import 'package:office_archiving/screens/editor/signature_position_page.dart';
import 'package:share_plus/share_plus.dart';
import 'package:office_archiving/pages/ai_features_page.dart';
import 'package:office_archiving/l10n/app_localizations.dart';

class InternalEditorPage extends StatefulWidget {
  final String? initialImagePath; // مسار صورة افتراضي
  const InternalEditorPage({super.key, this.initialImagePath});

  @override
  State<InternalEditorPage> createState() => _InternalEditorPageState();
}

class _InternalEditorPageState extends State<InternalEditorPage> {
  File? _image;
  final _ocr = OCRService();
  final _pdf = PdfService();
  String _extractedText = '';
  bool _busy = false;
  int _imgVersion = 0; // لتحديث عرض الصورة بعد الكتابة فوق نفس الملف

  @override
  void initState() {
    super.initState();
    if (widget.initialImagePath != null) {
      _image = File(widget.initialImagePath!);
    }
  }

  @override
  void dispose() {
    _image = null;
    super.dispose();
  }

  Future<void> _chooseSignatureOrWatermark() async {
    if (_image == null) return;
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.draw),
                title: Text(AppLocalizations.of(context).add_signature),
                onTap: () => Navigator.pop(ctx, 'signature'),
              ),
              ListTile(
                leading: const Icon(Icons.water_drop),
                title: Text(AppLocalizations.of(context).add_watermark),
                onTap: () => Navigator.pop(ctx, 'watermark'),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted || choice == null) return;
    if (choice == 'signature') {
      await _signature();
    } else if (choice == 'watermark') {
      await _promptWatermarkText();
    }
  }

  Future<void> _promptWatermarkText() async {
    final controller = TextEditingController(text: 'Office Archiving');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context).watermark_text_prompt),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: AppLocalizations.of(context).watermark_hint),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context).cancel)),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppLocalizations.of(context).ok_action)),
          ],
        );
      },
    );
    if (ok == true && controller.text.trim().isNotEmpty) {
      await _overlayTextWatermark(controller.text.trim());
    }
  }

  Future<void> _overlayTextWatermark(String text) async {
    if (_image == null) return;
    setState(() => _busy = true);
    try {
      final baseBytes = await _image!.readAsBytes();
      final base = img.decodeImage(baseBytes);
      if (base == null) throw Exception(AppLocalizations.of(context).image_read_error);

      final padding = 24;
      // اختر حجم الخط حسب عرض الصورة لضمان الوضوح
      final bmFont = base.width >= 2000
          ? img.arial48
          : (base.width >= 1000 ? img.arial24 : img.arial14);
      final approxH = bmFont == img.arial48 ? 48 : (bmFont == img.arial24 ? 24 : 14);

      // لون النص
      final white = img.ColorRgba8(255, 255, 255, 255);

      // تموضع أسفل يمين: x عند يمين الصورة (rightJustify) و y فوق الحافة السفلية بقليل
      final x = (base.width - padding).clamp(0, base.width - 1);
      final y = (base.height - approxH - padding).clamp(0, base.height - 1);

      // نص واضح أسفل يمين (بدون تكرار/ظل)
      img.drawString(base, text, font: bmFont, x: x, y: y, color: white, rightJustify: true);

      final ext = p.extension(_image!.path).toLowerCase();
      late List<int> outBytes;
      if (ext == '.png') {
        outBytes = img.encodePng(base);
      } else {
        outBytes = img.encodeJpg(base, quality: 90);
      }
      await _image!.writeAsBytes(outBytes, flush: true);
      // إزالة الصورة من الكاش لأننا كتبنا فوق نفس المسار
      await FileImage(_image!).evict();
      if (!mounted) return;
      setState(() => _imgVersion++);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).watermark_added_success)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context).watermark_add_failed_prefix}$e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openEditor() async {
    if (_image == null) return;
    final bytes = await _image!.readAsBytes();
    final edited = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ImageEditor(image: bytes)),
    );
    if (edited is List<int>) {
      await _image!.writeAsBytes(edited);
      // إزالة الصورة من الكاش لأننا كتبنا فوق نفس المسار
      await FileImage(_image!).evict();
      if (mounted) setState(() => _imgVersion++);
    }
  }

  Future<void> _signature() async {
    if (_image == null) return;
    final data = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SignaturePad()),
    );
    if (data == null || data is! Uint8List) return;
    // افتح شاشة تحديد موضع التوقيع على الصورة
    final placement = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SignaturePositionPage(
          baseImagePath: _image!.path,
          signatureBytes: data,
        ),
      ),
    );
    if (placement is SignaturePlacementResult) {
      await _overlaySignatureOnImage(
        data,
        baseX: placement.baseX,
        baseY: placement.baseY,
        targetBaseWidth: placement.targetBaseWidth,
      );
    }
  }

  Future<void> _overlaySignatureOnImage(
    Uint8List signaturePngBytes, {
    int? baseX,
    int? baseY,
    int? targetBaseWidth,
  }) async {
    if (_image == null) return;
    setState(() => _busy = true);
    try {
      // اقرأ صورة الأساس
      final baseBytes = await _image!.readAsBytes();
      final base = img.decodeImage(baseBytes);
      if (base == null) throw Exception(AppLocalizations.of(context).image_read_error);

      // اقرأ صورة التوقيع (PNG بخلفية شفافة)
      final sig = img.decodeImage(signaturePngBytes);
      if (sig == null) throw Exception('تعذر قراءة صورة التوقيع');

      // تحجيم التوقيع
      final targetW = (targetBaseWidth ?? (base.width * 0.30)).clamp(1, base.width).toInt();
      final scaledSig = img.copyResize(sig, width: targetW);

      // الموضع: إما ما اختاره المستخدم، أو أسفل يمين مع هامش 20 بكسل
      const margin = 20;
      final dx = (baseX ?? (base.width - scaledSig.width - margin)).clamp(0, base.width - 1).toInt();
      final dy = (baseY ?? (base.height - scaledSig.height - margin)).clamp(0, base.height - 1).toInt();

      // دمج مع تفعيل المزج (يحترم الشفافية)
      img.compositeImage(base, scaledSig, dstX: dx, dstY: dy);

      // ترميز حسب امتداد الملف الأصلي
      final ext = p.extension(_image!.path).toLowerCase();
      late List<int> outBytes;
      if (ext == '.png') {
        outBytes = img.encodePng(base);
      } else {
        outBytes = img.encodeJpg(base, quality: 90);
      }

      await _image!.writeAsBytes(outBytes, flush: true);
      // إزالة الصورة من الكاش لأننا كتبنا فوق نفس المسار
      await FileImage(_image!).evict();
      if (!mounted) return;
      setState(() => _imgVersion++);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).signature_added_success)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context).signature_merge_failed_prefix}$e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _doOcr() async {
    if (_image == null) return;
    setState(() => _busy = true);
    try {
      _extractedText = await _ocr.extractTextFromImage(_image!.path);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).snack_extraction_done)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportPdf() async {
    if (_image == null) return;
    setState(() => _busy = true);
    try {
      final pdf = await _pdf.createPdfFromImages([_image!.path]);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).snack_pdf_created)));
      Navigator.pop(context, _image!.path); // إرجاع المسار للاستخدام إن لزم
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share() async {
    if (_image == null) return;
    await Share.shareXFiles([XFile(_image!.path)]);
  }

  Future<void> _openAI() async {
    // إذا لم نستخرج نصاً بعد، قم بالـ OCR أولاً
    if (_extractedText.isEmpty) {
      await _doOcr();
    }
    if (!mounted) return;
    if (_extractedText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).no_text_found)),
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AIFeaturesPage(initialText: _extractedText),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final btnStyle = ElevatedButton.styleFrom(
      minimumSize: const Size(0, 40),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).editor_title),
        actions: [
          TextButton(
            onPressed: _image == null ? null : () => Navigator.pop(context, _image!.path),
            child: Text(AppLocalizations.of(context).editor_save, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _image == null
                  ? Text(AppLocalizations.of(context).no_image_to_edit)
                  : Image.file(
                      _image!,
                      key: ValueKey(_imgVersion),
                      fit: BoxFit.contain,
                    ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2)),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _busy ? null : _openEditor,
                  style: btnStyle,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune, size: 18),
                      SizedBox(height: 2),
                      Text(
                        AppLocalizations.of(context).edit_action,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _busy ? null : _chooseSignatureOrWatermark,
                  style: btnStyle,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.draw, size: 18),
                      SizedBox(height: 2),
                      Text(
                        AppLocalizations.of(context).add_signature_watermark,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _busy ? null : _doOcr,
                  style: btnStyle,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.text_fields, size: 18),
                      SizedBox(height: 2),
                      Text(
                        AppLocalizations.of(context).extract_text_ocr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _busy ? null : _exportPdf,
                  style: btnStyle,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.picture_as_pdf, size: 18),
                      SizedBox(height: 2),
                      Text(
                        AppLocalizations.of(context).export_to_pdf,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _busy ? null : _openAI,
                  style: btnStyle,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 18),
                      SizedBox(height: 2),
                      Text(
                        AppLocalizations.of(context).ai_features_title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _busy ? null : _share,
                  style: btnStyle,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.share, size: 18),
                      SizedBox(height: 2),
                      Text(
                        AppLocalizations.of(context).share_action,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
