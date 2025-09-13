import 'package:flutter/material.dart';
import 'package:office_archiving/constants.dart';

class CustomAppBarWidgetApp extends StatelessWidget
    implements PreferredSizeWidget {
  const CustomAppBarWidgetApp({
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text(kOfficeArchiving),
      centerTitle: true,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
