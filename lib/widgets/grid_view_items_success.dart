import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:office_archiving/constants.dart';
import 'package:office_archiving/cubit/item_section_cubit/item_section_cubit.dart';
import 'package:office_archiving/functions/show_item_dialog.dart';
import 'package:office_archiving/helper/open_file.dart';
import 'package:office_archiving/helper/pdf_viwer.dart';
import 'package:office_archiving/models/item.dart';
import 'package:office_archiving/l10n/app_localizations.dart';

class GridViewItemsSuccess extends StatelessWidget {
  const GridViewItemsSuccess({
    super.key,
    required this.items,
    required this.itemSectionCubit,
  });

  final List<ItemSection> items;
  final ItemSectionCubit itemSectionCubit;

  static const _imageTypes = {'image', 'jpg', 'jpeg', 'png', 'gif', 'webp'};
  static const _videoTypes = {'mp4', 'mov', 'avi', 'mkv', 'flv', 'wmv'};
  static const _audioTypes = {'mp3', 'wav', 'ogg', 'aac', 'm4a', 'flac'};
  static const _docTypes = {'pdf', 'docx', 'doc', 'txt', 'rtf'};
  static const _sheetTypes = {'xlsx', 'xls', 'csv'};

  static const _iconSize = 64.0;
  static const _gridPadding = EdgeInsets.symmetric(horizontal: 4);
  static const _gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    crossAxisSpacing: 10.0,
    mainAxisSpacing: 10.0,
  );
  IconData _getFileIcon(String? fileType) {
    final type = fileType?.toLowerCase();

    if (_videoTypes.contains(type)) return Icons.videocam;
    if (_audioTypes.contains(type)) return Icons.audiotrack;
    if (_docTypes.contains(type)) {
      switch (type) {
        case 'pdf':
          return Icons.picture_as_pdf;
        case 'txt':
          return Icons.text_fields;
        default:
          return Icons.description;
      }
    }
    if (_sheetTypes.contains(type)) return Icons.table_chart;
    if (_imageTypes.contains(type)) return Icons.image;

    return Icons.insert_drive_file;
  }

  Color _getIconColor(String? fileType) {
    final type = fileType?.toLowerCase();

    if (_videoTypes.contains(type)) return Colors.purple.shade700;
    if (_audioTypes.contains(type)) return Colors.orange.shade700;
    if (_docTypes.contains(type)) {
      switch (type) {
        case 'pdf':
          return Colors.red;
        case 'txt':
          return Colors.blue.shade800;
        default:
          return Colors.blue;
      }
    }
    if (_sheetTypes.contains(type)) return Colors.green.shade700;
    if (_imageTypes.contains(type)) return Colors.amber.shade700;

    return Colors.grey.shade700;
  }

  // Removed unused _buildMediaOverlay to satisfy lint

  Widget _buildFileInfo(ItemSection item) {
    final isArabic =
        item.name.contains(RegExp(r'[\u0600-\u06FF\u0750-\u077F\u0590-\u05FF\uFE70-\uFEFF\uFB50-\uFDFF\uFEE0-\uFEFF]'));

    return Column(
      children: [
        Text(
          item.name,
          textAlign: TextAlign.center,
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          item.fileType?.toUpperCase() ?? 'UNKNOWN',
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildMediaThumbnail(ItemSection item) {
    final fileType = item.fileType?.toLowerCase();
    final filePath = item.filePath;

    if (_imageTypes.contains(fileType) && filePath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(filePath),
          fit: BoxFit.cover,
          width: double.infinity,
          height: 120,
          errorBuilder: (ctx, _, __) => Container(
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image),
          ),
        ),
      );
    }

    if (_videoTypes.contains(fileType)) {
      return Stack(
        children: [
          Container(
            color: Colors.grey[200],
            height: 120,
            child: const Center(
              child: Icon(Icons.videocam, size: 40),
            ),
          ),
          const Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: Icon(Icons.play_circle_filled, color: Colors.white54, size: 50),
            ),
          ),
        ],
      );
    }

    return Icon(
      _getFileIcon(fileType),
      size: _iconSize,
      color: _getIconColor(fileType),
    );
  }

  Widget _buildFileThumbnail(ItemSection item) {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // المنطقة العلوية للصورة/الأيقونة
          Expanded(
            child: SizedBox(
              height: 120,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: _buildMediaThumbnail(item),
              ),
            ),
          ),
          // المنطقة السفلية للمعلومات
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildFileInfo(item),
          ),
        ],
      ),
    );
  }

  void _handleFileTap(BuildContext context, ItemSection item) {
    final fileType = item.fileType?.toLowerCase();
    final filePath = item.filePath;

    if (fileType == null || filePath == null || !File(filePath).existsSync()) {
      _showErrorDialog(context);
      return;
    }

    if (fileType == 'pdf') {
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MyPdfViewer(filePath: filePath),
          ));
    } else {
      openFile(pathFile: filePath, context: context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Image(
              image: AssetImage(kLogoOffice),
              width: 200,
              height: 200,
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.emptyItemsMessage,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: _gridPadding,
      gridDelegate: _gridDelegate,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        log('Item details: ${item.id} | ${item.name} | ${item.fileType} | ${item.filePath}');

        return GestureDetector(
          onTap: () => _handleFileTap(context, item),
          onLongPress: () => showItemOptionsDialog(context, item, itemSectionCubit),
          child: _buildFileThumbnail(item),
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.fileErrorTitle),
        content: Text(AppLocalizations.of(context)!.fileErrorBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
