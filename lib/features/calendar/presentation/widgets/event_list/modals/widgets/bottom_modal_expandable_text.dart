import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Abschnitt mit Label und Text, der nach [maxCollapsedLines] per „Mehr“
/// inline in der letzten Zeile animiert aufgeklappt wird.
class BottomModalExpandableTextSection extends StatefulWidget {
  const BottomModalExpandableTextSection({
    super.key,
    this.label,
    required this.text,
    this.labelStyle,
    required this.bodyStyle,
    this.maxCollapsedLines = 2,
    this.labelGap = AppSpacing.s,
  });

  final String? label;
  final String text;
  final TextStyle? labelStyle;
  final TextStyle? bodyStyle;
  final int maxCollapsedLines;
  final double labelGap;

  @override
  State<BottomModalExpandableTextSection> createState() =>
      _BottomModalExpandableTextSectionState();
}

class _CollapsedLayout {
  const _CollapsedLayout({
    required this.canExpand,
    required this.prefix,
  });

  final bool canExpand;
  final String prefix;
}

class _BottomModalExpandableTextSectionState
    extends State<BottomModalExpandableTextSection> {
  static const Duration _kExpandDuration = Duration(milliseconds: 280);
  static const Curve _kExpandCurve = Curves.easeInOutCubic;
  static const String _kMoreLabel = ' Mehr';
  static const String _kLessLabel = ' Weniger';

  bool _expanded = false;
  TapGestureRecognizer? _toggleRecognizer;

  @override
  void didUpdateWidget(covariant BottomModalExpandableTextSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _expanded = false;
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

  _CollapsedLayout _collapsedLayout({
    required BuildContext context,
    required double maxWidth,
  }) {
    final effectiveWidth = _effectiveMaxWidth(context, maxWidth);
    if (effectiveWidth <= 0) {
      return _CollapsedLayout(canExpand: false, prefix: widget.text);
    }

    final bodyStyle = _bodyStyle(context);
    final linkStyle = _linkStyle(context);
    final textDirection = Directionality.of(context);
    final textScaler = MediaQuery.textScalerOf(context);

    final fullPainter = TextPainter(
      text: TextSpan(text: widget.text, style: bodyStyle),
      textDirection: textDirection,
      textScaler: textScaler,
    )..layout(maxWidth: effectiveWidth);

    final canExpand =
        fullPainter.computeLineMetrics().length > widget.maxCollapsedLines;

    if (!canExpand) {
      return _CollapsedLayout(canExpand: false, prefix: widget.text);
    }

    return _CollapsedLayout(
      canExpand: true,
      prefix: _truncateForInlineAction(
        text: widget.text,
        suffix: _kMoreLabel,
        bodyStyle: bodyStyle,
        actionStyle: linkStyle,
        maxWidth: effectiveWidth,
        maxLines: widget.maxCollapsedLines,
        textDirection: textDirection,
        textScaler: textScaler,
      ),
    );
  }

  double _effectiveMaxWidth(BuildContext context, double maxWidth) {
    if (maxWidth.isFinite && maxWidth > 0) return maxWidth;
    return MediaQuery.sizeOf(context).width;
  }

  String _truncateForInlineAction({
    required String text,
    required String suffix,
    required TextStyle bodyStyle,
    required TextStyle actionStyle,
    required double maxWidth,
    required int maxLines,
    required TextDirection textDirection,
    required TextScaler textScaler,
  }) {
    var low = 0;
    var high = text.length;
    var best = '';

    while (low <= high) {
      final mid = (low + high) ~/ 2;
      final candidate = text.substring(0, mid).trimRight();
      if (_fitsInLines(
        span: TextSpan(
          style: bodyStyle,
          children: [
            TextSpan(text: candidate),
            TextSpan(text: suffix, style: actionStyle),
          ],
        ),
        maxWidth: maxWidth,
        maxLines: maxLines,
        textDirection: textDirection,
        textScaler: textScaler,
      )) {
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

  bool _fitsInLines({
    required InlineSpan span,
    required double maxWidth,
    required int maxLines,
    required TextDirection textDirection,
    required TextScaler textScaler,
  }) {
    final painter = TextPainter(
      text: span,
      textDirection: textDirection,
      textScaler: textScaler,
    )..layout(maxWidth: maxWidth);

    return painter.computeLineMetrics().length <= maxLines;
  }

  InlineSpan _buildCollapsedSpan(
    BuildContext context,
    _CollapsedLayout layout,
  ) {
    final bodyStyle = _bodyStyle(context);
    final linkStyle = _linkStyle(context);

    if (!layout.canExpand) {
      return TextSpan(text: widget.text, style: bodyStyle);
    }

    return TextSpan(
      style: bodyStyle,
      children: [
        TextSpan(text: layout.prefix),
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
        final collapsedLayout = _collapsedLayout(
          context: context,
          maxWidth: constraints.maxWidth,
        );

        final label = widget.label?.trim();
        final showLabel = label != null && label.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showLabel) ...[
              Text(label, style: widget.labelStyle),
              SizedBox(height: widget.labelGap),
            ],
            AnimatedSize(
              duration: _kExpandDuration,
              curve: _kExpandCurve,
              alignment: Alignment.topCenter,
              clipBehavior: Clip.none,
              child: Text.rich(
                _expanded
                    ? _buildExpandedSpan(context)
                    : _buildCollapsedSpan(context, collapsedLayout),
                textAlign: TextAlign.start,
                maxLines: _expanded ? null : widget.maxCollapsedLines,
              ),
            ),
          ],
        );
      },
    );
  }
}
