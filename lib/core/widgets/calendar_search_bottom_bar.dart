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
  static const _morphDuration = Duration(milliseconds: 380);
  static const _barHeight = 52.0;
  static const _closeButtonSize = 56.0;
  static const _closeButtonGlyphSize = 20.0;
  static const _gapBetweenCloseAndBar = 8.0;
  static const _glyphSize = 18.0;
  static const _fieldFontSize = 16.0;

  static const _leadingIconSlotWidth = 40.0;
  static const _trailingIconSlotWidth = 44.0;
  static const _materialSearchTrailingInset = 34.0;

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

  double _morphStartCenterX(double rowWidth, RenderBox? rowBox) {
    if (_morphOriginGlobal != null && rowBox != null) {
      return rowBox.globalToLocal(_morphOriginGlobal!.center).dx;
    }
    return rowWidth - _materialSearchTrailingInset;
  }

  double _morphEndCenterX() =>
      _closeButtonSize + _gapBetweenCloseAndBar + _leadingIconSlotWidth / 2;

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

    final button = Tooltip(
      message: 'Suche beenden',
      child: SizedBox(
        width: _closeButtonSize,
        height: _closeButtonSize,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _handleClose,
            child: Center(child: icon),
          ),
        ),
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
        shape: CNGlassEffectShape.circle,
        tint: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.42),
      ),
      child: button,
    );
  }

  Widget _buildGlassShell({
    required Widget child,
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
            shape: CNGlassEffectShape.capsule,
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
          borderRadius: BorderRadius.circular(_barHeight / 2),
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sparrowAssetSize =
        DomspatzenIconMetrics.assetSizeForGlyph(_closeButtonGlyphSize);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final inputFocused = ref.watch(calendarSearchInputFocusedProvider);
    final keyboardInset =
        inputFocused ? MediaQuery.viewInsetsOf(context).bottom : 0.0;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              12,
              0,
              12,
              (bottomInset - 6).clamp(6.0, double.infinity),
            ),
            child: AnimatedBuilder(
              animation: _morphCurve,
              builder: (context, child) {
                final t = _morphCurve.value;
                final morphComplete = t >= 1.0;
                final useNativeGlass = _useNativeGlass() && morphComplete;
                final dotOpacity = t.clamp(0.0, 1.0);
                final fieldFlex = 0.15 + 0.85 * t;

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final rowWidth = constraints.maxWidth;
                    final rowBox = context.findRenderObject() as RenderBox?;
                    final startCenterX = _morphStartCenterX(rowWidth, rowBox);
                    final endCenterX = _morphEndCenterX();
                    final magnifierCenterX =
                        lerpDouble(startCenterX, endCenterX, t)!;
                    final flyingIconSize =
                        lerpDouble(_glyphSize + 2, _glyphSize + 1, t)!;
                    final flyingOpacity =
                        (1.0 - (t - 0.92) / 0.08).clamp(0.0, 1.0);

                    return SizedBox(
                      height: _closeButtonSize,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              FadeTransition(
                                opacity: AlwaysStoppedAnimation(dotOpacity),
                                child: _buildCalendarCloseButton(
                                  sparrowAssetSize: sparrowAssetSize,
                                  useNativeGlass: useNativeGlass,
                                ),
                              ),
                              const SizedBox(width: _gapBetweenCloseAndBar),
                              Expanded(
                                flex: (fieldFlex * 100).round().clamp(1, 100),
                                child: _buildGlassShell(
                                  useNativeGlass: useNativeGlass,
                                  child: SizedBox(
                                    height: _barHeight,
                                    child: Stack(
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: _leadingIconSlotWidth,
                                              height: _barHeight,
                                              child: t >= 0.92
                                                  ? IgnorePointer(
                                                      child: Opacity(
                                                        opacity: ((t - 0.92) /
                                                                0.08)
                                                            .clamp(0.0, 1.0),
                                                        child: Center(
                                                          child: Icon(
                                                            Icons.search_rounded,
                                                            size: _glyphSize,
                                                            color: scheme
                                                                .onSurfaceVariant,
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                  : const SizedBox.shrink(),
                                            ),
                                            Expanded(
                                              child: TextField(
                                                controller: _textController,
                                                focusNode: _focusNode,
                                                textInputAction:
                                                    TextInputAction.search,
                                                textAlignVertical:
                                                    TextAlignVertical.center,
                                                style: TextStyle(
                                                  fontSize: _fieldFontSize,
                                                  height: 1.0,
                                                  color: scheme.onSurface
                                                      .withValues(alpha: 0.96),
                                                ),
                                                decoration: InputDecoration(
                                                  isDense: true,
                                                  filled: false,
                                                  fillColor: Colors.transparent,
                                                  border: InputBorder.none,
                                                  enabledBorder:
                                                      InputBorder.none,
                                                  focusedBorder:
                                                      InputBorder.none,
                                                  hintText:
                                                      'Finde den richtigen Termin',
                                                  hintStyle: TextStyle(
                                                    fontSize: _fieldFontSize,
                                                    height: 1.0,
                                                    color: scheme.onSurface
                                                        .withValues(alpha: 0.7),
                                                  ),
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 2,
                                                    vertical: 14,
                                                  ),
                                                ),
                                                onChanged: (value) {
                                                  ref
                                                      .read(
                                                        calendarSearchQueryProvider
                                                            .notifier,
                                                      )
                                                      .updateQuery(value);
                                                },
                                              ),
                                            ),
                                            SizedBox(
                                              width: _trailingIconSlotWidth,
                                              height: _barHeight,
                                              child: IconButton(
                                                tooltip: 'Filter',
                                                onPressed: _openSearchFilters,
                                                padding: EdgeInsets.zero,
                                                visualDensity:
                                                    VisualDensity.compact,
                                                iconSize: _glyphSize,
                                                style: IconButton.styleFrom(
                                                  tapTargetSize:
                                                      MaterialTapTargetSize
                                                          .shrinkWrap,
                                                ),
                                                icon: Icon(
                                                  Icons.filter_list_rounded,
                                                  size: _glyphSize,
                                                  color: scheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (t < 0.92)
                            Positioned(
                              left: magnifierCenterX - flyingIconSize / 2,
                              top: 0,
                              bottom: 0,
                              child: IgnorePointer(
                                child: Opacity(
                                  opacity: flyingOpacity,
                                  child: Center(
                                    child: Icon(
                                      Icons.search_rounded,
                                      size: flyingIconSize,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
