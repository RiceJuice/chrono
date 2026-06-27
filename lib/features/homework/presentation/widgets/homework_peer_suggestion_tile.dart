import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_subject.dart';
import 'package:chronoapp/features/homework/domain/models/homework_peer_suggestion.dart';
import 'package:chronoapp/features/homework/presentation/widgets/homework_fragment_chip.dart';
import 'package:chronoapp/features/homework/presentation/widgets/homework_peer_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class HomeworkPeerSuggestionTile extends StatelessWidget {
  const HomeworkPeerSuggestionTile({
    super.key,
    required this.suggestion,
    required this.subject,
    this.onAccept,
    this.onReject,
  });

  final HomeworkPeerSuggestion suggestion;
  final CalendarSubject? subject;
  final Future<void> Function()? onAccept;
  final Future<void> Function()? onReject;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final interactive = onAccept != null || onReject != null;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.s,
      ),
      child: HomeworkPeerShimmer(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (interactive) ...[
                _ActionIconButton(
                  icon: PhosphorIcons.check(PhosphorIconsStyle.bold),
                  color: scheme.tertiary,
                  onPressed: onAccept,
                  tooltip: 'Übernehmen',
                ),
                const SizedBox(width: AppSpacing.xs),
                _ActionIconButton(
                  icon: PhosphorIcons.x(PhosphorIconsStyle.bold),
                  color: scheme.onSurfaceVariant,
                  onPressed: onReject,
                  tooltip: 'Ablehnen',
                ),
                const SizedBox(width: AppSpacing.s),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Von der Klasse',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: scheme.tertiary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (subject != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: subject!.defaultColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s),
                          Expanded(
                            child: Text(
                              subject!.name,
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: scheme.onSurface.withValues(alpha: 0.8),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    HomeworkFragmentChipRow(
                      fragments: [suggestion.fragment],
                      compact: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  const _ActionIconButton({
    required this.icon,
    required this.color,
    required this.onPressed,
    required this.tooltip,
  });

  final IconData icon;
  final Color color;
  final Future<void> Function()? onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed == null
              ? null
              : () async {
                  AppHaptics.selection();
                  await onPressed!();
                },
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, size: 20, color: color),
          ),
        ),
      ),
    );
  }
}
