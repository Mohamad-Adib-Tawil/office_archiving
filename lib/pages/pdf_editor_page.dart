import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class PdfEditorPage extends StatefulWidget {
  final String pdfPath;
  const PdfEditorPage({super.key, required this.pdfPath});

  @override
  State<PdfEditorPage> createState() => _PdfEditorPageState();
}

class _PdfEditorPageState extends State<PdfEditorPage> {
  String _selectedTool = 'select';
  final List<Annotation> _annotations = [];
  bool _isProcessing = false;
  
  final _textController = TextEditingController();
  Color _selectedColor = Colors.red;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('محرر PDF'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _savePdf,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _sharePdf,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildToolbar(),
          Expanded(
            child: _buildPdfViewer(),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildToolButton('select', Icons.touch_app, 'تحديد'),
          _buildToolButton('highlight', Icons.highlight, 'تمييز'),
          _buildToolButton('text', Icons.text_fields, 'نص'),
          _buildToolButton('draw', Icons.draw, 'رسم'),
          _buildToolButton('stamp', Icons.bookmark, 'ختم'),
          const Spacer(),
          PopupMenuButton<Color>(
            icon: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _selectedColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey),
              ),
            ),
            onSelected: (color) => setState(() => _selectedColor = color),
            itemBuilder: (context) => [
              Colors.red, Colors.blue, Colors.green, Colors.yellow,
              Colors.orange, Colors.purple, Colors.black,
            ].map((color) => PopupMenuItem(
              value: color,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(String tool, IconData icon, String tooltip) {
    final isSelected = _selectedTool == tool;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isSelected ? Theme.of(context).colorScheme.primary : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, color: isSelected ? Colors.white : null),
        tooltip: tooltip,
        onPressed: () => setState(() => _selectedTool = tool),
      ),
    );
  }

  Widget _buildPdfViewer() {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 3.0,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey[200],
        child: Center(
          child: Container(
            width: 400,
            height: 600,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // محتوى PDF (محاكاة)
                const Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'محتوى PDF هنا...\n\nيمكنك إضافة التعليقات والتمييز والنصوص.',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                // طبقة التعليقات
                ..._annotations.map((annotation) => _buildAnnotationWidget(annotation)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnnotationWidget(Annotation annotation) {
    return Positioned(
      left: annotation.x,
      top: annotation.y,
      child: GestureDetector(
        onTap: () => _editAnnotation(annotation),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: annotation.color.withValues(alpha: 0.3),
            border: Border.all(color: annotation.color),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            annotation.text,
            style: TextStyle(color: annotation.color),
          ),
        ),
      ),
    );
  }

  void _editAnnotation(Annotation annotation) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تحرير التعليق'),
        content: TextField(
          controller: TextEditingController(text: annotation.text),
          decoration: const InputDecoration(labelText: 'النص'),
          onChanged: (value) => annotation.text = value,
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _annotations.remove(annotation));
              Navigator.pop(ctx);
            },
            child: const Text('حذف'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _savePdf() async {
    setState(() => _isProcessing = true);
    
    try {
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.Page(
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('مستند معدّل', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text('تم إضافة ${_annotations.length} تعليق'),
              // إضافة التعليقات كنص
              ..._annotations.map((a) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Text('• ${a.text}'),
              )),
            ],
          ),
        ),
      );
      
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/edited_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ PDF المعدّل')),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في الحفظ: $e')),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _sharePdf() async {
    await Share.shareXFiles([XFile(widget.pdfPath)]);
  }
}

class Annotation {
  double x, y;
  String text;
  Color color;
  String type;
  
  Annotation({
    required this.x,
    required this.y,
    required this.text,
    required this.color,
    required this.type,
  });
}
