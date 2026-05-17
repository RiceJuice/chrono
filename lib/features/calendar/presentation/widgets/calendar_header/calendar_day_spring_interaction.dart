import 'package:chronoapp/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

/// Feder-Parameter — bewusst zurückhaltend und kritisch gedämpft (kein Bounce).
abstract final class CalendarDaySpringPhysics {
  static const double restScale = 1.0;
  static const double pressedScale = 0.96;
  static const double minScale = 0.94;
  static const double maxScale = 1.01;

  static const SpringDescription press = SpringDescription(
    mass: 0.22,
    stiffness: 620,
    damping: 30,
  );

  static const SpringDescription release = SpringDescription(
    mass: 0.26,
    stiffness: 560,
    damping: 32,
  );

  /// Dezentes Einblenden der Auswahl (Swipe, Programmatik, …).
  static const SpringDescription appear = SpringDescription(
    mass: 0.3,
    stiffness: 520,
    damping: 31,
  );

  static const double appearStartScale = 0.94;

  static const Tolerance simulationTolerance = Tolerance(
    velocity: 0.02,
    distance: 0.002,
  );

  /// Opazität bei gedrücktem Zustand (Rest = 1.0) — nur leicht spürbar.
  static double opacityForScale(double scale) {
    final t =
        ((scale - pressedScale) / (restScale - pressedScale)).clamp(0.0, 1.0);
    return 0.92 + 0.08 * t;
  }
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

  void _runSpring({
    required double target,
    required SpringDescription spring,
    double velocity = 0,
  }) {
    _scaleController.stop();
    final simulation = SpringSimulation(
      spring,
      _scaleController.value,
      target,
      velocity,
      tolerance: CalendarDaySpringPhysics.simulationTolerance,
    );
    _scaleController.animateWith(simulation);
  }

  void _onPointerDown(PointerDownEvent event) {
    if (!widget.enabled) return;
    _isPressed = true;
    // Kein HapticFeedback hier: bei erfolgreichem Tages-Tap feuert
    // [SelectedDay.update] in calendar_providers.dart bereits
    // [HapticFeedback.mediumImpact]. Zusätzliches Feedback auf pointerDown
    // würde doppelt vibrieren (Press + Provider-Wechsel).
    _runSpring(
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
    _runSpring(
      target: CalendarDaySpringPhysics.restScale,
      spring: CalendarDaySpringPhysics.release,
      velocity: delta * 6,
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

/// Dezentes Appear, wenn der Tag **extern** ausgewählt wird (Wischen, Listener, …).
///
/// Bei direktem Tap ([CalendarDaySelectionOrigin.tap]) bleibt die Animation aus,
/// damit sie nicht mit dem Druck-Feedback von [CalendarDaySpringInteraction]
/// kollidiert — dort liefert [SelectedDay.update] bereits Haptic.
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
    with SingleTickerProviderStateMixin {
  late final AnimationController _appearController;

  @override
  void initState() {
    super.initState();
    _appearController = AnimationController(
      vsync: this,
      value: CalendarDaySpringPhysics.restScale,
      lowerBound: CalendarDaySpringPhysics.minScale,
      upperBound: CalendarDaySpringPhysics.maxScale,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePlayAppear());
  }

  @override
  void dispose() {
    _appearController.dispose();
    super.dispose();
  }

  void _maybePlayAppear() {
    if (!widget.enabled || !mounted) return;
    if (!isSameDay(ref.read(selectedDayProvider), widget.day)) return;
    final originTracker = ref.read(calendarDaySelectionOriginProvider.notifier);
    if (originTracker.changeGeneration == 0) return;
    if (ref.read(calendarDaySelectionOriginProvider) !=
        CalendarDaySelectionOrigin.external) {
      return;
    }
    _playAppear();
  }

  void _playAppear() {
    _appearController.stop();
    _appearController.value = CalendarDaySpringPhysics.appearStartScale;
    final simulation = SpringSimulation(
      CalendarDaySpringPhysics.appear,
      CalendarDaySpringPhysics.appearStartScale,
      CalendarDaySpringPhysics.restScale,
      0,
      tolerance: CalendarDaySpringPhysics.simulationTolerance,
    );
    _appearController.animateWith(simulation);
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
      animation: _appearController,
      builder: (context, child) {
        return Transform.scale(
          scale: _appearController.value,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
