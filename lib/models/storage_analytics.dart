class StorageAnalytics {
  final int totalFiles;
  final int totalSections;
  final double totalSizeBytes;
  final Map<String, int> fileTypeCount;
  final Map<String, double> fileTypeSizes;
  final List<DailyUsage> dailyUsage;
  final List<PopularFile> mostAccessedFiles;

  StorageAnalytics({
    required this.totalFiles,
    required this.totalSections,
    required this.totalSizeBytes,
    required this.fileTypeCount,
    required this.fileTypeSizes,
    required this.dailyUsage,
    required this.mostAccessedFiles,
  });

  String get formattedTotalSize {
    if (totalSizeBytes < 1024) return '${totalSizeBytes.toInt()} B';
    if (totalSizeBytes < 1024 * 1024) return '${(totalSizeBytes / 1024).toStringAsFixed(1)} KB';
    if (totalSizeBytes < 1024 * 1024 * 1024) return '${(totalSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(totalSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  double get averageFilesPerSection => totalSections > 0 ? totalFiles / totalSections : 0;
}

class DailyUsage {
  final DateTime date;
  final int filesAdded;
  final double sizeAdded;

  DailyUsage({
    required this.date,
    required this.filesAdded,
    required this.sizeAdded,
  });
}

class PopularFile {
  final String name;
  final String type;
  final int accessCount;
  final DateTime lastAccessed;

  PopularFile({
    required this.name,
    required this.type,
    required this.accessCount,
    required this.lastAccessed,
  });
}
