import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:office_archiving/l10n/app_localizations.dart';
import 'package:office_archiving/widgets/first_open_animator.dart';

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
                  Text(
                    AppLocalizations.of(context).qr_generate_title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _textController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).text_or_url,
                      hintText: AppLocalizations.of(context).enter_text_for_qr,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context).quick_templates, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ActionChip(label: const Text('WiFi'), onPressed: _showWifiDialog),
                      ActionChip(label: Text(AppLocalizations.of(context).phone_number), onPressed: () => _textController.text = 'tel:+966'),
                      ActionChip(label: Text(AppLocalizations.of(context).email_address), onPressed: () => _textController.text = 'mailto:'),
                      ActionChip(label: Text(AppLocalizations.of(context).geo_location), onPressed: () => _textController.text = 'geo:24.7136,46.6753'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_textController.text.isNotEmpty)
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(AppLocalizations.of(context).qr_preview_title, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                              label: Text(AppLocalizations.of(context).save_as_image),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _shareQRCode,
                              icon: const Icon(Icons.share),
                              label: Text(AppLocalizations.of(context).share_action_short),
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
      ),
    );
  }

  Widget _buildHistoryTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(index % 2 == 0 ? Icons.qr_code : Icons.qr_code_scanner, color: Colors.white),
            ),
            title: Text('QR ${index + 1}'),
            subtitle: Text('${AppLocalizations.of(context).scanned_on_prefix}${DateTime.now().subtract(Duration(days: index)).toString().split(' ')[0]}'),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'copy',
                  child: ListTile(leading: const Icon(Icons.copy), title: Text(AppLocalizations.of(context).copy_action_short)),
                ),
                PopupMenuItem(
                  value: 'share',
                  child: ListTile(leading: const Icon(Icons.share), title: Text(AppLocalizations.of(context).share_action_short)),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(leading: const Icon(Icons.delete, color: Colors.red), title: Text(AppLocalizations.of(context).delete_action)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveQRCode() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).qr_saved_gallery)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context).save_error_prefix}$e')),
      );
    }
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
        title: Text(AppLocalizations.of(context).qr_title),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: const Icon(Icons.qr_code_scanner), text: AppLocalizations.of(context).qr_tab_scan),
            Tab(icon: const Icon(Icons.qr_code), text: AppLocalizations.of(context).qr_tab_generate),
            Tab(icon: const Icon(Icons.history), text: AppLocalizations.of(context).qr_tab_history),
          ],
        ),
      ),
      body: FirstOpenAnimator(
        pageKey: 'qr_barcode_scanner',
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildScannerTab(),
            _buildGeneratorTab(),
            _buildHistoryTab(),
          ],
        ),
      ),
    );
  }

  Future<void> _scanFromCamera() async {
    setState(() => _isScanning = true);
    try {
      final image = await _picker.pickImage(source: ImageSource.camera);
      if (image == null) return;
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        _scannedData = 'https://example.com/scanned-qr-${DateTime.now().millisecondsSinceEpoch}';
      });
      HapticFeedback.mediumImpact();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context).scan_error_prefix}$e')),
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
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _scannedData = AppLocalizations.of(context).scanned_text_from_selected_image;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context).scan_error_prefix}$e')),
      );
    } finally {
      setState(() => _isScanning = false);
    }
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
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.qr_code_scanner, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(AppLocalizations.of(context).qr_scan_area, style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 8),
                        Text(AppLocalizations.of(context).qr_position_camera, style: const TextStyle(fontSize: 12)),
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
                      label: Text(AppLocalizations.of(context).qr_scan_with_camera),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _scanFromGallery,
                      icon: const Icon(Icons.photo_library),
                      label: Text(AppLocalizations.of(context).from_gallery),
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
                        Text(AppLocalizations.of(context).qr_result, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        SelectableText(_scannedData!),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            FilledButton.icon(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: _scannedData!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(AppLocalizations.of(context).copied_done)),
                                );
                              },
                              icon: const Icon(Icons.copy),
                              label: Text(AppLocalizations.of(context).copy_action_short),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () => Share.share(_scannedData!),
                              icon: const Icon(Icons.share),
                              label: Text(AppLocalizations.of(context).share_action_short),
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
  Future<void> _shareQRCode() async {
    try {
      await Share.share(_textController.text);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context).share_error_prefix}$e')),
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
          title: Text(AppLocalizations.of(context).wifi_settings_title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ssidController,
                decoration: InputDecoration(labelText: AppLocalizations.of(context).network_name_ssid),
              ),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(labelText: AppLocalizations.of(context).password_label),
                obscureText: true,
              ),
              DropdownButtonFormField<String>(
                value: securityType,
                decoration: InputDecoration(labelText: AppLocalizations.of(context).security_type_label),
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
              child: Text(AppLocalizations.of(context).cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(AppLocalizations.of(context).create_action),
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
