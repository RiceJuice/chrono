import 'package:chronoapp/core/widgets/app_modal_sheet.dart';
import 'package:chronoapp/core/widgets/app_toast.dart';
import 'package:chronoapp/features/login/data/auth_repository.dart';
import 'package:chronoapp/features/login/domain/models/login_flow_step.dart';
import 'package:chronoapp/features/login/presentation/providers/auth_repository_provider.dart';
import 'package:chronoapp/features/login/presentation/providers/profile_gate_provider.dart';
import 'package:chronoapp/features/settings/presentation/providers/settings_profile_providers.dart';
import 'package:chronoapp/features/login/presentation/providers/login_step_scaffold.dart';
import 'package:chronoapp/features/login/presentation/utils/login_form_validation.dart';
import 'package:chronoapp/features/login/presentation/widgets/buttons.dart';
import 'package:chronoapp/features/login/presentation/widgets/login_personal_name_fields.dart';
import 'package:chronoapp/features/login/presentation/widgets/login_scroll_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsEditPersonalDataPage extends ConsumerStatefulWidget {
  const SettingsEditPersonalDataPage({
    super.key,
    this.initialFirstName,
    this.initialLastName,
  });

  final String? initialFirstName;
  final String? initialLastName;

  @override
  ConsumerState<SettingsEditPersonalDataPage> createState() =>
      _SettingsEditPersonalDataPageState();
}

class _SettingsEditPersonalDataPageState
    extends ConsumerState<SettingsEditPersonalDataPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameFieldKey = GlobalKey<FormFieldState<dynamic>>();
  final _lastNameFieldKey = GlobalKey<FormFieldState<dynamic>>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    AppModalSheetTracker.retainMainNavigationHidden();
    _firstNameController = TextEditingController(
      text: (widget.initialFirstName ?? '').trim(),
    );
    _lastNameController = TextEditingController(
      text: (widget.initialLastName ?? '').trim(),
    );
  }

  @override
  void dispose() {
    AppModalSheetTracker.releaseMainNavigationHidden();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final ok = loginValidateFormAndScrollToFirstError(
      context,
      formKey: _formKey,
      orderedFieldKeys: [_firstNameFieldKey, _lastNameFieldKey],
    );
    if (!ok) return;

    setState(() => _busy = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .updateProfile(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
          );
      await ref.read(profileGateProvider).refresh();
      ref.invalidate(syncedProfileProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on AuthRepositoryException catch (e) {
      if (mounted) {
        showAppToast(context, e.message, kind: AppToastKind.error);
      }
      rethrow;
    } catch (_) {
      if (mounted) {
        showAppToast(
          context,
          'Änderung konnte nicht gespeichert werden. Bitte erneut versuchen.',
          kind: AppToastKind.error,
        );
      }
      rethrow;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final titleStyle = GoogleFonts.libreBaskerville(
      color: scheme.onSurface,
      fontSize: 44,
      fontWeight: FontWeight.w700,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.chevron_left, size: 40),
                  padding: const EdgeInsets.only(left: 4),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: LoginStepScaffold.defaultContentMaxWidth,
                  ),
                  child: Text(
                    LoginFlowStep.personalData.title,
                    textAlign: TextAlign.left,
                    style: titleStyle,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: LoginScrollSurface(
                scrollPadding: const EdgeInsets.only(bottom: 16),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: LoginStepScaffold.defaultContentMaxWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Form(
                        key: _formKey,
                        child: LoginPersonalNameFields(
                          firstNameFieldKey: _firstNameFieldKey,
                          lastNameFieldKey: _lastNameFieldKey,
                          firstNameController: _firstNameController,
                          lastNameController: _lastNameController,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Align(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: LoginStepScaffold.defaultContentMaxWidth,
                  ),
                  child: LoginPrimaryButton(
                    label: 'Speichern',
                    color: scheme.primary,
                    isLoading: _busy,
                    onPressed: _busy ? null : _onSave,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
