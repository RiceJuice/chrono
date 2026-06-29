import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/features/homework/domain/homework_syntax_parser.dart';
import 'package:chronoapp/features/homework/domain/models/homework_fragment.dart';
import 'package:chronoapp/features/homework/domain/models/homework_syntax_suggestion.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

const double kHomeworkSuggestionItemHeight = 44;

class HomeworkSuggestionOverlay extends StatelessWidget {
  const HomeworkSuggestionOverlay({
    super.key,
    required this.primarySuggestion,
    required this.onAddCustom,
    this.onPrimaryTap,
    this.width = 280,
  });

  final HomeworkSyntaxSuggestion? primarySuggestion;
  final VoidCallback? onPrimaryTap;
  final VoidCallback onAddCustom;
  final double width;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      elevation: 6,
      color: scheme.surfaceContainerHighest,
      shape: AppSquircle.shape(AppRadius.l),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (primarySuggestion != null)
              SizedBox(
                height: kHomeworkSuggestionItemHeight,
                child: ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: Text(
                    '${primarySuggestion!.shorthand} — ${primarySuggestion!.label}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  onTap: onPrimaryTap,
                ),
              ),
            SizedBox(
              height: kHomeworkSuggestionItemHeight,
              child: ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                leading: Icon(
                  PhosphorIcons.plus(PhosphorIconsStyle.bold),
                  color: scheme.primary,
                  size: 20,
                ),
                title: Text(
                  'Eigene Abkürzung hinzufügen',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                onTap: onAddCustom,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeworkAddSuggestionSheet extends StatefulWidget {
  const HomeworkAddSuggestionSheet({super.key});

  static Future<({String label, String shorthand})?> show(BuildContext context) {
    return showModalBottomSheet<({String label, String shorthand})?>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const HomeworkAddSuggestionSheet(),
    );
  }

  @override
  State<HomeworkAddSuggestionSheet> createState() =>
      _HomeworkAddSuggestionSheetState();
}

class _HomeworkAddSuggestionSheetState extends State<HomeworkAddSuggestionSheet> {
  final _labelController = TextEditingController();
  final _shorthandController = TextEditingController();

  @override
  void dispose() {
    _labelController.dispose();
    _shorthandController.dispose();
    super.dispose();
  }

  void _submit() {
    final label = _labelController.text.trim();
    final shorthand = _shorthandController.text.trim();
    if (label.isEmpty || shorthand.isEmpty) return;
    Navigator.of(context).pop((label: label, shorthand: shorthand));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.l,
        AppSpacing.xl,
        AppSpacing.l + bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Eigene Abkürzung',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.m),
          TextField(
            controller: _labelController,
            decoration: const InputDecoration(labelText: 'Bezeichnung'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.s),
          TextField(
            controller: _shorthandController,
            decoration: const InputDecoration(labelText: 'Abkürzung'),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: AppSpacing.l),
          FilledButton(
            onPressed: _submit,
            child: const Text('Hinzufügen'),
          ),
        ],
      ),
    );
  }
}

void applySuggestionToLine({
  required HomeworkSyntaxParser parser,
  required List<HomeworkFragment> committedFragments,
  required String activeText,
  required HomeworkSyntaxSuggestion suggestion,
  required void Function(List<HomeworkFragment> fragments, String activeText) onChanged,
}) {
  final committed = parser.commitActiveText(
    committedFragments: committedFragments,
    activeText: '${suggestion.shorthand} ',
  );

  if (committed != null) {
    onChanged(committed.committedFragments, committed.activeText);
    return;
  }

  final fragment = HomeworkFragment(
    kind: switch (suggestion.category) {
      'book' => HomeworkFragmentKind.book,
      'worksheet' => HomeworkFragmentKind.worksheet,
      'notebook' => HomeworkFragmentKind.notebook,
      'online' => HomeworkFragmentKind.online,
      _ => HomeworkFragmentKind.format,
    },
    canonicalKey: '${suggestion.category}:${suggestion.shorthand.toLowerCase()}',
    displayText: suggestion.shorthand,
    chipColorKey: suggestion.chipColorKey,
    fields: {'code': suggestion.shorthand},
  );
  onChanged([...committedFragments, fragment], '');
}
