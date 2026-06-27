import 'package:chronoapp/features/homework/domain/models/homework_fragment.dart';
import 'package:chronoapp/features/homework/presentation/widgets/homework_fragment_chip.dart';
import 'package:flutter/material.dart';

/// Hält nur den aktiven (editierbaren) Text; Chips kommen aus [fragments].
class HomeworkSyntaxController extends TextEditingController {
  HomeworkSyntaxController({
    List<HomeworkFragment> fragments = const [],
    String activeText = '',
  }) : _fragments = List<HomeworkFragment>.from(fragments) {
    super.value = TextEditingValue(
      text: activeText,
      selection: TextSelection.collapsed(offset: activeText.length),
    );
  }

  List<HomeworkFragment> _fragments;

  List<HomeworkFragment> get fragments => List<HomeworkFragment>.unmodifiable(_fragments);

  void updateDocument({
    required List<HomeworkFragment> fragments,
    required String activeText,
  }) {
    _fragments = List<HomeworkFragment>.from(fragments);
    value = TextEditingValue(
      text: activeText,
      selection: TextSelection.collapsed(offset: activeText.length),
    );
  }

  @override
  set value(TextEditingValue newValue) {
    final text = newValue.text;
    super.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
      composing: TextRange.empty,
    );
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final children = <InlineSpan>[];

    for (final fragment in _fragments) {
      final chipFragment = _inlineChipFragment(fragment);
      children.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.only(right: 4, bottom: 1),
            child: HomeworkFragmentChip(fragment: chipFragment, compact: true),
          ),
        ),
      );
    }

    children.add(TextSpan(text: value.text, style: style));

    return TextSpan(style: style, children: children);
  }

  HomeworkFragment _inlineChipFragment(HomeworkFragment fragment) {
    if (fragment.kind != HomeworkFragmentKind.book) return fragment;
    if (fragment.fields['page'] != null) return fragment;

    final code = fragment.fields['code'] as String? ?? fragment.displayText;
    if (code == fragment.displayText) return fragment;

    return fragment.copyWith(displayText: code);
  }
}
