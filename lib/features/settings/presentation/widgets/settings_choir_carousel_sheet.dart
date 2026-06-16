import 'package:chronoapp/features/login/domain/models/login_flow_step.dart';
import 'package:chronoapp/features/login/presentation/pages/select_choir/login_choir_options.dart';
import 'package:chronoapp/features/login/presentation/pages/select_choir/widgets/login_choir_selection.dart';
import 'package:chronoapp/features/login/presentation/widgets/buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SettingsChoirCarouselSheet extends StatefulWidget {
  const SettingsChoirCarouselSheet({
    super.key,
    required this.initialChoirLabel,
  });

  final String? initialChoirLabel;

  @override
  State<SettingsChoirCarouselSheet> createState() =>
      _SettingsChoirCarouselSheetState();
}

class _SettingsChoirCarouselSheetState extends State<SettingsChoirCarouselSheet> {
  late int _choirPage;
  late String _selectedChoirLabel;

  @override
  void initState() {
    super.initState();
    _choirPage = LoginChoirOptions.pageIndexForLabel(widget.initialChoirLabel);
    _selectedChoirLabel = LoginChoirOptions.labelForPageIndex(_choirPage);
  }

  void _onPageChanged(int page) {
    setState(() {
      _choirPage = page;
      _selectedChoirLabel = LoginChoirOptions.labelForPageIndex(page);
    });
  }

  void _save() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(_selectedChoirLabel);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return SafeArea(
      bottom: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: screenHeight * 0.72,
          maxHeight: screenHeight * 0.92,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Text(
                'Chor auswählen',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            LoginChoirSelection(
              selectedPage: _choirPage,
              selectedVoice: '',
              onPageChanged: _onPageChanged,
              onVoiceChanged: (_) {},
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottomPadding),
              child: LoginPrimaryButton(
                label: 'Speichern',
                color: LoginFlowStep.choir.accentColor,
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
