import 'package:chronoapp/features/homework/presentation/widgets/homework_task_form_sheet.dart';
import 'package:flutter/material.dart';

class HomeworkCreateFormSheet extends StatelessWidget {
  const HomeworkCreateFormSheet({super.key});
  static Future<void> show(BuildContext context) =>
      HomeworkTaskFormSheet.show(context);
  @override
  Widget build(BuildContext context) => const HomeworkTaskFormSheet();
}
