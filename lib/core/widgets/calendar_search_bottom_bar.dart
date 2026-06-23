import 'dart:ui' show lerpDouble;

import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:chronoapp/core/widgets/app_glass_icon_button.dart';
import 'package:chronoapp/core/widgets/app_modal_sheet.dart';
import 'package:chronoapp/core/widgets/app_native_glass.dart';
import 'package:chronoapp/core/widgets/domspatzen_icon_metrics.dart';
import 'package:chronoapp/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/calendar_header/calendar_filter_bottom_sheet.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/search/calendar_search_layer.dart';
import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import 'app_hairline_divider.dart';

/// Liquid-Glass-Suchleiste im Suchmodus (ersetzt die Tab-Bar).
///
/// Auf iOS mit nativer Tab-Bar wird diese Leiste nicht angezeigt — dort bleibt
/// die [CNTabBarSearchItem]-Morph aktiv. Auf macOS und iOS-Landscape nutzt sie
/// [CNSearchBar]; auf anderen Plattformen den Material-Fallback mit Morph.
class CalendarSearchBottomBar extends ConsumerStatefulWidget {
  const CalendarSearchBottomBar({
    required this.onClose,
    this.showTrailingActions = true,
    super.key,
  });

  final VoidCallback onClose;

  /// Filter-Button in der Leiste (auf iOS mit nativer Tab-Bar im Header).
  final bool showTrailingActions;

  @override
  ConsumerState<CalendarSearchBottomBar> createState() =>
      _CalendarSearchBottomBarState();
}

