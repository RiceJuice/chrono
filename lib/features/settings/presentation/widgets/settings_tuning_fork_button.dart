import 'package:chronoapp/features/settings/presentation/pages/settings_tuning_fork_page.dart';
import 'package:chronoapp/features/settings/presentation/widgets/tuning_fork_illustration.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SettingsTuningForkButton extends StatelessWidget {
  const SettingsTuningForkButton({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final iconColor = scheme.onSurfaceVariant.withValues(
      alpha: scheme.brightness == Brightness.dark ? 0.55 : 0.45,
    );

    return Semantics(
      button: true,
      label: 'Stimmgabel öffnen',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.heavyImpact();
            Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (context) => const SettingsTuningForkPage(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Center(
              child: TuningForkIllustration(
                size: 40,
                color: iconColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
