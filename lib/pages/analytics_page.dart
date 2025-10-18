import 'dart:math';
import 'package:flutter/material.dart';
import 'package:office_archiving/models/storage_analytics.dart';
import 'package:office_archiving/service/sqlite_service.dart';
import 'package:office_archiving/l10n/app_localizations.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  StorageAnalytics? _analytics;
  bool _isLoading = true;

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
    _loadAnalytics();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    try {
      // Get real data from database
      final dbData = await DatabaseService.instance.getStorageAnalytics();
      
      // Convert to StorageAnalytics model
      final dailyUsageList = (dbData['dailyUsage'] as List).map((item) {
        return DailyUsage(
          date: DateTime.parse(item['date']),
          filesAdded: item['filesAdded'],
          sizeAdded: item['sizeAdded'].toDouble(),
        );
      }).toList();
      
      final popularFilesList = (dbData['mostAccessedFiles'] as List).map((item) {
        return PopularFile(
          name: item['name'],
          type: item['type'],
          accessCount: item['accessCount'],
          lastAccessed: DateTime.parse(item['lastAccessed']),
        );
      }).toList();
      
      // Calculate file type sizes (estimated)
      final fileTypeCount = Map<String, int>.from(dbData['fileTypeCount']);
      final totalSize = dbData['totalSizeBytes'].toDouble();
      final totalFiles = dbData['totalFiles'];
      
      Map<String, double> fileTypeSizes = {};
      fileTypeCount.forEach((type, count) {
        // Estimate size based on file count proportion
        fileTypeSizes[type] = (count / totalFiles) * totalSize;
      });
      
      final analytics = StorageAnalytics(
        totalFiles: dbData['totalFiles'],
        totalSections: dbData['totalSections'],
        totalSizeBytes: totalSize,
        fileTypeCount: fileTypeCount,
        fileTypeSizes: fileTypeSizes,
        dailyUsage: dailyUsageList,
        mostAccessedFiles: popularFilesList,
      );

      setState(() {
        _analytics = analytics;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      // Fallback to empty data if error
      final analytics = StorageAnalytics(
        totalFiles: 0,
        totalSections: 0,
        totalSizeBytes: 0,
        fileTypeCount: {},
        fileTypeSizes: {},
        dailyUsage: [],
        mostAccessedFiles: [],
      );
      
      setState(() {
        _analytics = analytics;
        _isLoading = false;
      });
      _animationController.forward();
    }
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).analytics_title),
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOverviewCards(),
                    const SizedBox(height: 24),
                    _buildFileTypeChart(),
                    const SizedBox(height: 24),
                    _buildStoragePieChart(),
                    const SizedBox(height: 24),
                    _buildUsageChart(),
                    const SizedBox(height: 24),
                    _buildMonthlyReport(),
                    const SizedBox(height: 24),
                    _buildPopularFiles(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOverviewCards() {
    final analytics = _analytics!;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                AppLocalizations.of(context).total_files,
                analytics.totalFiles.toString(),
                Icons.description,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                AppLocalizations.of(context).sections,
                analytics.totalSections.toString(),
                Icons.folder,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                AppLocalizations.of(context).storage_size,
                analytics.formattedTotalSize,
                Icons.storage,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                AppLocalizations.of(context).avg_files_per_section,
                analytics.averageFilesPerSection.toStringAsFixed(1),
                Icons.analytics,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileTypeChart() {
    final analytics = _analytics!;
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
          Text(
            AppLocalizations.of(context).file_type_distribution,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...analytics.fileTypeCount.entries.map((entry) {
            final percentage = (entry.value / analytics.totalFiles * 100);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(entry.key),
                  ),
                  Expanded(
                    flex: 5,
                    child: LinearProgressIndicator(
                      value: entry.value / analytics.totalFiles,
                      backgroundColor: Colors.grey.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation(_getColorForFileType(entry.key)),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${percentage.toStringAsFixed(1)}%',
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildStoragePieChart() {
    final analytics = _analytics!;
    if (analytics.fileTypeSizes.isEmpty) {
      return const SizedBox.shrink();
    }

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
          Text(
            AppLocalizations.of(context).size_distribution,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildPieChart(analytics),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 1,
                  child: _buildPieLegend(analytics),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(StorageAnalytics analytics) {
    final total = analytics.fileTypeSizes.values.fold(0.0, (sum, size) => sum + size);
    if (total == 0) return Center(child: Text(AppLocalizations.of(context).no_data));

    return CustomPaint(
      size: const Size(150, 150),
      painter: PieChartPainter(analytics.fileTypeSizes, total),
    );
  }

  Widget _buildPieLegend(StorageAnalytics analytics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: analytics.fileTypeSizes.entries.map((entry) {
        final color = _getColorForFileType(entry.key);
        final sizeFormatted = _formatBytes(entry.value);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      sizeFormatted,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUsageChart() {
    final analytics = _analytics!;
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
          Text(
            AppLocalizations.of(context).weekly_usage,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: analytics.dailyUsage.map((usage) {
                final maxFiles = analytics.dailyUsage.map((u) => u.filesAdded).reduce(max);
                final height = (usage.filesAdded / maxFiles * 100).clamp(10.0, 100.0);
                
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 24,
                        height: height,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getDayName(usage.date.weekday),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularFiles() {
    final analytics = _analytics!;
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
          Text(
            AppLocalizations.of(context).most_accessed_files,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...analytics.mostAccessedFiles.map((file) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: _getColorForFileType(file.type).withValues(alpha: 0.2),
                child: Icon(
                  _getIconForFileType(file.type),
                  color: _getColorForFileType(file.type),
                ),
              ),
              title: Text(
                file.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text('${file.accessCount} ${AppLocalizations.of(context).times}'),
              trailing: Text(
                _formatLastAccessed(file.lastAccessed),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Color _getColorForFileType(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'image':
        return Colors.green;
      case 'document':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconForFileType(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'image':
        return Icons.image;
      case 'document':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _getDayName(int weekday) {
    // أيام الأسبوع بالعربية - أول حرف من كل يوم
    const days = ['ن', 'ث', 'ر', 'خ', 'ج', 'س', 'ح']; // الاثنين، الثلاثاء، الأربعاء، الخميس، الجمعة، السبت، الأحد
    return days[weekday - 1];
  }

  Widget _buildMonthlyReport() {
    final analytics = _analytics!;
    final now = DateTime.now();
    final currentMonth = '${_getMonthName(now.month)} ${now.year}';
    
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
              Icon(Icons.calendar_month, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                '${AppLocalizations.of(context).monthly_report} $currentMonth',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMonthlyMetric(AppLocalizations.of(context).files_added, '${analytics.totalFiles}', Icons.add_circle_outline, Colors.green),
          const SizedBox(height: 12),
          _buildMonthlyMetric(AppLocalizations.of(context).space_used, analytics.formattedTotalSize, Icons.storage, Colors.blue),
          const SizedBox(height: 12),
          _buildMonthlyMetric(AppLocalizations.of(context).most_common_type, _getMostCommonFileType(analytics), Icons.trending_up, Colors.orange),
          const SizedBox(height: 12),
          _buildMonthlyMetric(AppLocalizations.of(context).growth_rate, '+${(analytics.totalFiles * 0.15).toInt()}%', Icons.show_chart, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildMonthlyMetric(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getMostCommonFileType(StorageAnalytics analytics) {
    if (analytics.fileTypeCount.isEmpty) return AppLocalizations.of(context).undefined;
    
    var maxEntry = analytics.fileTypeCount.entries.first;
    for (var entry in analytics.fileTypeCount.entries) {
      if (entry.value > maxEntry.value) {
        maxEntry = entry;
      }
    }
    return maxEntry.key;
  }

  String _getMonthName(int month) {
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return months[month - 1];
  }

  String _formatBytes(double bytes) {
    if (bytes < 1024) return '${bytes.toInt()} B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatLastAccessed(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inHours < 1) {
      return 'منذ ${difference.inMinutes} ${AppLocalizations.of(context).minutes_ago}';
    } else if (difference.inDays < 1) {
      return 'منذ ${difference.inHours} ${AppLocalizations.of(context).hours_ago}';
    } else {
      return 'منذ ${difference.inDays} ${AppLocalizations.of(context).days_ago}';
    }
  }
}

// Custom Pie Chart Painter
class PieChartPainter extends CustomPainter {
  final Map<String, double> data;
  final double total;

  PieChartPainter(this.data, this.total);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 10;
    
    double startAngle = -pi / 2;
    
    for (var entry in data.entries) {
      final sweepAngle = (entry.value / total) * 2 * pi;
      final color = _getColorForFileType(entry.key);
      
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      
      startAngle += sweepAngle;
    }
    
    // Draw center circle for donut effect
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, radius * 0.4, centerPaint);
  }

  Color _getColorForFileType(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'image':
        return Colors.green;
      case 'document':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
