import 'package:flutter/material.dart';
import 'package:office_archiving/cubit/item_section_cubit/item_section_cubit.dart';
import 'package:office_archiving/functions/add_item_from_memory_storage.dart';
import 'package:office_archiving/functions/add_item_from_camera.dart';
import 'package:office_archiving/functions/addItemFromGallery.dart';
import 'package:office_archiving/theme/app_icons.dart';

void showAddItemSheet(BuildContext context, int idSection, ItemSectionCubit itemCubit) {
  final theme = Theme.of(context);
  final primary = theme.colorScheme.primary;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: theme.colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(AppIcons.add, color: primary),
                  ),
                  const SizedBox(width: 12),
                  Text('Add item', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 12),
              _ActionTile(
                icon: AppIcons.file,
                color: Colors.blue,
                title: 'From Files',
                onTap: () {
                  Navigator.pop(ctx);
                  addItemFromMemoryStorage(context, idSection, itemCubit);
                },
              ),
              _ActionTile(
                icon: AppIcons.image,
                color: Colors.orange,
                title: 'From Gallery',
                onTap: () {
                  Navigator.pop(ctx);
                  addItemFromGallery(context, idSection, itemCubit);
                },
              ),
              _ActionTile(
                icon: AppIcons.video, // fallback if no camera icon
                color: Colors.teal,
                title: 'From Camera',
                onTap: () {
                  Navigator.pop(ctx);
                  addItemFromCamera(idSection, itemCubit, context);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.color, required this.title, required this.onTap});
  final IconData icon;
  final Color color;
  final String title;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withOpacity(.6), color.withOpacity(.15)]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white.withOpacity(.2), shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title, style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
        onTap: onTap,
      ),
    );
  }
}
