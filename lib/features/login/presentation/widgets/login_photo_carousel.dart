import 'dart:async';

import 'package:flutter/material.dart';

/// Full-bleed photos with a gentle crossfade in the tablet login pane.
class LoginPhotoCarousel extends StatefulWidget {
  const LoginPhotoCarousel({super.key});

  @override
  State<LoginPhotoCarousel> createState() => _LoginPhotoCarouselState();
}

class _LoginPhotoCarouselState extends State<LoginPhotoCarousel>
    with WidgetsBindingObserver {
  static const _alignments = [
    Alignment(0, 0.15),
    Alignment(0, 0.45),
    Alignment.center,
    Alignment.center,
    Alignment.center,
    Alignment(0, 0.35),
  ];
  Timer? _timer;
  int _index = 0;
  bool _reduceMotion = false;
  bool _foreground = true;

  String _asset(int index) =>
      'assets/login_carousel/domspatzen_${index + 1}.jpg';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _restartTimer();
    _preloadNext();
  }

  void _preloadNext() {
    unawaited(
      precacheImage(
        AssetImage(_asset((_index + 1) % _alignments.length)),
        context,
      ),
    );
  }

  void _restartTimer() {
    _timer?.cancel();
    if (_reduceMotion ||
        !_foreground ||
        !TickerMode.valuesOf(context).enabled) {
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      setState(() => _index = (_index + 1) % _alignments.length);
      _preloadNext();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _restartTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ClipRect(
        child: ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: AnimatedSwitcher(
            duration: _reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 1400),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation.status == AnimationStatus.reverse
                  ? const AlwaysStoppedAnimation<double>(1)
                  : animation,
              child: child,
            ),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            layoutBuilder: (currentChild, previousChildren) => Stack(
              fit: StackFit.expand,
              children: [...previousChildren, ?currentChild],
            ),
            child: Image.asset(
              _asset(_index),
              key: ValueKey(_index),
              fit: BoxFit.cover,
              alignment: _alignments[_index],
              width: double.infinity,
              height: double.infinity,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
      ),
    );
  }
}
