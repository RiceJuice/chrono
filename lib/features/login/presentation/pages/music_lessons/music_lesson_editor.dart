import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../music_lessons/domain/music_lesson_schedule.dart';
import 'music_lesson_time_picker.dart';

const _instruments = [
  'Akkordeon',
  'Blockflöte',
  'Bratsche',
  'Cello',
  'E-Bass',
  'E-Gitarre',
  'Fagott',
  'Geige',
  'Gitarre',
  'Harfe',
  'Horn',
  'Klarinette',
  'Klavier',
  'Kontrabass',
  'Oboe',
  'Orgel',
  'Posaune',
  'Querflöte',
  'Saxofon',
  'Trompete',
];

extension MusicLessonEditorLabels on MusicLessonKind {
  String get editorTitle =>
      this == MusicLessonKind.voice ? 'Stimmbildung' : 'Instrumentalunterricht';

  String get extendedLabel => this == MusicLessonKind.voice
      ? 'Additum (45 Min.)'
      : 'Doppelstunde (45 Min.)';
}

String formatMusicLessonTime(int minute) =>
    '${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}';

typedef MusicLessonEdit = ({MusicLesson? lesson});

Future<MusicLessonEdit?> showMusicLessonEditor(
  BuildContext context,
  MusicLessonKind kind,
  MusicLesson? saved,
) async {
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS)) {
    try {
      final row = await const MethodChannel('chrono/music_lesson_editor')
          .invokeMapMethod<String, dynamic>('present', {
            'title': kind.editorTitle,
            'extendedLabel': kind.extendedLabel,
            'standardMinutes': kind.standardMinutes,
            'hasInstrument': kind == MusicLessonKind.instrument,
            'instruments': _instruments,
            'weekday': saved?.weekday,
            'startMinute': saved?.startMinute,
            'instrument': saved?.instrument,
            'teacher': saved?.teacher,
            'extended': saved?.extended ?? false,
          });
      if (row == null) return null;
      if (row['remove'] == true) return (lesson: null);
      return (
        lesson: MusicLesson(
          kind: kind,
          weekday: row['weekday'] as int,
          startMinute: row['startMinute'] as int,
          instrument: _optionalText(row['instrument'] as String?),
          teacher: _optionalText(row['teacher'] as String?),
          extended: row['extended'] == true,
        ),
      );
    } on MissingPluginException {
      // Builds without the Apple editor still have the Flutter form.
    } on PlatformException {
      // The app may not currently have a window that can present a native sheet.
    }
  }

  if (!context.mounted) return null;
  return showModalBottomSheet<MusicLessonEdit>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 520),
    builder: (context) => _FlutterLessonEditor(kind: kind, saved: saved),
  );
}

String? _optionalText(String? text) {
  final trimmed = text?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}

class _FlutterLessonEditor extends StatefulWidget {
  const _FlutterLessonEditor({required this.kind, this.saved});

  final MusicLessonKind kind;
  final MusicLesson? saved;

  @override
  State<_FlutterLessonEditor> createState() => _FlutterLessonEditorState();
}

class _FlutterLessonEditorState extends State<_FlutterLessonEditor> {
  final _form = GlobalKey<FormState>();
  final _instrumentFocus = FocusNode();
  late final _instrument = TextEditingController(
    text: widget.saved?.instrument,
  );
  late final _teacher = TextEditingController(text: widget.saved?.teacher);
  late int? _weekday = widget.saved?.weekday;
  late int? _startMinute = widget.saved?.startMinute;
  late bool _extended = widget.saved?.extended ?? false;

  @override
  void dispose() {
    _instrumentFocus.dispose();
    _instrument.dispose();
    _teacher.dispose();
    super.dispose();
  }

  Future<void> _chooseTime(FormFieldState<int> field) async {
    FocusScope.of(context).unfocus();
    final minutes = await showMusicLessonTimePicker(
      context,
      _startMinute ?? 14 * 60,
    );
    if (!mounted || !field.mounted || minutes == null) return;
    setState(() => _startMinute = minutes);
    field.didChange(minutes);
  }

  void _accept() {
    if (!_form.currentState!.validate()) return;
    Navigator.pop(context, (
      lesson: MusicLesson(
        kind: widget.kind,
        weekday: _weekday!,
        startMinute: _startMinute!,
        instrument: _optionalText(_instrument.text),
        teacher: _optionalText(_teacher.text),
        extended: _extended,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasInstrument = widget.kind == MusicLessonKind.instrument;
    final duration = _extended ? 45 : widget.kind.standardMinutes;
    final time = _startMinute;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.kind.editorTitle, style: theme.textTheme.titleLarge),
              const SizedBox(height: 18),
              FormField<int>(
                initialValue: _weekday,
                validator: (value) =>
                    value == null ? 'Bitte einen Wochentag wählen.' : null,
                builder: (field) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Wochentag'),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 7,
                      children: [
                        for (final (index, label) in [
                          'Mo',
                          'Di',
                          'Mi',
                          'Do',
                          'Fr',
                        ].indexed)
                          ChoiceChip(
                            label: Text(label),
                            showCheckmark: false,
                            selected: _weekday == index + 1,
                            onSelected: (_) {
                              setState(() => _weekday = index + 1);
                              field.didChange(index + 1);
                            },
                          ),
                      ],
                    ),
                    if (field.errorText case final error?)
                      Text(
                        error,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FormField<int>(
                initialValue: time,
                validator: (value) => value == null
                    ? 'Bitte die Uhrzeit wählen.'
                    : value + duration > 1440
                    ? 'Der Termin muss am selben Tag enden.'
                    : null,
                builder: (field) => OutlinedButton.icon(
                  icon: const Icon(Icons.schedule_rounded),
                  label: Text(
                    field.errorText ??
                        (time == null
                            ? 'Beginn wählen'
                            : '${formatMusicLessonTime(time)} Uhr'),
                  ),
                  style: field.hasError
                      ? OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                        )
                      : null,
                  onPressed: () => _chooseTime(field),
                ),
              ),
              if (hasInstrument) ...[
                const SizedBox(height: 12),
                Autocomplete<String>(
                  textEditingController: _instrument,
                  focusNode: _instrumentFocus,
                  optionsViewOpenDirection: OptionsViewOpenDirection.mostSpace,
                  optionsBuilder: (value) {
                    final prefix = value.text.trim().toLowerCase();
                    return prefix.isEmpty
                        ? const <String>[]
                        : _instruments.where((name) {
                            final normalized = name.toLowerCase();
                            return normalized != prefix &&
                                normalized.startsWith(prefix);
                          });
                  },
                  fieldViewBuilder: (context, controller, focusNode, submit) =>
                      TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        maxLength: 80,
                        textCapitalization: TextCapitalization.words,
                        onFieldSubmitted: (_) => submit(),
                        decoration: const InputDecoration(
                          labelText: 'Instrument',
                          hintText: 'z. B. Klavier',
                          counterText: '',
                        ),
                        validator: (value) => _optionalText(value) == null
                            ? 'Bitte ein Instrument eintragen.'
                            : null,
                      ),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _teacher,
                maxLength: 100,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Lehrkraft (optional)',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 6),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(widget.kind.extendedLabel),
                value: _extended,
                onChanged: (value) =>
                    setState(() => _extended = value ?? false),
              ),
              const SizedBox(height: 12),
              FilledButton(onPressed: _accept, child: const Text('Übernehmen')),
              if (widget.saved != null)
                TextButton(
                  onPressed: () =>
                      Navigator.pop(context, (lesson: null) as MusicLessonEdit),
                  child: const Text('Termin entfernen'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
