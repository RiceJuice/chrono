import 'package:chronoapp/features/settings/presentation/helpers/settings_app_metadata.dart';
import 'package:chronoapp/features/settings/presentation/widgets/settings_buy_coffee_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsFooter extends ConsumerWidget {
  const SettingsFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metadata = ref.watch(settingsAppMetadataProvider);
    final scheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            metadata.maybeWhen(
              data: (data) => data.versionLabel,
              orElse: () => 'Version wird geladen',
            ),
            style: textStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Impressum',
            style: textStyle?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Alexander Ottmann, '
            'Frederick Seubert\n'
            'Florian Bandulik',
            style: textStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          const SettingsBuyCoffeeButton(),
        ],
      ),
    );
  }
}
