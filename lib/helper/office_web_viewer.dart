import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

/// عارض مكتبي يعتمد WebView محلي (يعمل أوفلاين بالكامل):
/// يحمّل قالب HTML من الأصول، ويمرّر بايتات الملف (base64) لمكتبة JS لعرضها.
class OfficeWebViewerPage extends StatefulWidget {
  const OfficeWebViewerPage({
    super.key,
    required this.filePath,
    required this.assetHtml,
    required this.jsFunction,
  });

  final String filePath;

  /// مسار قالب HTML داخل الأصول، مثل: assets/viewers/docx.html
  final String assetHtml;

  /// اسم دالة JS التي تُستدعى مع (base64, isRtl)، مثل: renderDocx / renderXlsx
  final String jsFunction;

  @override
  State<OfficeWebViewerPage> createState() => _OfficeWebViewerPageState();
}

class _OfficeWebViewerPageState extends State<OfficeWebViewerPage> {
  bool _loading = true;
  String? _error;
  String? _base64;

  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _loadBytes();
  }

  Future<void> _loadBytes() async {
    try {
      final bytes = await File(widget.filePath).readAsBytes();
      _base64 = base64Encode(bytes);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '$e';
        });
      }
    }
  }

  void _registerHandlers(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
      handlerName: 'onRendered',
      callback: (_) {
        if (mounted) setState(() => _loading = false);
      },
    );
    controller.addJavaScriptHandler(
      handlerName: 'onError',
      callback: (args) {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = args.isNotEmpty ? '${args.first}' : 'render error';
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            p.basename(widget.filePath),
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: _ar ? 'مشاركة' : 'Share',
              onPressed: () => Share.shareXFiles([XFile(widget.filePath)]),
            ),
          ],
        ),
        body: _error != null
            ? _ErrorView(message: _error!, isArabic: _ar)
            : Stack(
                children: [
                  InAppWebView(
                    initialFile: widget.assetHtml,
                    initialSettings: InAppWebViewSettings(
                      javaScriptEnabled: true,
                      allowFileAccess: true,
                      allowFileAccessFromFileURLs: true,
                      allowUniversalAccessFromFileURLs: true,
                      supportZoom: true,
                      builtInZoomControls: true,
                      displayZoomControls: false,
                      transparentBackground: true,
                    ),
                    onWebViewCreated: _registerHandlers,
                    onLoadStop: (controller, _) async {
                      if (_base64 == null) return;
                      final rtl = _ar ? 'true' : 'false';
                      await controller.evaluateJavascript(
                        source: "${widget.jsFunction}('$_base64', $rtl)",
                      );
                    },
                    onReceivedError: (controller, request, error) {
                      if (mounted) {
                        setState(() {
                          _loading = false;
                          _error = error.description;
                        });
                      }
                    },
                  ),
                  if (_loading)
                    const Center(child: CircularProgressIndicator()),
                ],
              ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.isArabic});

  final String message;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              isArabic ? 'تعذّر عرض الملف' : 'Could not display file',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
