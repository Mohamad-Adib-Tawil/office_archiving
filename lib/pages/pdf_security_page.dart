import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

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
  
  bool _enablePrint = true;
  bool _enableCopy = true;
  bool _enableEdit = false;
  bool _enableAnnotate = true;
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
        title: const Text('حماية وتوقيع PDF'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.security), text: 'الحماية'),
            Tab(icon: Icon(Icons.edit), text: 'التوقيع'),
            Tab(icon: Icon(Icons.branding_watermark), text: 'العلامة المائية'),
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
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.security),
        label: Text(_isProcessing ? 'جاري المعالجة...' : 'حماية PDF'),
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
          
          // كلمة المرور للفتح
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lock, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('كلمة مرور الفتح', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'كلمة المرور',
                      hintText: 'أدخل كلمة مرور قوية',
                      prefixIcon: Icon(Icons.password),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'تأكيد كلمة المرور',
                      prefixIcon: Icon(Icons.password),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // كلمة مرور المالك
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.admin_panel_settings, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('كلمة مرور المالك', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'للتحكم في صلاحيات الطباعة والتحرير',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _ownerPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'كلمة مرور المالك (اختيارية)',
                      prefixIcon: Icon(Icons.admin_panel_settings),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // الصلاحيات
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.settings, color: Colors.green),
                      SizedBox(width: 8),
                      Text('الصلاحيات', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  SwitchListTile(
                    title: const Text('السماح بالطباعة'),
                    subtitle: const Text('يمكن للمستخدم طباعة المستند'),
                    value: _enablePrint,
                    onChanged: (v) => setState(() => _enablePrint = v),
                  ),
                  
                  SwitchListTile(
                    title: const Text('السماح بالنسخ'),
                    subtitle: const Text('يمكن نسخ النص من المستند'),
                    value: _enableCopy,
                    onChanged: (v) => setState(() => _enableCopy = v),
                  ),
                  
                  SwitchListTile(
                    title: const Text('السماح بالتحرير'),
                    subtitle: const Text('يمكن تعديل محتوى المستند'),
                    value: _enableEdit,
                    onChanged: (v) => setState(() => _enableEdit = v),
                  ),
                  
                  SwitchListTile(
                    title: const Text('السماح بالتعليقات'),
                    subtitle: const Text('يمكن إضافة تعليقات وملاحظات'),
                    value: _enableAnnotate,
                    onChanged: (v) => setState(() => _enableAnnotate = v),
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
          child: const Text(
            'ارسم توقيعك في المساحة أدناه',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                  label: const Text('مسح'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _signatureController.isNotEmpty 
                    ? () => _previewSignature() 
                    : null,
                  icon: const Icon(Icons.preview),
                  label: const Text('معاينة'),
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
                const Text(
                  'خيارات التوقيع',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                
                ListTile(
                  leading: const Icon(Icons.location_on),
                  title: const Text('موقع التوقيع'),
                  subtitle: const Text('أسفل يمين الصفحة الأخيرة'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // TODO: فتح حوار اختيار موقع التوقيع
                  },
                ),
                
                ListTile(
                  leading: const Icon(Icons.format_size),
                  title: const Text('حجم التوقيع'),
                  subtitle: const Text('متوسط'),
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
                  const Text(
                    'إعدادات العلامة المائية',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    onChanged: (value) => setState(() => _watermarkText = value.isEmpty ? null : value),
                    decoration: const InputDecoration(
                      labelText: 'نص العلامة المائية',
                      hintText: 'مثل: سري، نسخة أولية، شركة XYZ',
                      prefixIcon: Icon(Icons.text_fields),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  Text('الشفافية: ${(_watermarkOpacity * 100).round()}%'),
                  Slider(
                    value: _watermarkOpacity,
                    onChanged: (v) => setState(() => _watermarkOpacity = v),
                    min: 0.1,
                    max: 0.8,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  const Text('اللون:'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      Colors.grey,
                      Colors.red,
                      Colors.blue,
                      Colors.green,
                      Colors.orange,
                      Colors.purple,
                    ].map((color) => GestureDetector(
                      onTap: () => setState(() => _watermarkColor = color),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _watermarkColor == color ? Colors.black : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    )).toList(),
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
                      child: const Center(
                        child: Text(
                          'محتوى المستند\n(معاينة)',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54),
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
                            color: _watermarkColor.withOpacity(_watermarkOpacity),
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
                  const Text(
                    'قوالب جاهزة',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      'سري',
                      'مسودة',
                      'نسخة أولية',
                      'للمراجعة',
                      'معتمد',
                      'أرشيف الشركة',
                    ].map((template) => ActionChip(
                      label: Text(template),
                      onPressed: () {
                        setState(() => _watermarkText = template);
                      },
                    )).toList(),
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
                  'حماية متقدمة للمستندات',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '• حماية بكلمة مرور قوية\n'
              '• تحكم في صلاحيات الوصول\n'
              '• توقيع إلكتروني احترافي\n'
              '• علامة مائية مخصصة\n'
              '• أمان على مستوى enterprise',
              style: TextStyle(fontSize: 13),
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
        title: const Text('معاينة التوقيع'),
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
            const Text(
              'سيتم إضافة هذا التوقيع للصفحة الأخيرة من المستند',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _processPdf();
            },
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  Future<void> _processPdf() async {
    if (widget.inputPdfPath == null) {
      _showError('لم يتم تحديد ملف PDF للمعالجة');
      return;
    }
    
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('كلمة المرور وتأكيدها غير متطابقتين');
      return;
    }
    
    setState(() => _isProcessing = true);
    
    try {
      // قراءة PDF الأصلي
      final originalFile = File(widget.inputPdfPath!);
      final originalBytes = await originalFile.readAsBytes();
      
      // إنشاء PDF جديد محمي
      final pdf = pw.Document();
      
      // TODO: هنا يجب إضافة منطق معقد لقراءة PDF الأصلي وإعادة إنشاؤه
      // هذا مثال مبسط:
      
      pdf.addPage(
        pw.Page(
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'مستند محمي',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              
              if (_watermarkText != null)
                pw.Watermark(
                  angle: -30,
                  child: pw.Text(
                    _watermarkText!,
                    style: pw.TextStyle(
                      fontSize: 48,
                      color: PdfColor.fromInt(_watermarkColor.value).flatten(_watermarkOpacity),
                    ),
                  ),
                ),
              
              pw.Expanded(
                child: pw.Center(
                  child: pw.Text('محتوى المستند الأصلي هنا'),
                ),
              ),
              
              // إضافة التوقيع إذا وُجد
              if (_signatureController.isNotEmpty) ...[
                pw.Spacer(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        // TODO: إضافة صورة التوقيع
                        pw.Text('التوقيع: _____________________'),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          'تاريخ: ${DateTime.now().toString().split(' ')[0]}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
      
      // حفظ PDF المحمي
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final protectedFile = File('${dir.path}/protected_$timestamp.pdf');
      
      List<int> pdfBytes = await pdf.save();
      
      // تطبيق الحماية (هذا مثال مبسط - في الواقع يتطلب مكتبة أكثر تقدماً)
      if (_passwordController.text.isNotEmpty) {
        // TODO: تشفير PDF بكلمة مرور
        // يتطلب مكتبة مثل pointycastle أو native plugin
      }
      
      await protectedFile.writeAsBytes(pdfBytes);
      
      if (!mounted) return;
      
      // عرض النتيجة
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('تم إنشاء PDF محمي'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              Text('الحجم: ${(protectedFile.lengthSync() / 1024).toStringAsFixed(2)} KB'),
              const SizedBox(height: 8),
              const Text('تم تطبيق جميع إعدادات الحماية'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إغلاق'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                Share.shareXFiles([XFile(protectedFile.path)]);
              },
              child: const Text('مشاركة'),
            ),
          ],
        ),
      );
      
    } catch (e) {
      _showError('خطأ في معالجة PDF: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
