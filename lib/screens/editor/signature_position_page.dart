import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/rendering.dart';

class SignaturePlacementResult {
  final int baseX;
  final int baseY;
  final int targetBaseWidth;
  const SignaturePlacementResult({
    required this.baseX,
    required this.baseY,
    required this.targetBaseWidth,
  });
}

class SignaturePositionPage extends StatefulWidget {
  final String baseImagePath;
  final Uint8List signatureBytes;
  const SignaturePositionPage({
    super.key,
    required this.baseImagePath,
    required this.signatureBytes,
  });

  @override
  State<SignaturePositionPage> createState() => _SignaturePositionPageState();
}

class _SignaturePositionPageState extends State<SignaturePositionPage> {
  img.Image? _baseImg;
  img.Image? _sigImg;

  // overlay position in displayed coordinates
  double _overlayLeft = 0;
  double _overlayTop = 0;
  // overlay width as fraction of displayed base width
  double _overlayScale = 0.3; // 30% of displayed width

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final baseBytes = await File(widget.baseImagePath).readAsBytes();
    final base = img.decodeImage(baseBytes);
    final sig = img.decodeImage(widget.signatureBytes);
    if (mounted) {
      setState(() {
        _baseImg = base;
        _sigImg = sig;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('تحديد موضع التوقيع'),
        actions: [
          TextButton(
            onPressed: (_baseImg == null || _sigImg == null)
                ? null
                : () => _apply(context),
            child: const Text('تطبيق', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: (_baseImg == null || _sigImg == null)
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (ctx, constraints) {
                final cw = constraints.maxWidth;
                final ch = constraints.maxHeight;
                final baseW = _baseImg!.width.toDouble();
                final baseH = _baseImg!.height.toDouble();
                final scale =
                    (cw / baseW)
                            .clamp(0.0, double.infinity)
                            .compareTo(
                              (ch / baseH).clamp(0.0, double.infinity),
                            ) <
                        0
                    ? (cw / baseW)
                    : (ch / baseH);
                final dispW = baseW * scale;
                final dispH = baseH * scale;
                final offX = (cw - dispW) / 2;
                final offY = (ch - dispH) / 2;

                final overlayW = dispW * _overlayScale;
                final overlayH = overlayW * (_sigImg!.height / _sigImg!.width);

                // Clamp overlay inside displayed rect
                double left = _overlayLeft;
                double top = _overlayTop;
                left = left.clamp(offX, offX + dispW - overlayW);
                top = top.clamp(offY, offY + dispH - overlayH);

                return Stack(
                  children: [
                    // Base image
                    Positioned(
                      left: offX,
                      top: offY,
                      width: dispW,
                      height: dispH,
                      child: Image.file(
                        File(widget.baseImagePath),
                        fit: BoxFit.contain,
                      ),
                    ),

                    // Overlay signature
                    Positioned(
                      left: left,
                      top: top,
                      width: overlayW,
                      height: overlayH,
                      child: GestureDetector(
                        onPanUpdate: (d) {
                          setState(() {
                            _overlayLeft = (left + d.delta.dx);
                            _overlayTop = (top + d.delta.dy);
                          });
                        },
                        child: Opacity(
                          opacity: 0.95,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                            child: Image.memory(
                              widget.signatureBytes,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Bottom controls
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: SafeArea(
                        top: false,
                        child: Container(
                          color: theme.colorScheme.surface.withValues(
                            alpha: 0.9,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  const Text('الحجم'),
                                  Expanded(
                                    child: Slider(
                                      value: _overlayScale,
                                      min: 0.1,
                                      max: 0.8,
                                      onChanged: (v) =>
                                          setState(() => _overlayScale = v),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'الموضع: x=${(left - offX).toStringAsFixed(0)}, y=${(top - offY).toStringAsFixed(0)}',
                                  ),
                                  Text(
                                    'العرض: ${(overlayW).toStringAsFixed(0)}px',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  void _apply(BuildContext context) {
    // Map display to base coordinates
    final renderBox = context.findRenderObject() as RenderBox?;
    final cw = renderBox?.size.width ?? MediaQuery.of(context).size.width;
    final ch = renderBox?.size.height ?? MediaQuery.of(context).size.height;

    final baseW = _baseImg!.width.toDouble();
    final baseH = _baseImg!.height.toDouble();
    final scale =
        (cw / baseW)
                .clamp(0.0, double.infinity)
                .compareTo((ch / baseH).clamp(0.0, double.infinity)) <
            0
        ? (cw / baseW)
        : (ch / baseH);
    final dispW = baseW * scale;
    final dispH = baseH * scale;
    final offX = (cw - dispW) / 2;
    final offY = (ch - dispH) / 2;

    final overlayW = dispW * _overlayScale;
    final overlayH = overlayW * (_sigImg!.height / _sigImg!.width);

    // Clamp
    final left = _overlayLeft.clamp(offX, offX + dispW - overlayW);
    final top = _overlayTop.clamp(offY, offY + dispH - overlayH);

    final baseX = ((left - offX) / scale).round();
    final baseY = ((top - offY) / scale).round();
    final targetBaseWidth = (overlayW / scale).round();

    Navigator.pop(
      context,
      SignaturePlacementResult(
        baseX: baseX,
        baseY: baseY,
        targetBaseWidth: targetBaseWidth,
      ),
    );
  }
}
