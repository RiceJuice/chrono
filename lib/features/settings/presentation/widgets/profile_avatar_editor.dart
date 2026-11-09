import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/widgets/app_modal_sheet.dart';
import '../../data/models/profile_avatar.dart';
import '../../data/models/profile_snapshot.dart';
import '../../data/profile_avatar_repository.dart';
import '../providers/profile_avatar_provider.dart';
import 'profile_avatar.dart';
import 'profile_appearance.dart';

const profileAvatarColors = <(String, int)>[
  ('Blau', 0xff3478c7),
  ('Indigo', 0xff5856a8),
  ('Violett', 0xff9463b5),
  ('Rosa', 0xffbd577c),
  ('Koralle', 0xffc65c50),
  ('Orange', 0xffb77731),
  ('Grün', 0xff43846b),
  ('Petrol', 0xff397f8b),
  ('Grau', 0xff717783),
  ('Sand', 0xffcbbba0),
];

class ProfileAvatarEditor extends ConsumerStatefulWidget {
  const ProfileAvatarEditor({
    super.key,
    required this.profile,
    required this.initial,
    this.initialPhoto,
  });

  final ProfileSnapshot? profile;
  final ProfileAvatar initial;
  final Uint8List? initialPhoto;

  @override
  ConsumerState<ProfileAvatarEditor> createState() =>
      _ProfileAvatarEditorState();
}

class _ProfileAvatarEditorState extends ConsumerState<ProfileAvatarEditor> {
  late bool _usePhoto = widget.initial.path != null;
  late int? _color = widget.initial.color;
  Uint8List? _newPhoto;
  bool _saving = false;
  bool _picking = false;
  String? _error;

  Future<void> _pickPhoto() async {
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1536,
        maxHeight: 1536,
        imageQuality: 90,
        requestFullMetadata: false,
      );
      if (picked == null || !mounted) return;
      if (await picked.length() > 20 * 1024 * 1024) {
        throw const FormatException('Bitte ein Foto unter 20 MB auswählen.');
      }
      final bytes = await picked.readAsBytes();
      final photo = await compute(prepareProfilePhoto, bytes);
      if (!mounted) return;
      setState(() {
        _newPhoto = photo;
        _usePhoto = true;
      });
      HapticFeedback.selectionClick();
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _error = error is FormatException
            ? error.message.toString()
            : 'Foto konnte nicht geöffnet werden. Bitte den Fotozugriff prüfen oder ein anderes Bild auswählen.',
      );
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(profileAvatarRepositoryProvider)
          .save(color: _color, photo: _newPhoto, usePhoto: _usePhoto);
      if (!mounted) return;
      // Allow PopScope to rebuild before closing the successfully saved sheet.
      setState(() => _saving = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error =
            'Profilbild konnte nicht gespeichert werden. Bitte deine Verbindung prüfen und erneut versuchen.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final busy = _saving || _picking;
    final loadedPhoto =
        widget.initialPhoto ??
        (widget.initial.path == null
            ? null
            : ref.watch(profileAvatarPhotoProvider).asData?.value);
    final photo = _newPhoto ?? loadedPhoto;
    return PopScope(
      canPop: !_saving,
      child: AppModalSheetChrome(
        color: isNativeAppleProfile
            ? (theme.brightness == Brightness.dark
                  ? const Color(0xff1c1c1e)
                  : const Color(0xfff2f2f7))
            : null,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              24,
              12,
              24,
              24 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cancel = ProfileSheetIconButton(
                      confirm: false,
                      onPressed: busy
                          ? null
                          : () => Navigator.of(context).pop(),
                    );
                    final title = Text(
                      'Profilbild',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    );
                    final done = _saving
                        ? const SizedBox.square(
                            dimension: 52,
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : ProfileSheetIconButton(
                            confirm: true,
                            onPressed: busy ? null : _save,
                          );
                    if (constraints.maxWidth < 300 ||
                        MediaQuery.textScalerOf(context).scale(16) > 20) {
                      return Column(
                        children: [
                          title,
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(child: cancel),
                              Expanded(child: done),
                            ],
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: cancel,
                          ),
                        ),
                        title,
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: done,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                ProfileAvatarView(
                  profile: widget.profile,
                  radius: 64,
                  color: _color,
                  photo: _usePhoto ? photo : null,
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _modeChoice(
                      label: 'Initialen',
                      selected: !_usePhoto,
                      busy: busy,
                      onTap: () => _selectMode(false, photo),
                      child: ProfileAvatarView(
                        profile: widget.profile,
                        radius: 26,
                        color: _color,
                      ),
                    ),
                    const SizedBox(width: 20),
                    _modeChoice(
                      label: 'Foto',
                      selected: _usePhoto,
                      busy: busy,
                      onTap: () => _selectMode(true, photo),
                      child: photo != null
                          ? ProfileAvatarView(
                              profile: widget.profile,
                              radius: 26,
                              photo: photo,
                            )
                          : CircleAvatar(
                              radius: 26,
                              backgroundColor: scheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.add_photo_alternate_outlined,
                                color: scheme.onSurfaceVariant,
                                size: 27,
                              ),
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_usePhoto) ...[
                  if (_picking)
                    const SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    ProfileActionButton(
                      onPressed: busy ? null : _pickPhoto,
                      prominent: true,
                      label: photo == null
                          ? 'Foto auswählen'
                          : 'Anderes Foto auswählen',
                    ),
                  const SizedBox(height: 12),
                  Text(
                    'Dein Foto wird als runder Ausschnitt angezeigt.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ] else ...[
                  Text('Hintergrundfarbe', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _colorButton(
                        context,
                        'Standard',
                        null,
                        profileDefaultBackground(context),
                        busy,
                      ),
                      for (final (label, color) in profileAvatarColors)
                        _colorButton(context, label, color, Color(color), busy),
                    ],
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 18),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.error,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _selectMode(bool usePhoto, Uint8List? photo) {
    HapticFeedback.selectionClick();
    if (usePhoto && photo == null) {
      _pickPhoto();
      return;
    }
    setState(() {
      _usePhoto = usePhoto;
      _error = null;
    });
  }

  Widget _modeChoice({
    required String label,
    required bool selected,
    required bool busy,
    required VoidCallback onTap,
    required Widget child,
  }) {
    const accent = profileSelectionBlue;
    return Semantics(
      label: label,
      button: true,
      selected: selected,
      enabled: !busy,
      child: Tooltip(
        message: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: busy ? null : onTap,
            borderRadius: BorderRadius.circular(24),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected
                    ? accent.withValues(alpha: 0.16)
                    : Theme.of(context).colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: selected ? accent : Colors.transparent,
                  width: 3,
                ),
              ),
              child: ExcludeSemantics(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    child,
                    if (selected)
                      Positioned(
                        right: -6,
                        bottom: -6,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: accent, width: 2),
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: accent,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _colorButton(
    BuildContext context,
    String label,
    int? value,
    Color color,
    bool busy,
  ) {
    final selected = _color == value;
    return Semantics(
      label: label,
      selected: selected,
      button: true,
      child: Tooltip(
        message: label,
        child: SizedBox.square(
          dimension: 46,
          child: Material(
            color: color,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: busy
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      setState(() => _color = value);
                    },
              child: selected
                  ? Icon(
                      Icons.check_rounded,
                      color: color.computeLuminance() > 0.45
                          ? Colors.black87
                          : Colors.white,
                      size: 23,
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
