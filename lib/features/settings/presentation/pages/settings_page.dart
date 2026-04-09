import 'package:chronoapp/core/database/backend_connector.dart';
import 'package:chronoapp/core/database/backend_enums.dart';
import 'package:chronoapp/core/widgets/app_toast.dart';
import 'package:chronoapp/core/widgets/main_navigation_bar.dart';
import 'package:chronoapp/features/login/presentation/providers/auth_repository_provider.dart';
import 'package:chronoapp/features/login/presentation/providers/klassen_provider.dart';
import 'package:chronoapp/features/login/data/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_profile_providers.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _saving = false;

  static const _roleOptions = <String>[
    'Schüler',
    'Elternteil',
  ];
  static const _voiceOptions = <String>[
    'Sopran',
    'Alt',
    'Tenor',
    'Bass',
  ];
  static final _dietOptions = <String>[
    BackendDiet.noRestriction.displayLabel,
    BackendDiet.vegetarian.displayLabel,
  ];

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(syncedProfileProvider);
    final classesAsync = ref.watch(availableClassesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Center(child: const Text('Einstellungen')),
      ),
      bottomNavigationBar: const MainNavigationBar(),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          ...profileAsync.when(
            data: (profile) => [
              const _SectionHeader('Persönlich', top: 4),
              _EditableInfoTile(
                label: 'Vorname',
                value: profile?.firstName,
                icon: Icons.person_outline,
                enabled: !_saving,
                onTap: () => _editTextField(
                  title: 'Vorname bearbeiten',
                  initialValue: profile?.firstName,
                  fieldLabel: 'Vorname',
                  onSave: (value) => _updateProfile(
                    firstName: value,
                  ),
                ),
              ),
              _EditableInfoTile(
                label: 'Nachname',
                value: profile?.lastName,
                icon: Icons.badge_outlined,
                enabled: !_saving,
                onTap: () => _editTextField(
                  title: 'Nachname bearbeiten',
                  initialValue: profile?.lastName,
                  fieldLabel: 'Nachname',
                  onSave: (value) => _updateProfile(
                    lastName: value,
                  ),
                ),
              ),
              const _SectionHeader('Schule'),
              _EditableInfoTile(
                label: 'Rolle',
                value: profile?.role,
                icon: Icons.groups_outlined,
                enabled: !_saving,
                onTap: () => _editChoiceField(
                  title: 'Rolle auswählen',
                  initialValue: profile?.role,
                  options: _roleOptions,
                  onSave: (value) => _updateProfile(
                    role: value,
                  ),
                ),
              ),
              _EditableInfoTile(
                label: 'Klasse',
                value: profile?.className,
                icon: Icons.school_outlined,
                enabled: !_saving,
                onTap: () => _editChoiceField(
                  title: 'Klasse auswählen',
                  initialValue: profile?.className,
                  options: classesAsync.maybeWhen(
                    data: (classes) => classes,
                    orElse: () => const [],
                  ),
                  onSave: (value) => _updateProfile(
                    className: value,
                  ),
                ),
              ),
              const _SectionHeader('Chor'),
              _EditableInfoTile(
                label: 'Chor',
                value: _choirDisplayLabel(profile?.choir),
                icon: Icons.church_outlined,
                enabled: !_saving,
                onTap: () => _editChoiceField(
                  title: 'Chor auswählen',
                  initialValue: _choirDisplayLabel(profile?.choir),
                  options: BackendChoir.values
                      .where((item) => item != BackendChoir.unknown)
                      .map((item) => item.displayLabel)
                      .toList(),
                  onSave: (value) => _updateProfile(
                    choir: value,
                  ),
                ),
              ),
              _EditableInfoTile(
                label: 'Stimme',
                value: profile?.voice,
                icon: Icons.record_voice_over_outlined,
                enabled: !_saving,
                onTap: () => _editChoiceField(
                  title: 'Stimme auswählen',
                  initialValue: profile?.voice,
                  options: _voiceOptions,
                  onSave: (value) => _updateProfile(
                    voice: value,
                  ),
                ),
              ),
              const _SectionHeader('Sonstiges'),
              _EditableInfoTile(
                label: 'Ernährung',
                value: _dietDisplayLabel(profile?.diet),
                icon: Icons.restaurant_outlined,
                enabled: !_saving,
                onTap: () => _editChoiceField(
                  title: 'Ernährung auswählen',
                  initialValue: _dietDisplayLabel(profile?.diet),
                  options: _dietOptions,
                  onSave: (value) => _updateProfile(
                    diet: value,
                  ),
                ),
              ),
            ],
            loading: () => const [
              ListTile(
                leading: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                title: Text('Profil wird geladen...'),
              ),
            ],
            error: (error, _) => [
              ListTile(
                leading: const Icon(Icons.error_outline),
                title: const Text('Profil konnte nicht geladen werden'),
                subtitle: Text(error.toString()),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListTile(
            title: Text(
              'Abmelden',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            leading: Icon(
              Icons.logout,
              color: Theme.of(context).colorScheme.error,
            ),
            onTap: () async {
              await BackendConnector.logout(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _editTextField({
    required String title,
    required String? initialValue,
    required String fieldLabel,
    required Future<void> Function(String) onSave,
  }) async {
    var draftValue = (initialValue ?? '').trim();
    final value = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextFormField(
            initialValue: draftValue,
            autofocus: true,
            decoration: InputDecoration(labelText: fieldLabel),
            onChanged: (value) => draftValue = value.trim(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(draftValue),
              child: const Text('Speichern'),
            ),
          ],
        );
      },
    );

    if (value == null) return;
    await onSave(value);
  }

  Future<void> _editChoiceField({
    required String title,
    required String? initialValue,
    required List<String> options,
    required Future<void> Function(String) onSave,
  }) async {
    if (options.isEmpty) {
      if (!mounted) return;
      _showErrorSnackBar('Keine Optionen verfügbar.');
      return;
    }

    final value = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            children: [
              ListTile(
                title: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ...options.map(
                (option) => ListTile(
                  title: Text(option),
                  trailing: option == initialValue
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => Navigator.of(context).pop(option),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (value == null) return;
    await onSave(value);
  }

  Future<void> _updateProfile({
    String? firstName,
    String? lastName,
    String? className,
    String? voice,
    String? diet,
    String? role,
    String? choir,
  }) async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      await ref.read(authRepositoryProvider).updateProfile(
            firstName: firstName,
            lastName: lastName,
            className: className,
            voice: voice,
            diet: diet,
            role: role,
            choir: choir,
          );
    } on AuthRepositoryException catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(e.message);
    } catch (_) {
      if (!mounted) return;
      _showErrorSnackBar(
        'Änderung konnte nicht gespeichert werden. Bitte erneut versuchen.',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showErrorSnackBar(String message) {
    showAppToast(context, message, kind: AppToastKind.error);
  }
}

/// Zeigt [BackendChoir]-Labels; unbekannte Rohwerte werden durchgereicht.
String? _choirDisplayLabel(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final choir = BackendChoirCodec.fromBackend(raw);
  if (choir != BackendChoir.unknown) return choir.displayLabel;
  return raw.trim();
}

/// Zeigt [BackendDiet]-Labels; unbekannte Rohwerte werden durchgereicht.
String? _dietDisplayLabel(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final diet = BackendDietCodec.fromBackend(raw);
  if (diet != BackendDiet.unknown) return diet.displayLabel;
  return raw.trim();
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, {this.top = 20});

  final String title;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, top, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _EditableInfoTile extends StatelessWidget {
  const _EditableInfoTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final String? value;
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final text = (value ?? '').trim();
    return ListTile(
      enabled: enabled,
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(text.isEmpty ? 'Nicht gesetzt' : text),
      trailing: const Icon(Icons.edit_outlined),
      onTap: enabled ? onTap : null,
    );
  }
}
