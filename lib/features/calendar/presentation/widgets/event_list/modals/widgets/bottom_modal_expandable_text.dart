import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Abschnitt mit Label und Text, der nach [maxCollapsedLines] per „mehr“
/// in der letzten Zeile animiert aufgeklappt wird.
class BottomModalExpandableTextSection extends StatefulWidget {
  const BottomModalExpandableTextSection({
    super.key,
    required this.label,
    required this.text,
    required this.labelStyle,
    required this.bodyStyle,
    this.maxCollapsedLines = 3,
    this.labelGap = AppSpacing.s,
  });

  final String label;
  final String text;
  final TextStyle? labelStyle;
  final TextStyle? bodyStyle;
  final int maxCollapsedLines;
  final double labelGap;

  @override
  State<BottomModalExpandableTextSection> createState() =>
      _BottomModalExpandableTextSectionState();
}

class _BottomModalExpandableTextSectionState
    extends State<BottomModalExpandableTextSection> {
  static const Duration _kExpandDuration = Duration(milliseconds: 280);
  static const Curve _kExpandCurve = Curves.easeInOutCubic;
  static const String _kMoreLabel = ' mehr';
  static const String _kLessLabel = ' weniger';

  bool _expanded = false;
  bool _canExpand = false;
  double? _lastMeasuredWidth;
  String? _collapsedPrefix;
  TapGestureRecognizer? _toggleRecognizer;

  @override
  void didUpdateWidget(covariant BottomModalExpandableTextSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _expanded = false;
      _canExpand = false;
      _lastMeasuredWidth = null;
      _collapsedPrefix = null;
    }
  }

  @override
  void dispose() {
    _toggleRecognizer?.dispose();
    super.dispose();
  }

  TextStyle _bodyStyle(BuildContext context) {
    return widget.bodyStyle ?? DefaultTextStyle.of(context).style;
  }

  TextStyle _linkStyle(BuildContext context) {
    final theme = Theme.of(context);
    final base = _bodyStyle(context);
    return base.copyWith(
      fontSize: base.fontSize ?? 17,
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w600,
    );
  }

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
  }

  TapGestureRecognizer _recognizer() {
    return _toggleRecognizer ??= TapGestureRecognizer()..onTap = _toggleExpanded;
  }

  void _measureLayout(double maxWidth) {
    if (maxWidth <= 0) return;

    final bodyStyle = _bodyStyle(context);
    final linkStyle = _linkStyle(context);
    final textDirection = Directionality.of(context);

    final fullPainter = TextPainter(
      text: TextSpan(text: widget.text, style: bodyStyle),
      maxLines: widget.maxCollapsedLines,
      textDirection: textDirection,
    )..layout(maxWidth: maxWidth);

    final canExpand = fullPainter.didExceedMaxLines;
    String? collapsedPrefix;

    if (canExpand) {
      collapsedPrefix = _truncateForInlineAction(
        text: widget.text,
        suffix: _kMoreLabel,
        bodyStyle: bodyStyle,
        actionStyle: linkStyle,
        maxWidth: maxWidth,
        maxLines: widget.maxCollapsedLines,
        textDirection: textDirection,
      );
    }

    if (_lastMeasuredWidth == maxWidth &&
        _canExpand == canExpand &&
        _collapsedPrefix == collapsedPrefix) {
      return;
    }

    setState(() {
      _canExpand = canExpand;
      _lastMeasuredWidth = maxWidth;
      _collapsedPrefix = collapsedPrefix;
      if (!canExpand) _expanded = false;
    });
  }

  String _truncateForInlineAction({
    required String text,
    required String suffix,
    required TextStyle bodyStyle,
    required TextStyle actionStyle,
    required double maxWidth,
    required int maxLines,
    required TextDirection textDirection,
  }) {
    var low = 0;
    var high = text.length;
    var best = '';

    while (low <= high) {
      final mid = (low + high) ~/ 2;
      final candidate = text.substring(0, mid).trimRight();
      final painter = TextPainter(
        text: TextSpan(
          style: bodyStyle,
          children: [
            TextSpan(text: candidate),
            TextSpan(text: suffix, style: actionStyle),
          ],
        ),
        maxLines: maxLines,
        textDirection: textDirection,
      )..layout(maxWidth: maxWidth);

      if (!painter.didExceedMaxLines) {
        best = candidate;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    if (best.isEmpty && text.isNotEmpty) {
      return text.substring(0, 1);
    }

    return best;
  }

  InlineSpan _buildCollapsedSpan(BuildContext context) {
    final bodyStyle = _bodyStyle(context);
    final linkStyle = _linkStyle(context);

    if (!_canExpand) {
      return TextSpan(text: widget.text, style: bodyStyle);
    }

    final prefix = _collapsedPrefix ?? widget.text;
    return TextSpan(
      style: bodyStyle,
      children: [
        TextSpan(text: prefix),
        TextSpan(
          text: _kMoreLabel,
          style: linkStyle,
          recognizer: _recognizer(),
        ),
      ],
    );
  }

  InlineSpan _buildExpandedSpan(BuildContext context) {
    final bodyStyle = _bodyStyle(context);
    final linkStyle = _linkStyle(context);

    return TextSpan(
      style: bodyStyle,
      children: [
        TextSpan(text: widget.text),
        TextSpan(
          text: _kLessLabel,
          style: linkStyle,
          recognizer: _recognizer(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _measureLayout(constraints.maxWidth);
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.label, style: widget.labelStyle),
            SizedBox(height: widget.labelGap),
            AnimatedSize(
              duration: _kExpandDuration,
              curve: _kExpandCurve,
              alignment: Alignment.topCenter,
              clipBehavior: Clip.none,
              child: Text.rich(
                _expanded ? _buildExpandedSpan(context) : _buildCollapsedSpan(context),
                textAlign: TextAlign.start,
              ),
            ),
          ],
        );
      },
    );
  }
}
