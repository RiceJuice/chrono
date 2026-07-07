import 'package:chronoapp/core/widgets/app_toast.dart';
import 'package:chronoapp/features/calendar/presentation/providers/meal_images_preference_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/auth_repository.dart';
import '../../../domain/models/login_flow_role_ids.dart';
import '../../../domain/models/login_flow_step.dart';
import '../../providers/auth_repository_provider.dart';
import '../../providers/klassen_provider.dart';
import '../../copy/login_flow_role_ui.dart';
import '../../widgets/login_step_scaffold.dart';
import '../../providers/profile_gate_provider.dart';
import '../../routes/login_routes.dart';
import '../../state/login_flow_draft.dart';
import '../../utils/draft_text_controller.dart';
import '../../utils/login_form_validation.dart';
import '../../widgets/login_personal_name_fields.dart';
import 'widgets/forms.dart';

class PersonalDataPage extends ConsumerStatefulWidget {
  const PersonalDataPage({super.key});

  @override
  ConsumerState<PersonalDataPage> createState() => _PersonalDataPageState();
}

class _PersonalDataPageState extends ConsumerState<PersonalDataPage> {
  final _draft = LoginFlowDraft.instance;
  final _formKey = GlobalKey<FormState>();
  final _firstNameFieldKey = GlobalKey<FormFieldState<dynamic>>();
  final _lastNameFieldKey = GlobalKey<FormFieldState<dynamic>>();
  final _classFieldKey = GlobalKey<FormFieldState<dynamic>>();
  final _schoolTrackFieldKey = GlobalKey<FormFieldState<dynamic>>();
  final _dietFieldKey = GlobalKey<FormFieldState<dynamic>>();
  late final DraftTextController _firstNameController;
  late final DraftTextController _lastNameController;
  String? _selectedClass;
  String? _selectedSchoolTrack;
  String? _selectedDiet;
  bool _showMealImages = true;
  bool _busy = false;

  bool get _isGuardian => _draft.role.trim() == LoginFlowRoleIds.guardian;

  @override
  void initState() {
    super.initState();
    _firstNameController = DraftTextController(
      initialValue: _draft.firstName,
      onChanged: (value) => _draft.firstName = value,
    );
    _lastNameController = DraftTextController(
      initialValue: _draft.lastName,
      onChanged: (value) => _draft.lastName = value,
    );
    _selectedClass = _draft.schoolClass;
    _selectedSchoolTrack = _draft.schoolTrack;
    _selectedDiet = _draft.diet;
    _showMealImages = _draft.showMealImages;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final classOptionsAsync = ref.watch(availableClassesProvider);
    final classOptions = classOptionsAsync.asData?.value ?? const <String>[];
    final roleUi = LoginFlowRoleUi.fromStoredRoleLabel(_draft.role);

    return LoginStepScaffold(
      step: LoginFlowStep.personalData,
      titleOverride: roleUi.scaffoldTitle(LoginFlowStep.personalData),
      subtitleOverride: _isGuardian
          ? 'Wie heißt du? Dein Kind sieht diesen Namen bei der Verknüpfung.'
          : null,
      nextPath: _isGuardian ? LoginPaths.selectChild : LoginPaths.choir,
      submitBusy: _busy,
      contentMaxWidth: LoginStepScaffold.defaultContentMaxWidth,
      primaryButtonMaxWidth: LoginStepScaffold.defaultContentMaxWidth,
      validateBeforeProceed: () => loginValidateFormAndScrollToFirstError(
        context,
        formKey: _formKey,
        orderedFieldKeys: [
          _firstNameFieldKey,
          _lastNameFieldKey,
          if (!_isGuardian) _classFieldKey,
          if (!_isGuardian) _schoolTrackFieldKey,
          if (!_isGuardian) _dietFieldKey,
        ],
      ),
      onAsyncProceed: (goNext) async {
        setState(() => _busy = true);
        try {
          _draft.firstName = _firstNameController.text.trim();
          _draft.lastName = _lastNameController.text.trim();
          if (_draft.firstName.isEmpty || _draft.lastName.isEmpty) {
            if (!context.mounted) return;
            showAppToast(
              context,
              'Bitte Vorname und Nachname ausfüllen.',
              kind: AppToastKind.info,
            );
            throw const LoginStepErrorAlreadyShown();
          }

          if (_isGuardian) {
            await ref.read(authRepositoryProvider).updateProfile(
                  firstName: _draft.firstName,
                  lastName: _draft.lastName,
                );
          } else {
            final className = _draft.schoolClass;
            if (className == null || className.trim().isEmpty) {
              if (!context.mounted) return;
              showAppToast(
                context,
                'Bitte wähle eine Klasse aus.',
                kind: AppToastKind.info,
              );
              throw const LoginStepErrorAlreadyShown();
            }
            final schoolTrack = _draft.schoolTrack;
            if (schoolTrack == null || schoolTrack.trim().isEmpty) {
              if (!context.mounted) return;
              showAppToast(
                context,
                'Bitte waehle einen Schulzweig aus.',
                kind: AppToastKind.info,
              );
              throw const LoginStepErrorAlreadyShown();
            }
            final diet = _draft.diet;
            if (diet == null || diet.trim().isEmpty) {
              if (!context.mounted) return;
              showAppToast(
                context,
                'Bitte wähle eine Ernährung aus.',
                kind: AppToastKind.info,
              );
              throw const LoginStepErrorAlreadyShown();
            }
            await ref.read(authRepositoryProvider).updateProfile(
                  firstName: _draft.firstName,
                  lastName: _draft.lastName,
                  className: className,
                  schoolTrack: schoolTrack,
                  diet: diet,
                );
            await setShowMealImages(ref, _draft.showMealImages);
          }

          await ref.read(profileGateProvider).refresh();
          if (!context.mounted) return;
          goNext();
        } on AuthRepositoryException {
          rethrow;
        } finally {
          if (context.mounted) setState(() => _busy = false);
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Form(
          key: _formKey,
          child: _isGuardian
              ? LoginPersonalNameFields(
                  firstNameFieldKey: _firstNameFieldKey,
                  lastNameFieldKey: _lastNameFieldKey,
                  firstNameController: _firstNameController,
                  lastNameController: _lastNameController,
                )
              : LoginPersonalDataFields(
                  firstNameFieldKey: _firstNameFieldKey,
                  lastNameFieldKey: _lastNameFieldKey,
                  classFieldKey: _classFieldKey,
                  schoolTrackFieldKey: _schoolTrackFieldKey,
                  dietFieldKey: _dietFieldKey,
                  firstNameController: _firstNameController,
                  lastNameController: _lastNameController,
                  selectedClass: _selectedClass,
                  selectedSchoolTrack: _selectedSchoolTrack,
                  selectedDiet: _selectedDiet,
                  showMealImages: _showMealImages,
                  classOptions: classOptions,
                  onClassChanged: (value) => setState(() {
                    _selectedClass = value;
                    _draft.schoolClass = value;
                  }),
                  onSchoolTrackChanged: (value) => setState(() {
                    _selectedSchoolTrack = value;
                    _draft.schoolTrack = value;
                  }),
                  onDietChanged: (value) => setState(() {
                    _selectedDiet = value;
                    _draft.diet = value;
                  }),
                  onShowMealImagesChanged: (value) => setState(() {
                    _showMealImages = value;
                    _draft.showMealImages = value;
                  }),
                ),
        ),
      ),
    );
  }
}
