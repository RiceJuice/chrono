import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:chronoapp/core/widgets/app_modal_sheet.dart';
import 'package:chronoapp/core/widgets/domspatzen_icon_metrics.dart';
import 'package:chronoapp/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/calendar_header/calendar_filter_bottom_sheet.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/search/calendar_search_layer.dart';
import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

/// Liquid-Glass-Suchleiste im Suchmodus (ersetzt die Tab-Bar).
class CalendarSearchBottomBar extends ConsumerStatefulWidget {
  const CalendarSearchBottomBar({
    required this.onClose,
    super.key,
  });

  final VoidCallback onClose;

  @override
  ConsumerState<CalendarSearchBottomBar> createState() =>
      _CalendarSearchBottomBarState();
}

class _CalendarSearchBottomBarState extends ConsumerState<CalendarSearchBottomBar>
    with SingleTickerProviderStateMixin {
  static const _morphDuration = Duration(milliseconds: 420);
  /// Entspricht [kMainShellNavigationBarHeight] — dupliziert wegen Zirkelimport.
  static const _shellBarHeight = 56.0;
  static const _barHeight = 48.0;
  static const _closeButtonSize = 48.0;
  static const _searchButtonSize = 44.0;
  static const _gapBetweenCloseAndBar = 8.0;
  static const _cornerRadius = 24.0;
  static const _glyphSize = 18.0;
  static const _fieldFontSize = 17.0;

  static const _fieldPrefixInset = 12.0;

  late final AnimationController _morphController;
  late final Animation<double> _morphCurve;
  late final TextEditingController _textController;
  late final FocusNode _focusNode;
  Rect? _morphOriginGlobal;

  @override
  void initState() {
    super.initState();
    final existingQuery = ref.read(calendarSearchQueryProvider);
    _textController = TextEditingController(text: existingQuery);
    _focusNode = FocusNode();
    _morphController = AnimationController(vsync: this, duration: _morphDuration);
    _morphCurve = CurvedAnimation(
      parent: _morphController,
      curve: Curves.easeOutCubic,
    );
    _morphOriginGlobal = ref.read(calendarSearchMorphOriginProvider);
    _morphController.addStatusListener(_onMorphStatusChanged);
    _focusNode.addListener(_syncSearchInputFocus);
    _morphController.forward();
  }

  void _onMorphStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    ref.read(calendarSearchMorphOriginProvider.notifier).clear();
  }

  Rect _morphStartLocalRect(double slotWidth, RenderBox? slotBox) {
    if (_morphOriginGlobal != null && slotBox != null) {
      final topLeft = slotBox.globalToLocal(_morphOriginGlobal!.topLeft);
      final bottomRight = slotBox.globalToLocal(_morphOriginGlobal!.bottomRight);
      return Rect.fromPoints(topLeft, bottomRight);
    }

    final top = (_shellBarHeight - _searchButtonSize) / 2;
    return Rect.fromLTWH(
      slotWidth - _searchButtonSize,
      top,
      _searchButtonSize,
      _searchButtonSize,
    );
  }

  void _syncSearchInputFocus() {
    if (!mounted) return;
    ref
        .read(calendarSearchInputFocusedProvider.notifier)
        .update(_focusNode.hasFocus);
  }

  @override
  void dispose() {
    _morphController.removeStatusListener(_onMorphStatusChanged);
    _focusNode.removeListener(_syncSearchInputFocus);
    if (_focusNode.hasFocus) {
      _focusNode.unfocus();
    }
    ref.read(calendarSearchInputFocusedProvider.notifier).dismiss();
    _morphController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _openSearchFilters() async {
    HapticFeedback.heavyImpact();
    await AppModalSheet.show<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const CalendarFilterBottomSheet(
        mode: CalendarFilterBottomSheetMode.searchFilter,
      ),
    );
  }

  void _handleClose() {
    AppHaptics.light();
    exitCalendarSearchToCalendarTab(ref, context);
  }

  bool _useNativeGlass() {
    final isApple = defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    return isApple && PlatformVersion.shouldUseNativeGlass;
  }

  Widget _buildCalendarCloseButton({
    required double sparrowAssetSize,
    required bool useNativeGlass,
  }) {
    final icon = SvgPicture.asset(
      DomspatzenIconMetrics.assetPath,
      height: sparrowAssetSize,
      width: sparrowAssetSize,
      fit: BoxFit.contain,
    );

    final button = SizedBox(
      width: _closeButtonSize,
      height: _closeButtonSize,
      child: IconButton(
        tooltip: 'Suche beenden',
        onPressed: _handleClose,
        padding: EdgeInsets.zero,
        icon: icon,
      ),
    );

    if (!useNativeGlass) {
      final scheme = Theme.of(context).colorScheme;
      return Material(
        color: scheme.surface.withValues(alpha: 0.92),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: button,
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LiquidGlassContainer(
      config: LiquidGlassConfig(
        effect: CNGlassEffect.regular,
        shape: CNGlassEffectShape.capsule,
        cornerRadius: _closeButtonSize / 2,
        tint: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.42),
      ),
      child: button,
    );
  }

  Widget _buildGlassShell({
    required Widget child,
    required double cornerRadius,
    required bool useNativeGlass,
  }) {
    if (useNativeGlass) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => _focusNode.requestFocus(),
        child: LiquidGlassContainer(
          config: LiquidGlassConfig(
            effect: CNGlassEffect.regular,
            shape: CNGlassEffectShape.rect,
            cornerRadius: cornerRadius,
            tint: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white.withValues(alpha: 0.42),
          ),
          child: child,
        ),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => _focusNode.requestFocus(),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(cornerRadius),
        ),
        child: child,
      ),
    );
  }

  Widget _buildSearchFieldContent({
    required ColorScheme scheme,
    required double chromeOpacity,
    required bool fieldInteractive,
    required double searchIconLeft,
  }) {
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, right: 4),
          child: Opacity(
            opacity: chromeOpacity,
            child: IgnorePointer(
              ignoring: !fieldInteractive,
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                textInputAction: TextInputAction.search,
                style: TextStyle(
                  fontSize: _fieldFontSize,
                  color: scheme.onSurface.withValues(alpha: 0.96),
                ),
                decoration: InputDecoration(
                  isDense: true,
                  filled: false,
                  fillColor: Colors.transparent,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintText: 'Finde den richtigen Termin',
                  hintStyle: TextStyle(
                    fontSize: _fieldFontSize,
                    color: scheme.onSurface.withValues(alpha: 0.7),
                  ),
                  contentPadding: const EdgeInsets.only(
                    left: 28,
                    right: 36,
                    top: 12,
                    bottom: 12,
                  ),
                ),
                onChanged: (value) {
                  ref
                      .read(calendarSearchQueryProvider.notifier)
                      .updateQuery(value);
                },
              ),
            ),
          ),
        ),
        Positioned(
          left: searchIconLeft,
          top: 0,
          bottom: 0,
          child: IgnorePointer(
            child: Center(
              child: Icon(
                Icons.search_rounded,
                size: _glyphSize + 1,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: Opacity(
            opacity: chromeOpacity,
            child: IconButton(
              tooltip: 'Filter',
              onPressed: fieldInteractive ? _openSearchFilters : null,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              iconSize: _glyphSize,
              icon: Icon(
                Icons.filter_list_rounded,
                size: _glyphSize,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sparrowAssetSize = DomspatzenIconMetrics.assetSizeForGlyph(_glyphSize);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final inputFocused = ref.watch(calendarSearchInputFocusedProvider);
    final keyboardInset =
        inputFocused ? MediaQuery.viewInsetsOf(context).bottom : 0.0;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(12, 0, 12, bottomInset),
            child: AnimatedBuilder(
              animation: _morphCurve,
              builder: (context, child) {
                final t = reduceMotion ? 1.0 : _morphCurve.value;
                final morphComplete = t >= 1.0;
                final useNativeGlass = _useNativeGlass() && morphComplete;
                final chromeOpacity = const Interval(
                  0.55,
                  0.92,
                  curve: Curves.easeOut,
                ).transform(t);
                final iconSlide = const Interval(
                  0.0,
                  0.78,
                  curve: Curves.easeOutCubic,
                ).transform(t);

                return SizedBox(
                  height: _shellBarHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildCalendarCloseButton(
                        sparrowAssetSize: sparrowAssetSize,
                        useNativeGlass: _useNativeGlass(),
                      ),
                      const SizedBox(width: _gapBetweenCloseAndBar),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final slotWidth = constraints.maxWidth;
                            final slotBox =
                                context.findRenderObject() as RenderBox?;
                            final startRect = _morphStartLocalRect(
                              slotWidth,
                              slotBox,
                            );

                            final fieldWidth = lerpDouble(
                              startRect.width,
                              slotWidth,
                              t,
                            )!;
                            final fieldRight = lerpDouble(
                              startRect.right,
                              slotWidth,
                              t,
                            )!;
                            final fieldLeft = fieldRight - fieldWidth;
                            final fieldTop = lerpDouble(
                              startRect.top.clamp(0.0, _shellBarHeight),
                              (_shellBarHeight - _barHeight) / 2,
                              t,
                            )!;
                            final fieldHeight = lerpDouble(
                              startRect.height,
                              _barHeight,
                              t,
                            )!;
                            final cornerRadius = lerpDouble(
                              math.min(startRect.width, startRect.height) / 2,
                              _cornerRadius,
                              t,
                            )!;
                            final searchIconLeft = lerpDouble(
                              (fieldWidth - _glyphSize) / 2,
                              _fieldPrefixInset,
                              iconSlide,
                            )!;

                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned(
                                  left: fieldLeft,
                                  top: fieldTop,
                                  width: fieldWidth,
                                  height: fieldHeight,
                                  child: _buildGlassShell(
                                    cornerRadius: cornerRadius,
                                    useNativeGlass: useNativeGlass,
                                    child: SizedBox(
                                      height: fieldHeight,
                                      child: _buildSearchFieldContent(
                                        scheme: scheme,
                                        chromeOpacity: chromeOpacity,
                                        fieldInteractive: morphComplete,
                                        searchIconLeft: searchIconLeft,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
