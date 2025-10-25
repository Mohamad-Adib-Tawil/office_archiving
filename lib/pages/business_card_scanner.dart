import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:office_archiving/services/ocr_service.dart';
import 'package:share_plus/share_plus.dart';

class BusinessCardScannerPage extends StatefulWidget {
  const BusinessCardScannerPage({super.key});

  @override
  State<BusinessCardScannerPage> createState() => _BusinessCardScannerPageState();
}

class _BusinessCardScannerPageState extends State<BusinessCardScannerPage> {
  final ImagePicker _picker = ImagePicker();
  final OCRService _ocrService = OCRService();
  
  String? _scannedImagePath;
  BusinessCardData? _extractedData;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ماسح بطاقات العمل'),
        actions: [
          if (_extractedData != null)
            IconButton(
              icon: const Icon(Icons.save_alt),
              onPressed: _saveContact,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 16),
            _buildScanCard(),
            if (_scannedImagePath != null) ...[
              const SizedBox(height: 16),
              _buildImagePreview(),
            ],
            if (_extractedData != null) ...[
              const SizedBox(height: 16),
              _buildExtractedDataCard(),
            ],
          ],
        ),
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
                Icon(Icons.credit_card, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'ماسح بطاقات العمل الذكي',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '• استخراج تلقائي للأسماء وأرقام الهواتف\n'
              '• التعرف على عناوين البريد الإلكتروني\n'
              '• حفظ جهات الاتصال مباشرة\n'
              '• مشاركة المعلومات بسهولة',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.credit_card, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('ضع بطاقة العمل هنا', style: TextStyle(color: Colors.grey)),
                    SizedBox(height: 4),
                    Text('للحصول على أفضل النتائج', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            if (_isProcessing) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('جاري معالجة بطاقة العمل...'),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _scanCard(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('التقط صورة'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _scanCard(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('من المعرض'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'الصورة الممسوحة',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            child: Image.file(
              File(_scannedImagePath!),
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtractedDataCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'المعلومات المستخرجة',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _editData,
                ),
              ],
            ),
            
            const Divider(),
            
            _buildDataField('الاسم', _extractedData!.name, Icons.person),
            _buildDataField('المنصب', _extractedData!.title, Icons.work),
            _buildDataField('الشركة', _extractedData!.company, Icons.business),
            _buildDataField('الهاتف', _extractedData!.phone, Icons.phone),
            _buildDataField('البريد الإلكتروني', _extractedData!.email, Icons.email),
            _buildDataField('الموقع الإلكتروني', _extractedData!.website, Icons.web),
            _buildDataField('العنوان', _extractedData!.address, Icons.location_on),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _saveContact,
                    icon: const Icon(Icons.person_add),
                    label: const Text('حفظ جهة اتصال'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _shareData,
                    icon: const Icon(Icons.share),
                    label: const Text('مشاركة'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataField(String label, String? value, IconData icon) {
    if (value == null || value.isEmpty) return const SizedBox();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SelectableText(
                  value,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('تم نسخ $label')),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _scanCard(ImageSource source) async {
    setState(() => _isProcessing = true);
    
    try {
      final image = await _picker.pickImage(source: source);
      if (image == null) return;
      
      setState(() => _scannedImagePath = image.path);
      
      // استخراج النص باستخدام OCR
      final extractedText = await _ocrService.recognizeTextAdvanced(
        image.path,
        lang: 'auto',
      );
      
      // تحليل النص لاستخراج البيانات
      final businessCardData = _parseBusinessCardText(extractedText);
      
      setState(() => _extractedData = businessCardData);
      
      HapticFeedback.mediumImpact();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم استخراج البيانات بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في معالجة البطاقة: $e')),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  BusinessCardData _parseBusinessCardText(String text) {
    // تحليل ذكي للنص المستخرج
    final lines = text.split('\n').where((line) => line.trim().isNotEmpty).toList();
    
    String? name, title, company, phone, email, website, address;
    
    // البحث عن أنماط مختلفة
    for (String line in lines) {
      line = line.trim();
      
      // البحث عن البريد الإلكتروني
      if (RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b').hasMatch(line)) {
        email ??= RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b').firstMatch(line)?.group(0);
      }
      
      // البحث عن رقم الهاتف
      if (RegExp(r'[\+]?[0-9][\d\s\-\(\)]{7,}').hasMatch(line)) {
        phone ??= RegExp(r'[\+]?[0-9][\d\s\-\(\)]{7,}').firstMatch(line)?.group(0);
      }
      
      // البحث عن الموقع الإلكتروني
      if (RegExp(r'www\.|http|\.com|\.org|\.net').hasMatch(line.toLowerCase())) {
        website ??= line;
      }
      
      // الاسم (عادة في أول سطر)
      if (name == null && line.length < 50 && !line.contains('@') && !RegExp(r'\d').hasMatch(line)) {
        name = line;
      }
      
      // المنصب والشركة (تخمين ذكي)
      if (title == null && (line.contains('Manager') || line.contains('Director') || line.contains('مدير') || line.contains('رئيس'))) {
        title = line;
      }
      
      // الشركة (عادة تحتوي على كلمات مثل Company, Corp, Ltd)
      if (company == null && (line.contains('Company') || line.contains('Corp') || line.contains('Ltd') || line.contains('شركة'))) {
        company = line;
      }
    }
    
    // إذا لم نجد الاسم، نأخذ السطر الأول
    name ??= lines.isNotEmpty ? lines.first : 'غير محدد';
    
    // بناء العنوان من الأسطر المتبقية
    address = lines.where((line) => 
      !line.contains(name ?? '') &&
      !line.contains(email ?? '') &&
      !line.contains(phone ?? '') &&
      !line.contains(website ?? '')
    ).join(', ');
    
    return BusinessCardData(
      name: name,
      title: title,
      company: company,
      phone: phone,
      email: email,
      website: website,
      address: address.isNotEmpty ? address : null,
    );
  }

  Future<void> _editData() async {
    final result = await Navigator.push<BusinessCardData>(
      context,
      MaterialPageRoute(
        builder: (context) => BusinessCardEditorPage(data: _extractedData!),
      ),
    );
    
    if (result != null) {
      setState(() => _extractedData = result);
    }
  }

  Future<void> _saveContact() async {
    if (_extractedData == null) return;
    
    // محاكاة حفظ جهة الاتصال
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حفظ جهة الاتصال'),
        content: const Text('سيتم حفظ جهة الاتصال في دفتر الهاتف'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم حفظ جهة الاتصال')),
              );
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _shareData() async {
    if (_extractedData == null) return;
    
    final text = _extractedData!.toVCard();
    await Share.share(text, subject: 'بطاقة عمل - ${_extractedData!.name}');
  }
}

class BusinessCardData {
  String? name;
  String? title;
  String? company;
  String? phone;
  String? email;
  String? website;
  String? address;
  
  BusinessCardData({
    this.name,
    this.title,
    this.company,
    this.phone,
    this.email,
    this.website,
    this.address,
  });
  
  String toVCard() {
    return '''BEGIN:VCARD
VERSION:3.0
FN:${name ?? ''}
ORG:${company ?? ''}
TITLE:${title ?? ''}
TEL:${phone ?? ''}
EMAIL:${email ?? ''}
URL:${website ?? ''}
ADR:${address ?? ''}
END:VCARD''';
  }
}

class BusinessCardEditorPage extends StatefulWidget {
  final BusinessCardData data;
  
  const BusinessCardEditorPage({super.key, required this.data});
  
  @override
  State<BusinessCardEditorPage> createState() => _BusinessCardEditorPageState();
}

class _BusinessCardEditorPageState extends State<BusinessCardEditorPage> {
  late TextEditingController _nameController;
  late TextEditingController _titleController;
  late TextEditingController _companyController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _websiteController;
  late TextEditingController _addressController;
  
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.data.name);
    _titleController = TextEditingController(text: widget.data.title);
    _companyController = TextEditingController(text: widget.data.company);
    _phoneController = TextEditingController(text: widget.data.phone);
    _emailController = TextEditingController(text: widget.data.email);
    _websiteController = TextEditingController(text: widget.data.website);
    _addressController = TextEditingController(text: widget.data.address);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تحرير بيانات البطاقة'),
        actions: [
          FilledButton(
            onPressed: _saveData,
            child: const Text('حفظ'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTextField('الاسم', _nameController, Icons.person),
            _buildTextField('المنصب', _titleController, Icons.work),
            _buildTextField('الشركة', _companyController, Icons.business),
            _buildTextField('الهاتف', _phoneController, Icons.phone),
            _buildTextField('البريد الإلكتروني', _emailController, Icons.email),
            _buildTextField('الموقع الإلكتروني', _websiteController, Icons.web),
            _buildTextField('العنوان', _addressController, Icons.location_on, maxLines: 3),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
  
  void _saveData() {
    final updatedData = BusinessCardData(
      name: _nameController.text,
      title: _titleController.text,
      company: _companyController.text,
      phone: _phoneController.text,
      email: _emailController.text,
      website: _websiteController.text,
      address: _addressController.text,
    );
    
    Navigator.pop(context, updatedData);
  }
}
