// لوحة توقيع رقمية تُنتج صورة PNG للتوقيع
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

class SignaturePad extends StatefulWidget {
  const SignaturePad({super.key});

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  final SignatureController _controller =
      SignatureController(penStrokeWidth: 3, penColor: Colors.black);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _done() async {
    if (_controller.isEmpty) {
      Navigator.pop(context);
      return;
    }
    final Uint8List? bytes = await _controller.toPngBytes();
    Navigator.pop(context, bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التوقيع'),
        actions: [
          TextButton(
            onPressed: _done,
            child: const Text('تم', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.white,
              child: Signature(controller: _controller, backgroundColor: Colors.white),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  TextButton(onPressed: () => _controller.clear(), child: const Text('مسح')),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
