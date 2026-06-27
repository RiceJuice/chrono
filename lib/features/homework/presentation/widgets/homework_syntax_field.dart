import 'package:chronoapp/features/homework/domain/homework_syntax_parser.dart';
import 'package:chronoapp/features/homework/domain/models/homework_fragment.dart';
import 'package:chronoapp/features/homework/domain/models/homework_syntax_suggestion.dart';
import 'package:chronoapp/features/homework/presentation/widgets/homework_syntax_controller.dart';
import 'package:chronoapp/features/homework/presentation/widgets/homework_suggestion_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

class HomeworkSyntaxField extends StatefulWidget {
  const HomeworkSyntaxField({
    super.key,
    required this.parser,
    required this.suggestions,
    required this.committedFragments,
    required this.activeText,
    required this.onChanged,
    this.hintText = 'Hausaufgabe (z. B. BS 117/3)',
    this.onAddCustomSuggestion,
  });

  final HomeworkSyntaxParser parser;
  final List<HomeworkSyntaxSuggestion> suggestions;
  final List<HomeworkFragment> committedFragments;
  final String activeText;
  final void Function(List<HomeworkFragment> fragments, String activeText) onChanged;
  final String hintText;
  final Future<void> Function(String label, String shorthand)? onAddCustomSuggestion;

  @override
  State<HomeworkSyntaxField> createState() => _HomeworkSyntaxFieldState();
}

class _HomeworkSyntaxFieldState extends State<HomeworkSyntaxField> {
  final _layerLink = LayerLink();
  final _focusNode = FocusNode();
  late HomeworkSyntaxController _controller;
  OverlayEntry? _overlayEntry;
  bool _overlayUpdateScheduled = false;
  bool _syncingFromParent = false;

  @override
  void initState() {
    super.initState();
    _controller = HomeworkSyntaxController(
      fragments: widget.committedFragments,
      activeText: widget.activeText,
    );
    _focusNode.addListener(_handleFocusChange);
    _controller.addListener(_handleTextChange);
  }

  @override
  void didUpdateWidget(covariant HomeworkSyntaxField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.committedFragments != widget.committedFragments ||
        oldWidget.activeText != widget.activeText) {
      _syncingFromParent = true;
      _controller.updateDocument(
        fragments: widget.committedFragments,
        activeText: widget.activeText,
      );
      _syncingFromParent = false;
    }
    if (oldWidget.suggestions != widget.suggestions) {
      _scheduleOverlayUpdate();
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    _focusNode.removeListener(_handleFocusChange);
    _controller.removeListener(_handleTextChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      _scheduleOverlayUpdate();
    } else {
      _removeOverlay();
      _tryCommit();
    }
  }

  void _handleTextChange() {
    if (_syncingFromParent) return;

    final text = _controller.text;
    widget.onChanged(_controller.fragments, text);

    if (text.endsWith(' ')) {
      _tryCommit();
    }

    _scheduleOverlayUpdate();
  }

  void _applyDocument({
    required List<HomeworkFragment> fragments,
    required String activeText,
  }) {
    _syncingFromParent = true;
    _controller.updateDocument(fragments: fragments, activeText: activeText);
    _syncingFromParent = false;
    widget.onChanged(fragments, activeText);
    _scheduleOverlayUpdate();
  }

  void _tryCommit() {
    final text = _controller.text;
    final result = widget.parser.commitActiveText(
      committedFragments: _controller.fragments,
      activeText: text,
    );
    if (result != null) {
      _applyDocument(
        fragments: result.committedFragments,
        activeText: result.activeText,
      );
      return;
    }

    if (!text.endsWith(' ')) return;

    final token = text.trim();
    if (token.isEmpty) {
      _applyDocument(fragments: _controller.fragments, activeText: '');
      return;
    }

    final first = widget.parser.firstSuggestionForToken(
      context: _parsedLine.context,
      token: token,
    );
    if (first != null) {
      _applyFirstSuggestion(first);
      return;
    }

    // Ungültiger Token — Leerzeichen verwerfen.
    _applyDocument(fragments: _controller.fragments, activeText: token);
  }

  void _applyFirstSuggestion(HomeworkSyntaxSuggestion suggestion) {
    applySuggestionToLine(
      parser: widget.parser,
      committedFragments: _controller.fragments,
      activeText: _controller.text,
      suggestion: suggestion,
      onChanged: (fragments, activeText) {
        _applyDocument(fragments: fragments, activeText: activeText);
      },
    );
  }

  ParsedHomeworkLine get _parsedLine => widget.parser.parse(
        committedFragments: _controller.fragments,
        activeText: _controller.text,
      );

  List<HomeworkSyntaxSuggestion> get _filteredSuggestions {
    return widget.parser.suggestionsForContext(
      context: _parsedLine.context,
      activeText: _controller.text,
    );
  }

  HomeworkSyntaxSuggestion? get _primarySuggestion {
    final filtered = _filteredSuggestions;
    if (filtered.isEmpty) return null;
    return filtered.first;
  }

  void _scheduleOverlayUpdate() {
    if (_overlayUpdateScheduled) return;
    _overlayUpdateScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _overlayUpdateScheduled = false;
      if (!mounted) return;
      _updateOverlay();
    });
  }

  void _showOverlay() {
    if (!_focusNode.hasFocus || !mounted) return;

    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) {
        final primary = _primarySuggestion;
        final showOverlay =
            primary != null || _parsedLine.context == HomeworkParseContext.start;
        if (!showOverlay) return const SizedBox.shrink();

        return Positioned(
          width: 280,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 48),
            child: HomeworkSuggestionOverlay(
              primarySuggestion: primary,
              onAddCustom: _onAddCustom,
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _updateOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
    } else if (_focusNode.hasFocus) {
      _showOverlay();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _onAddCustom() async {
    final result = await HomeworkAddSuggestionSheet.show(context);
    if (result == null) return;
    await widget.onAddCustomSuggestion?.call(result.label, result.shorthand);
    _scheduleOverlayUpdate();
  }

  List<TextInputFormatter> get _inputFormatters {
    return switch (_parsedLine.context) {
      HomeworkParseContext.afterBook => [
          FilteringTextInputFormatter.allow(RegExp(r'[\d/ ]')),
        ],
      HomeworkParseContext.afterPage => [
          FilteringTextInputFormatter.allow(RegExp(r'[\d/ ]')),
        ],
      _ => const [],
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final showHint = _controller.fragments.isEmpty && _controller.text.isEmpty;

    return CompositedTransformTarget(
      link: _layerLink,
      child: Focus(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              _controller.text.isEmpty &&
              _controller.fragments.isNotEmpty) {
            final next = _controller.fragments.sublist(
              0,
              _controller.fragments.length - 1,
            );
            _applyDocument(fragments: next, activeText: '');
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          minLines: 1,
          maxLines: 4,
          style: Theme.of(context).textTheme.bodyLarge,
          inputFormatters: _inputFormatters,
          decoration: InputDecoration(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            isDense: true,
            contentPadding: EdgeInsets.zero,
            hintText: showHint ? widget.hintText : null,
            hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          onSubmitted: (_) => _tryCommit(),
        ),
      ),
    );
  }
}

List<HomeworkFragment> homeworkFragmentsFromField({
  required HomeworkSyntaxParser parser,
  required List<HomeworkFragment> committedFragments,
  required String activeText,
}) {
  if (activeText.trim().isEmpty) return committedFragments;
  final line = [
    ...committedFragments.map((f) => f.displayText),
    activeText.trim(),
  ].join(' ');
  return parser.parseCompleteLine(line);
}
