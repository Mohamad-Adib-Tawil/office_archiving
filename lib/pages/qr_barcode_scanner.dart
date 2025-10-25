import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class QRBarcodeScannerPage extends StatefulWidget {
  const QRBarcodeScannerPage({super.key});

  @override
  State<QRBarcodeScannerPage> createState() => _QRBarcodeScannerPageState();
}

class _QRBarcodeScannerPageState extends State<QRBarcodeScannerPage>
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  String? _scannedData;
  bool _isScanning = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ماسح الرموز والباركود'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.qr_code_scanner), text: 'مسح'),
            Tab(icon: Icon(Icons.qr_code), text: 'إنشاء QR'),
            Tab(icon: Icon(Icons.history), text: 'السجل'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildScannerTab(),
          _buildGeneratorTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildScannerTab() {
    return Column(
      children: [
        Container(
          height: 400,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(12),
          ),
          child: _isScanning
              ? const Center(child: CircularProgressIndicator())
              : Container(
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_scanner, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('منطقة المسح', style: TextStyle(color: Colors.grey)),
                        SizedBox(height: 8),
                        Text('ضع الكاميرا على الرمز للمسح', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
        ),
        
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _scanFromCamera,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('مسح بالكاميرا'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _scanFromGallery,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('من المعرض'),
                    ),
                  ),
                ],
              ),
              
              if (_scannedData != null) ...[
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('نتيجة المسح:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        SelectableText(_scannedData!),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            FilledButton.icon(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: _scannedData!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('تم نسخ النص')),
                                );
                              },
                              icon: const Icon(Icons.copy),
                              label: const Text('نسخ'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () => Share.share(_scannedData!),
                              icon: const Icon(Icons.share),
                              label: const Text('مشاركة'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGeneratorTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('إنشاء رمز QR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: _textController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'النص أو الرابط',
                      hintText: 'أدخل النص الذي تريد تحويله لرمز QR',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // قوالب سريعة
                  const Text('قوالب سريعة:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ActionChip(
                        label: const Text('WiFi'),
                        onPressed: () => _showWifiDialog(),
                      ),
                      ActionChip(
                        label: const Text('رقم الهاتف'),
                        onPressed: () => _textController.text = 'tel:+966',
                      ),
                      ActionChip(
                        label: const Text('بريد إلكتروني'),
                        onPressed: () => _textController.text = 'mailto:',
                      ),
                      ActionChip(
                        label: const Text('موقع جغرافي'),
                        onPressed: () => _textController.text = 'geo:24.7136,46.6753',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          if (_textController.text.isNotEmpty) ...[
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text('معاينة رمز QR', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      
                      Expanded(
                        child: Center(
                          child: QrImageView(
                            data: _textController.text,
                            version: QrVersions.auto,
                            size: 200.0,
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _saveQRCode,
                              icon: const Icon(Icons.download),
                              label: const Text('حفظ كصورة'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _shareQRCode,
                              icon: const Icon(Icons.share),
                              label: const Text('مشاركة'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5, // مثال
      itemBuilder: (context, index) {
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(
                index % 2 == 0 ? Icons.qr_code : Icons.qr_code_scanner,
                color: Colors.white,
              ),
            ),
            title: Text('رمز QR ${index + 1}'),
            subtitle: Text('تم المسح ${DateTime.now().subtract(Duration(days: index)).toString().split(' ')[0]}'),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'copy',
                  child: ListTile(
                    leading: Icon(Icons.copy),
                    title: Text('نسخ'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'share',
                  child: ListTile(
                    leading: Icon(Icons.share),
                    title: Text('مشاركة'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('حذف'),
                  ),
                ),
              ],
            ),
            onTap: () {
              // عرض تفاصيل الرمز
            },
          ),
        );
      },
    );
  }

  Future<void> _scanFromCamera() async {
    setState(() => _isScanning = true);
    
    try {
      final image = await _picker.pickImage(source: ImageSource.camera);
      if (image == null) return;
      
      // محاكاة مسح الرمز
      await Future.delayed(const Duration(seconds: 2));
      
      setState(() {
        _scannedData = 'https://example.com/scanned-qr-${DateTime.now().millisecondsSinceEpoch}';
      });
      
      HapticFeedback.mediumImpact();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في المسح: $e')),
      );
    } finally {
      setState(() => _isScanning = false);
    }
  }

  Future<void> _scanFromGallery() async {
    setState(() => _isScanning = true);
    
    try {
      final image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;
      
      // محاكاة مسح الرمز
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _scannedData = 'نص ممسوح من الصورة المحددة';
      });
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في المسح: $e')),
      );
    } finally {
      setState(() => _isScanning = false);
    }
  }

  Future<void> _saveQRCode() async {
    try {
      // محاكاة حفظ رمز QR
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ رمز QR في المعرض')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في الحفظ: $e')),
      );
    }
  }

  Future<void> _shareQRCode() async {
    try {
      await Share.share('رمز QR: ${_textController.text}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في المشاركة: $e')),
      );
    }
  }

  Future<void> _showWifiDialog() async {
    final ssidController = TextEditingController();
    final passwordController = TextEditingController();
    String securityType = 'WPA';
    
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إعدادات WiFi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ssidController,
                decoration: const InputDecoration(labelText: 'اسم الشبكة (SSID)'),
              ),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'كلمة المرور'),
                obscureText: true,
              ),
              DropdownButtonFormField<String>(
                value: securityType,
                decoration: const InputDecoration(labelText: 'نوع الأمان'),
                items: ['WPA', 'WEP', 'nopass'].map((type) => 
                  DropdownMenuItem(value: type, child: Text(type))
                ).toList(),
                onChanged: (value) => setDialogState(() => securityType = value!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('إنشاء'),
            ),
          ],
        ),
      ),
    );
    
    if (result == true) {
      setState(() {
        _textController.text = 'WIFI:T:$securityType;S:${ssidController.text};P:${passwordController.text};;';
      });
    }
  }
}
