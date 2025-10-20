import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:office_archiving/service/sqlite_service.dart';
import 'package:office_archiving/l10n/app_localizations.dart';

class FileCleanupPage extends StatefulWidget {
  const FileCleanupPage({super.key});

  @override
  State<FileCleanupPage> createState() => _FileCleanupPageState();
}

class _FileCleanupPageState extends State<FileCleanupPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isScanning = false;
  bool _isCleaningUp = false;

  final List<Map<String, dynamic>> _duplicateFiles = [];
  final List<Map<String, dynamic>> _brokenFiles = [];
  final List<Map<String, dynamic>> _largeFiles = [];
  int _totalFilesScanned = 0;
  double _spaceSaved = 0;
  double _totalSpaceAnalyzed = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _scanForIssues() async {
    // إضافة haptic feedback فوري
    HapticFeedback.lightImpact();

    setState(() {
      _isScanning = true;
      _duplicateFiles.clear();
      _brokenFiles.clear();
      _largeFiles.clear();
      _totalFilesScanned = 0;
      _totalSpaceAnalyzed = 0;
    });

    // إضافة تأخير قصير لإظهار التغيير في الواجهة
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      final allItems = await DatabaseService.instance.getAllItems();

      // إظهار رسالة إذا لم توجد ملفات
      if (allItems.isEmpty) {
        setState(() {
          _isScanning = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).no_files_to_scan),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      Map<String, List<Map<String, dynamic>>> filesByName = {};

      for (var item in allItems) {
        final filePath = item['filePath'] as String;
        final fileName = item['name'] as String;
        final itemId = item['id'];

        _totalFilesScanned++;

        final file = File(filePath);
        if (!file.existsSync()) {
          _brokenFiles.add({
            'id': itemId,
            'name': fileName,
            'path': filePath,
            'issue': AppLocalizations.of(context).file_not_found,
          });
          continue;
        }

        final fileSize = file.lengthSync();
        _totalSpaceAnalyzed += fileSize;

        if (fileSize > 50 * 1024 * 1024) {
          _largeFiles.add({
            'id': itemId,
            'name': fileName,
            'size': fileSize,
            'sizeFormatted': _formatBytes(fileSize.toDouble()),
          });
        }

        if (!filesByName.containsKey(fileName)) {
          filesByName[fileName] = [];
        }
        filesByName[fileName]!.add({
          'id': itemId,
          'name': fileName,
          'path': filePath,
          'size': fileSize,
        });

        // تحديث الواجهة بشكل أكثر تكراراً لإظهار التقدم
        if (_totalFilesScanned % 2 == 0) {
          setState(() {});
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }

      // Find duplicates by name
      for (var entry in filesByName.entries) {
        if (entry.value.length > 1) {
          for (var file in entry.value) {
            _duplicateFiles.add({
              'id': file['id'],
              'name': file['name'],
              'issue': '${AppLocalizations.of(context).copies}: ${entry.value.length}',
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).scan_error}: $e')),
        );
      }
    }

    setState(() {
      _isScanning = false;
    });

    // إضافة haptic feedback عند انتهاء الفحص
    HapticFeedback.mediumImpact();

    // إظهار رسالة نجاح الفحص
    if (mounted) {
      final totalIssues =
          _duplicateFiles.length + _brokenFiles.length + _largeFiles.length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            totalIssues > 0
                ? 'تم الفحص! وُجد $totalIssues مشكلة'
                : AppLocalizations.of(context).scan_completed_no_issues,
          ),
          backgroundColor: totalIssues > 0 ? Colors.orange : Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _cleanupBrokenFiles() async {
    setState(() {
      _isCleaningUp = true;
      _spaceSaved = 0;
    });

    try {
      int cleanedCount = 0;

      for (var brokenFile in _brokenFiles) {
        await DatabaseService.instance.deleteItem(brokenFile['id']);
        cleanedCount++;
        _spaceSaved += 1024;
      }

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).files_cleaned}: $cleanedCount'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).cleanup_error}: $e')),
        );
      }
    }

    setState(() {
      _isCleaningUp = false;
    });

    await _scanForIssues();
  }

  String _formatBytes(double bytes) {
    if (bytes < 1024) return '${bytes.toInt()} B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).file_cleanup_title),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildScanSection(),
              const SizedBox(height: 24),
              if (_totalFilesScanned > 0) ...[
                _buildResultsSection(),
                const SizedBox(height: 24),
              ],
              _buildCleanupActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).scan_files,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).scan_description,
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isScanning ? null : _scanForIssues,
              icon: _isScanning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.scanner),
              label: Text(_isScanning
                  ? AppLocalizations.of(context).scanning
                  : AppLocalizations.of(context).start_scan),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isScanning
                    ? Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.7)
                    : Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: _isScanning ? 1 : 2,
              ),
            ),
          ),
          if (_isScanning)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _totalFilesScanned > 0
                                  ? 'تم فحص $_totalFilesScanned ${AppLocalizations.of(context).files_scanned}'
                                  : AppLocalizations.of(context).starting_scan,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        if (_totalSpaceAnalyzed > 0) ...[
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            backgroundColor: Colors.grey.withValues(alpha: 0.2),
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${AppLocalizations.of(context).space_analyzed}: ${_formatBytes(_totalSpaceAnalyzed)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).scan_results,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        _buildResultCard(
          AppLocalizations.of(context).duplicate_files,
          _duplicateFiles.length,
          _duplicateFiles,
          Icons.content_copy,
          Colors.orange,
        ),
        const SizedBox(height: 12),
        _buildResultCard(
          AppLocalizations.of(context).broken_files,
          _brokenFiles.length,
          _brokenFiles,
          Icons.broken_image,
          Colors.red,
        ),
        const SizedBox(height: 12),
        _buildResultCard(
          AppLocalizations.of(context).large_files,
          _largeFiles.length,
          _largeFiles,
          Icons.storage,
          Colors.blue,
        ),
      ],
    );
  }

  Widget _buildResultCard(
    String title,
    int count,
    List<Map<String, dynamic>> items,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...items.take(3).map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '• ${item['name']} ${item['issue'] != null ? '- ${item['issue']}' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
                  ),
                )),
            if (items.length > 3)
              Text(
                AppLocalizations.of(context).and_more_items(items.length - 3),
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildCleanupActions() {
    final hasIssues = _brokenFiles.isNotEmpty || _duplicateFiles.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cleaning_services,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).cleanup_actions,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_brokenFiles.isNotEmpty && !_isCleaningUp)
                  ? _cleanupBrokenFiles
                  : null,
              icon: _isCleaningUp
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.auto_fix_high),
              label: Text(_isCleaningUp
                  ? AppLocalizations.of(context).cleaning
                  : AppLocalizations.of(context).auto_cleanup),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _brokenFiles.isNotEmpty ? Colors.green : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          if (_spaceSaved > 0)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${AppLocalizations.of(context).space_saved} ${_formatBytes(_spaceSaved)}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (!hasIssues && _totalFilesScanned > 0)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context).no_issues_found,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
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
}
