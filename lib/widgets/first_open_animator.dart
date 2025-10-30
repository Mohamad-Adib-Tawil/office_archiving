import 'package:flutter/material.dart';
import 'package:office_archiving/services/first_open_service.dart';

class FirstOpenAnimator extends StatefulWidget {
  final String pageKey;
  final Widget child;
  final Duration duration;
  final Curve curve;
  final double offsetY;
  final double startScale;
  final bool enabled;

  const FirstOpenAnimator({
    super.key,
    required this.pageKey,
    required this.child,
    this.duration = const Duration(milliseconds: 900),
    this.curve = Curves.easeOutCubic,
    this.offsetY = 28.0,
    this.startScale = 0.985,
    this.enabled = true,
  });

  @override
  State<FirstOpenAnimator> createState() => _FirstOpenAnimatorState();
}

class _FirstOpenAnimatorState extends State<FirstOpenAnimator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;

  bool _animateNow = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    final curved = CurvedAnimation(parent: _controller, curve: widget.curve);
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    _scale = Tween<double>(begin: widget.startScale, end: 1.0).animate(curved);
    _slide = Tween<Offset>(begin: Offset(0, widget.offsetY / 100), end: Offset.zero)
        .animate(curved);

    Future.microtask(() async {
      final first = await FirstOpenService.isFirstOpen(widget.pageKey);
      if (!mounted) return;
      if (first) {
        setState(() => _animateNow = true);
        _controller.forward();
      } else {
        // No animation on subsequent opens
        setState(() => _animateNow = false);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || !_animateNow) return widget.child;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(
          scale: _scale,
          child: widget.child,
        ),
      ),
    );
  }
}
