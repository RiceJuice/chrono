import 'package:flutter/material.dart';

/// Liefert [animation] und [forward] aus [loginSlidePage], damit Unterbäume
/// (z. B. nur Body + Button) selbst sliden können.
class LoginSlideScope extends InheritedWidget {
  const LoginSlideScope({
    super.key,
    required this.forward,
    required this.animation,
    required super.child,
  });

  final bool forward;
  final Animation<double> animation;

  static LoginSlideScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LoginSlideScope>();
  }

  @override
  bool updateShouldNotify(LoginSlideScope oldWidget) {
    return forward != oldWidget.forward || animation != oldWidget.animation;
  }
}

/// Slidet [child] horizontal — nur sinnvoll unterhalb eines festen Headers.
class LoginSlideLayer extends StatelessWidget {
  const LoginSlideLayer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scope = LoginSlideScope.maybeOf(context);
    if (scope == null) {
      return child;
    }
    final begin = scope.forward ? const Offset(1, 0) : const Offset(-1, 0);
    return SlideTransition(
      position: Tween<Offset>(begin: begin, end: Offset.zero).animate(
        CurvedAnimation(
          parent: scope.animation,
          curve: Curves.easeOutCubic,
        ),
      ),
      child: child,
    );
  }
}
