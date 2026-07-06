import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:chronoapp/core/widgets/app_modal_sheet.dart';
import 'package:chronoapp/core/widgets/app_sheet_drag_handle.dart';
import 'package:chronoapp/features/homework/presentation/widgets/homework_form_shell.dart';
import 'package:chronoapp/features/homework/presentation/widgets/homework_task_form_sheet.dart';
import 'package:chronoapp/features/school_assessments/presentation/providers/school_assessment_providers.dart';
import 'package:chronoapp/features/school_assessments/presentation/widgets/school_assessment_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeworkCreateFormSheet extends ConsumerStatefulWidget {
  const HomeworkCreateFormSheet({super.key});

  static Future<void> show(BuildContext context) {
    return AppModalSheet.show<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      sheetAnimationStyle: kAppModalSheetMotion,
      builder: (sheetContext) {
        return AppModalSheetChrome(
          constraints: appModalHomeworkFormSheetConstraints(sheetContext),
          child: const HomeworkCreateFormSheet(),
        );
      },
    );
  }

  @override
  ConsumerState<HomeworkCreateFormSheet> createState() =>
      _HomeworkCreateFormSheetState();
}

class _HomeworkCreateFormSheetState
    extends ConsumerState<HomeworkCreateFormSheet> {
  HomeworkCreateKind _kind = HomeworkCreateKind.task;

  void _onKindChanged(HomeworkCreateKind nextKind) {
    if (nextKind == _kind) return;
    HapticFeedback.selectionClick();
    AppHaptics.selection();
    setState(() => _kind = nextKind);
  }

  @override
  Widget build(BuildContext context) {
    final canCreateAssessment = ref.watch(canCreateSchoolAssessmentProvider);

    if (!canCreateAssessment) {
      return const HomeworkTaskFormSheet();
    }

    return SafeArea(
      top: false,
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppSheetDragHandle(),
          HomeworkCreateKindSegmentedControl(
            value: _kind,
            onChanged: _onKindChanged,
          ),
          Expanded(
            child: IndexedStack(
              index: _kind == HomeworkCreateKind.task ? 0 : 1,
              children: const [
                HomeworkTaskFormSheet(embedded: true),
                SchoolAssessmentFormSheet(embedded: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
