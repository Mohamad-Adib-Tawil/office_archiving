import 'package:flutter/material.dart';
  import 'package:office_archiving/constants.dart';
  import 'package:office_archiving/pages/home_screen.dart';
  import 'package:office_archiving/l10n/app_localizations.dart';

  class SplashView extends StatefulWidget {
    const SplashView({super.key});

    @override
    State<SplashView> createState() => _SplashViewState();
  }

class _SplashViewState extends State<SplashView> with SingleTickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<double> _logoOpacity;
  late Animation<double> _logoScale;
  late Animation<double> _textOpacity;

  @override
  void initState() {
    super.initState();
    initSlidingAnimation();
    navigateToHome();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: _logoOpacity,
              child: ScaleTransition(
                scale: _logoScale,
                child: Image.asset(
                  kLogoOffice,
                  width: 200,
                  height: 200,
                ),
              ),
            ),
            const SizedBox(height: 12),
            FadeTransition(
              opacity: _textOpacity,
              child: Text(
                AppLocalizations.of(context).splashMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

///////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////
  void initSlidingAnimation() {
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _logoOpacity = CurvedAnimation(
      parent: animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    );

    _logoScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: animationController, curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic)),
    );

    _textOpacity = CurvedAnimation(
      parent: animationController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );

    animationController.forward();
  }

///////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////
  void navigateToHome() {
    Future.delayed(
      const Duration(milliseconds: 1600),
      () {
        if (!mounted) return;
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            ));
      },
    );
  }
}

///////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////
class SlidingText extends StatelessWidget {
  const SlidingText({
    super.key,
    required this.slidingAnimation,
  });

  final Animation<Offset> slidingAnimation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: slidingAnimation,
        builder: (context, _) {
          return SlideTransition(
            position: slidingAnimation,
            child: Text(
              AppLocalizations.of(context).splashMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 20),
            ),
          );
        });
  }
}
