import 'package:chronoapp/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

/// Feder-Parameter im Stil von UIKit (leichter Overshoot, schneller Ansprung).
abstract final class CalendarDaySpringPhysics {
  static const double restScale = 1.0;
  static const double pressedScale = 0.86;
  static const double minScale = 0.78;
  static const double maxScale = 1.1;

  /// Schnelles Einfedern beim Drücken — ohne Nachschwingen.
  static final SpringDescription press = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 520,
    ratio: 1.02,
  );

  /// Loslassen mit dezentem iOS-Bounce.
  static final SpringDescription release = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 380,
    ratio: 0.72,
  );

  /// Einblenden bei programmatischer / Swipe-Auswahl.
  static final SpringDescription appear = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 320,
    ratio: 0.68,
  );

  /// Horizontales Gleiten der Auswahl-Pille (Wochenkopf).
  static final SpringDescription slide = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 340,
    ratio: 0.78,
  );

  static const double appearStartScale = 0.72;
  static const double appearStartOpacity = 0.45;

  static const Tolerance simulationTolerance = Tolerance(
    velocity: 0.015,
    distance: 0.0015,
  );

  static double opacityForScale(double scale) {
    final t =
        ((scale - pressedScale) / (restScale - pressedScale)).clamp(0.0, 1.0);
    return 0.88 + 0.12 * t;
  }
}

void _runSpringOn(
  AnimationController controller, {
  required double target,
  required SpringDescription spring,
  double velocity = 0,
}) {
  controller.stop();
  final simulation = SpringSimulation(
    spring,
    controller.value,
    target,
    velocity,
    tolerance: CalendarDaySpringPhysics.simulationTolerance,
  );
  controller.animateWith(simulation);
}

/// Physikbasierter Druck-/Loslass-Effekt für einzelne Kalendertage.
///
/// Nutzt [Listener], damit [TableCalendar] seine Tap-Gesten unverändert
/// behält. Skalierung und Opazität laufen über [SpringSimulation].
class CalendarDaySpringInteraction extends StatefulWidget {
  const CalendarDaySpringInteraction({
    required this.child,
    this.enabled = true,
    super.key,
  });

  final Widget child;
  final bool enabled;

  @override
  State<CalendarDaySpringInteraction> createState() =>
      _CalendarDaySpringInteractionState();
}

class _CalendarDaySpringInteractionState extends State<CalendarDaySpringInteraction>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      value: CalendarDaySpringPhysics.restScale,
      lowerBound: CalendarDaySpringPhysics.minScale,
      upperBound: CalendarDaySpringPhysics.maxScale,
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    if (!widget.enabled) return;
    _isPressed = true;
    _runSpringOn(
      _scaleController,
      target: CalendarDaySpringPhysics.pressedScale,
      spring: CalendarDaySpringPhysics.press,
    );
  }

  void _onPointerUp(PointerUpEvent event) {
    _release();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _release();
  }

  void _release() {
    if (!widget.enabled || !_isPressed) return;
    _isPressed = false;
    final delta = CalendarDaySpringPhysics.restScale - _scaleController.value;
    _runSpringOn(
      _scaleController,
      target: CalendarDaySpringPhysics.restScale,
      spring: CalendarDaySpringPhysics.release,
      velocity: delta * 10,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: AnimatedBuilder(
        animation: _scaleController,
        builder: (context, child) {
          final scale = _scaleController.value;
          return Transform.scale(
            scale: scale,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
            child: Opacity(
              opacity: CalendarDaySpringPhysics.opacityForScale(scale),
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Bouncy Appear bei externer Auswahl (Wischen, Scroll-Snap, Programmatik).
class CalendarDaySelectionAppear extends ConsumerStatefulWidget {
  const CalendarDaySelectionAppear({
    required this.day,
    required this.child,
    this.enabled = true,
    super.key,
  });

  final DateTime day;
  final Widget child;
  final bool enabled;

  @override
  ConsumerState<CalendarDaySelectionAppear> createState() =>
      _CalendarDaySelectionAppearState();
}

class _CalendarDaySelectionAppearState extends ConsumerState<CalendarDaySelectionAppear>
    with TickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final AnimationController _opacityController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      value: CalendarDaySpringPhysics.restScale,
      lowerBound: CalendarDaySpringPhysics.minScale,
      upperBound: CalendarDaySpringPhysics.maxScale,
    );
    _opacityController = AnimationController(
      vsync: this,
      value: 1,
      lowerBound: 0,
      upperBound: 1,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePlayAppear());
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _opacityController.dispose();
    super.dispose();
  }

  void _maybePlayAppear() {
    if (!widget.enabled || !mounted) return;
    if (!isSameDay(ref.read(selectedDayProvider), widget.day)) return;
    final originTracker = ref.read(calendarDaySelectionOriginProvider.notifier);
    if (originTracker.changeGeneration == 0) return;
    if (ref.read(calendarDaySelectionOriginProvider) ==
        CalendarDaySelectionOrigin.tap) {
      return;
    }
    _playAppear();
  }

  void _playAppear() {
    _scaleController.stop();
    _opacityController.stop();
    _scaleController.value = CalendarDaySpringPhysics.appearStartScale;
    _opacityController.value = CalendarDaySpringPhysics.appearStartOpacity;

    _runSpringOn(
      _scaleController,
      target: CalendarDaySpringPhysics.restScale,
      spring: CalendarDaySpringPhysics.appear,
    );
    _runSpringOn(
      _opacityController,
      target: 1,
      spring: CalendarDaySpringPhysics.appear,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<DateTime>(selectedDayProvider, (previous, next) {
      if (!isSameDay(next, widget.day)) return;
      if (previous != null && isSameDay(previous, widget.day)) return;
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybePlayAppear());
    });

    if (!widget.enabled) return widget.child;

    return AnimatedBuilder(
      animation: Listenable.merge([_scaleController, _opacityController]),
      builder: (context, child) {
        return Opacity(
          opacity: _opacityController.value,
          child: Transform.scale(
            scale: _scaleController.value,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
