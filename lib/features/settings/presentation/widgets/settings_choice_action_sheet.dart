import 'dart:async';

import 'package:chronoapp/core/widgets/app_modal_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SettingsChoiceActionSheet extends StatefulWidget {
  const SettingsChoiceActionSheet({
    super.key,
    required this.title,
    required this.options,
    required this.initialValue,
  });

  final String title;
  final List<String> options;
  final String? initialValue;

  @override
  State<SettingsChoiceActionSheet> createState() =>
      _SettingsChoiceActionSheetState();
}

class _SettingsChoiceActionSheetState extends State<SettingsChoiceActionSheet> {
  final _scrollController = ScrollController();
  final _selectedItemKey = GlobalKey();
  Timer? _showScrollbarTimer;
  Timer? _hideScrollbarTimer;
  bool _didScheduleInitialScrollbarReveal = false;
  bool _isScrollbarThumbVisible = false;

  static const Duration _initialScrollbarRevealDelay = Duration(
    milliseconds: 680,
  );
  static const Duration _initialScrollbarVisibleDuration = Duration(
    milliseconds: 900,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectedContext = _selectedItemKey.currentContext;
      if (selectedContext != null) {
        Scrollable.ensureVisible(
          selectedContext,
          duration: Duration.zero,
          alignment: 0.5,
        );
      }
      if (_scrollController.hasClients &&
          _scrollController.position.maxScrollExtent > 0) {
        _scheduleInitialScrollbarReveal();
      }
    });
  }

  @override
  void dispose() {
    _showScrollbarTimer?.cancel();
    _hideScrollbarTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _scheduleInitialScrollbarReveal() {
    if (_didScheduleInitialScrollbarReveal) return;
    _didScheduleInitialScrollbarReveal = true;

    _showScrollbarTimer?.cancel();
    _hideScrollbarTimer?.cancel();
    _showScrollbarTimer = Timer(_initialScrollbarRevealDelay, () {
      if (!mounted) return;
      setState(() {
        _isScrollbarThumbVisible = true;
      });
      _hideScrollbarTimer = Timer(_initialScrollbarVisibleDuration, () {
        if (!mounted) return;
        setState(() {
          _isScrollbarThumbVisible = false;
        });
      });
    });
  }

  Color _scrollbarThumbColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.78);
  }

  ScrollbarThemeData _scrollbarTheme(BuildContext context) {
    return ScrollbarTheme.of(context).copyWith(
      thumbVisibility: WidgetStatePropertyAll<bool>(_isScrollbarThumbVisible),
      thickness: const WidgetStatePropertyAll<double>(4.5),
      radius: const Radius.circular(4),
      crossAxisMargin: 2,
      mainAxisMargin: 2,
      thumbColor: WidgetStatePropertyAll<Color>(_scrollbarThumbColor(context)),
    );
  }

  Widget _buildPlatformScrollbar({required Widget child}) {
    final platform = Theme.of(context).platform;
    return ScrollbarTheme(
      data: _scrollbarTheme(context),
      child: platform == TargetPlatform.iOS || platform == TargetPlatform.macOS
          ? CupertinoScrollbar(
              controller: _scrollController,
              thickness: 4.5,
              thumbVisibility: _isScrollbarThumbVisible,
              child: child,
            )
          : Scrollbar(
              controller: _scrollController,
              thumbVisibility: _isScrollbarThumbVisible,
              child: child,
            ),
    );
  }

  Color _sheetBackgroundColor(BuildContext context) {
    final theme = Theme.of(context);
    return theme.bottomSheetTheme.modalBackgroundColor ??
        theme.bottomSheetTheme.backgroundColor ??
        theme.colorScheme.surfaceContainer;
  }

  static const double _bottomContentPadding = 12;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sheetConstraints = appModalChoiceSheetConstraints(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final sheetBg = _sheetBackgroundColor(context);

    return SafeArea(
      bottom: false,
      child: ConstrainedBox(
        constraints: sheetConstraints,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColoredBox(
              color: sheetBg,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                child: Text(
                  widget.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            Flexible(
              child: _buildPlatformScrollbar(
                child: ListView(
                  shrinkWrap: true,
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  children: [
                    ...widget.options.map((option) {
                      final isSelected = option == widget.initialValue;
                      return ListTile(
                        key: isSelected ? _selectedItemKey : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: Text(option),
                        trailing: isSelected
                            ? Icon(Icons.check_rounded, color: scheme.primary)
                            : null,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.of(context).pop(option);
                        },
                      );
                    }),
                  ],
                ),
              ),
            ),
            SizedBox(height: _bottomContentPadding + bottomInset),
          ],
        ),
      ),
    );
  }
}
