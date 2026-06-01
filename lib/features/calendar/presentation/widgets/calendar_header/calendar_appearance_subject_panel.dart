import 'package:chronoapp/features/calendar/domain/preview/calendar_appearance_config.dart';
import 'package:chronoapp/features/calendar/presentation/providers/subjects_providers.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/calendar_header/accent_picker_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Fach-Akzentfarbe (nur Color-Picker) — eingebettet oder im Erscheinungsbild-Sheet.
class CalendarAppearanceSubjectPanel extends ConsumerStatefulWidget {
  const CalendarAppearanceSubjectPanel({required this.config, super.key});

  final CalendarAppearanceBySubject config;

  @override
  ConsumerState<CalendarAppearanceSubjectPanel> createState() =>
      CalendarAppearanceSubjectPanelState();
}

class CalendarAppearanceSubjectPanelState
    extends ConsumerState<CalendarAppearanceSubjectPanel> {
  Color? _subjectAccentAtOpen;
  bool _hadSubjectOverrideAtOpen = false;

  @override
  void initState() {
    super.initState();
    final overrides =
        ref.read(subjectAccentOverridesProvider).value ??
        const <String, Color>{};
    _subjectAccentAtOpen = overrides[widget.config.subjectId];
    _hadSubjectOverrideAtOpen = _subjectAccentAtOpen != null;
  }

  Future<void> discardChanges() async {
    HapticFeedback.mediumImpact();
    await _restoreSubjectAccentAtOpen();
  }

  void confirmChanges() {
    HapticFeedback.mediumImpact();
  }

  Future<void> _restoreSubjectAccentAtOpen() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final repo = ref.read(profileCalendarPreferencesRepositoryProvider);
    if (!_hadSubjectOverrideAtOpen) {
      await repo.clearSubjectAccent(
        userId: userId,
        subjectId: widget.config.subjectId,
      );
    } else {
      await repo.setSubjectAccent(
        userId: userId,
        subjectId: widget.config.subjectId,
        color: _subjectAccentAtOpen!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjectOverrides =
        ref.watch(subjectAccentOverridesProvider).value ??
        const <String, Color>{};
    final baseEntry = widget.config.previewEntry;
    final currentColor =
        subjectOverrides[widget.config.subjectId] ?? baseEntry.accentColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: SubjectAccentColorPickerSection(
        subjectId: widget.config.subjectId,
        currentColor: currentColor,
      ),
    );
  }
}

class SubjectAccentColorPickerSection extends ConsumerWidget {
  const SubjectAccentColorPickerSection({
    required this.subjectId,
    required this.currentColor,
    super.key,
  });

  final String subjectId;
  final Color currentColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: BlockPicker(
        key: ValueKey('subject-$subjectId-${currentColor.toARGB32()}'),
        pickerColor: currentColor,
        availableColors: kCalendarAccentPickerColors,
        layoutBuilder: calendarAccentBlockPickerLayout,
        itemBuilder: calendarAccentBlockPickerItem,
        onColorChanged: (color) {
          HapticFeedback.selectionClick();
          final userId = Supabase.instance.client.auth.currentUser?.id;
          if (userId == null) return;
          ref
              .read(profileCalendarPreferencesRepositoryProvider)
              .setSubjectAccent(
                userId: userId,
                subjectId: subjectId,
                color: color,
              );
        },
      ),
    );
  }
}

Widget calendarAccentBlockPickerLayout(
  BuildContext context,
  List<Color> colors,
  PickerItem child,
) {
  return SizedBox(
    width: double.infinity,
    child: Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: [for (final color in colors) child(color)],
    ),
  );
}

Widget calendarAccentBlockPickerItem(
  Color color,
  bool isCurrentColor,
  void Function() changeColor,
) {
  return Container(
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(6),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.4),
          offset: const Offset(0, 1),
          blurRadius: 4,
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: changeColor,
        child: SizedBox(
          width: 32,
          height: 32,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 160),
            opacity: isCurrentColor ? 1 : 0,
            child: const Icon(Icons.check, color: Colors.white, size: 18),
          ),
        ),
      ),
    ),
  );
}