class _CalendarSearchBottomBarState extends ConsumerState<CalendarSearchBottomBar>
    with SingleTickerProviderStateMixin {
  static const _morphDuration = Duration(milliseconds: 380);
  static const _barHeight = 48.0;
  static const _closeButtonSize = 48.0;
  static const _gapBetweenCloseAndBar = 8.0;
  static const _cornerRadius = 24.0;
  static const _glyphSize = 18.0;
  static const _fieldFontSize = 17.0;
  static const _fieldPrefixInset = 12.0;
  static const _materialSearchTrailingInset = 34.0;
  static const _searchPlaceholder = 'Finde den richtigen Termin';

  AnimationController? _morphController;
  Animation<double>? _morphCurve;
  TextEditingController? _textController;
  FocusNode? _focusNode;
  CNSearchBarController? _nativeSearchController;
  Rect? _morphOriginGlobal;

  bool get _useNativeSearchBar => useNativeLiquidGlass();

  @override
  void initState() {
    super.initState();
    final existingQuery = ref.read(calendarSearchQueryProvider);

    if (_useNativeSearchBar) {
      _nativeSearchController = CNSearchBarController();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (existingQuery.isNotEmpty) {
          _nativeSearchController?.setText(existingQuery);
        }
        _nativeSearchController?.focus();
        ref.read(calendarSearchInputFocusedProvider.notifier).update(true);
      });
      return;
    }

    _textController = TextEditingController(text: existingQuery);
    _focusNode = FocusNode();
    _morphController = AnimationController(
      vsync: this,
      duration: _morphDuration,
    );
    _morphCurve = CurvedAnimation(
      parent: _morphController!,
      curve: Curves.easeOutCubic,
    );
    _morphOriginGlobal = ref.read(calendarSearchMorphOriginProvider);
    _morphController!.addStatusListener(_onMorphStatusChanged);
    _focusNode!.addListener(_syncSearchInputFocus);
    _morphController!.forward();
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
      _closeButtonSize +
      _gapBetweenCloseAndBar +
      _fieldPrefixInset +
      _glyphSize / 2;

  void _syncSearchInputFocus() {
    if (!mounted || _focusNode == null) return;
    ref
        .read(calendarSearchInputFocusedProvider.notifier)
        .update(_focusNode!.hasFocus);
  }

  @override
  void dispose() {
    _morphController?.removeStatusListener(_onMorphStatusChanged);
    _focusNode?.removeListener(_syncSearchInputFocus);
    if (_focusNode?.hasFocus ?? false) {
      _focusNode?.unfocus();
    }
    ref.read(calendarSearchInputFocusedProvider.notifier).dismiss();
    _morphController?.dispose();
    _textController?.dispose();
    _focusNode?.dispose();
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

  Widget _buildCalendarCloseButton({required double sparrowAssetSize}) {
    final icon = SvgPicture.asset(
      DomspatzenIconMetrics.assetPath,
      height: sparrowAssetSize,
      width: sparrowAssetSize,
      fit: BoxFit.contain,
    );

    if (!useNativeLiquidGlass()) {
      final scheme = Theme.of(context).colorScheme;
      return Material(
        color: scheme.surface.withValues(alpha: 0.92),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: _closeButtonSize,
          height: _closeButtonSize,
          child: IconButton(
            tooltip: 'Suche beenden',
            onPressed: _handleClose,
            padding: EdgeInsets.zero,
            icon: icon,
          ),
        ),
      );
    }

    return LiquidGlassContainer(
      config: searchGlassConfig(
        context,
        shape: CNGlassEffectShape.capsule,
        cornerRadius: _closeButtonSize / 2,
      ),
      child: SizedBox(
        width: _closeButtonSize,
        height: _closeButtonSize,
        child: IconButton(
          tooltip: 'Suche beenden',
          onPressed: _handleClose,
          padding: EdgeInsets.zero,
          icon: icon,
        ),
      ),
    );
  }

  Widget _buildFilterButton() {
    return AppGlassIconButton(
      icon: Icons.filter_list_rounded,
      tooltip: 'Filter',
      iconSize: _glyphSize,
      glassEffectUnionId: kCalendarSearchGlassUnionId,
      onPressed: _openSearchFilters,
    );
  }

  Widget _buildNativeSearchRow(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sparrowAssetSize = DomspatzenIconMetrics.assetSizeForGlyph(_glyphSize);
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
          const AppHairlineDivider.horizontal(),
          Padding(
            padding: EdgeInsets.fromLTRB(12, 8, 12, bottomInset + 8),
            child: SizedBox(
              height: _barHeight,
              child: Row(
                children: [
                  _buildCalendarCloseButton(sparrowAssetSize: sparrowAssetSize),
                  const SizedBox(width: _gapBetweenCloseAndBar),
                  Expanded(
                    child: CNSearchBar(
                      controller: _nativeSearchController,
                      placeholder: _searchPlaceholder,
                      expandable: false,
                      initiallyExpanded: true,
                      showCancelButton: false,
                      expandedHeight: _barHeight,
                      textColor: scheme.onSurface.withValues(alpha: 0.96),
                      placeholderColor: scheme.onSurface.withValues(alpha: 0.7),
                      onChanged: (value) {
                        ref
                            .read(calendarSearchQueryProvider.notifier)
                            .updateQuery(value);
                      },
                    ),
                  ),
                  if (widget.showTrailingActions) ...[
                    const SizedBox(width: _gapBetweenCloseAndBar),
                    _buildFilterButton(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialMorphRow(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sparrowAssetSize = DomspatzenIconMetrics.assetSizeForGlyph(_glyphSize);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final inputFocused = ref.watch(calendarSearchInputFocusedProvider);
    final keyboardInset =
        inputFocused ? MediaQuery.viewInsetsOf(context).bottom : 0.0;
    final morphCurve = _morphCurve!;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppHairlineDivider.horizontal(),
          Padding(
            padding: EdgeInsets.fromLTRB(12, 8, 12, bottomInset + 8),
            child: AnimatedBuilder(
              animation: morphCurve,
              builder: (context, child) {
                final t = morphCurve.value;
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
                      height: _barHeight,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Row(
                            children: [
                              FadeTransition(
                                opacity: AlwaysStoppedAnimation(dotOpacity),
                                child: _buildCalendarCloseButton(
                                  sparrowAssetSize: sparrowAssetSize,
                                ),
                              ),
                              const SizedBox(width: _gapBetweenCloseAndBar),
                              Expanded(
                                flex: (fieldFlex * 100).round().clamp(1, 100),
                                child: _buildMaterialSearchField(scheme, t),
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
                                  child: Icon(
                                    Icons.search_rounded,
                                    size: flyingIconSize,
                                    color: scheme.onSurfaceVariant,
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

  Widget _buildMaterialSearchField(ColorScheme scheme, double t) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => _focusNode?.requestFocus(),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(_cornerRadius),
        ),
        child: SizedBox(
          height: _barHeight,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 4),
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
                    hintText: _searchPlaceholder,
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
              if (widget.showTrailingActions)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: IconButton(
                    tooltip: 'Filter',
                    onPressed: _openSearchFilters,
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
              if (t >= 0.92)
                Positioned(
                  left: _fieldPrefixInset,
                  top: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Opacity(
                        opacity: ((t - 0.92) / 0.08).clamp(0.0, 1.0),
                        child: Icon(
                          Icons.search_rounded,
                          size: _glyphSize + 1,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_useNativeSearchBar) {
      return _buildNativeSearchRow(context);
    }
    return _buildMaterialMorphRow(context);
  }
}
