import 'package:chronoapp/features/homework/domain/models/homework_fragment.dart';
import 'package:chronoapp/features/homework/presentation/widgets/homework_fragment_chip.dart';
import 'package:flutter/material.dart';

/// Hält nur den aktiven (editierbaren) Text; Chips kommen aus [fragments].
class HomeworkSyntaxController extends TextEditingController {
  HomeworkSyntaxController({
    List<HomeworkFragment> fragments = const [],
    String activeText = '',
  }) : _fragments = List<HomeworkFragment>.from(fragments) {
    text = activeText;
  }

  List<HomeworkFragment> _fragments;

  List<HomeworkFragment> get fragments => List<HomeworkFragment>.unmodifiable(_fragments);

  void updateDocument({
    required List<HomeworkFragment> fragments,
    required String activeText,
  }) {
    _fragments = List<HomeworkFragment>.from(fragments);
    if (text != activeText) {
      value = TextEditingValue(
        text: activeText,
        selection: TextSelection.collapsed(offset: activeText.length),
      );
    } else {
      notifyListeners();
    }
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final children = <InlineSpan>[];

    for (final fragment in _fragments) {
      children.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.only(right: 4, bottom: 1),
            child: HomeworkFragmentChip(fragment: fragment, compact: true),
          ),
        ),
      );
    }

    children.add(TextSpan(text: value.text, style: style));

    return TextSpan(style: style, children: children);
  }
}
