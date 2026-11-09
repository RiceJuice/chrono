import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/core/widgets/app_hairline_divider.dart';
import 'package:chronoapp/core/widgets/app_sheet_drag_handle.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

bool homeworkUsesCupertino(BuildContext context) =>
    Theme.of(context).platform == TargetPlatform.iOS ||
    Theme.of(context).platform == TargetPlatform.macOS;

enum HomeworkCreateKind { task, assessment }

extension HomeworkCreateKindLabels on HomeworkCreateKind {
  String get label => switch (this) {
    HomeworkCreateKind.task => 'Aufgabe',
    HomeworkCreateKind.assessment => 'Klausur',
  };
}

/// Gruppierte Formular-Karte im Stil der Einstellungs-Inseln.
class HomeworkFormGroup extends StatelessWidget {
  const HomeworkFormGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: ShapeDecoration(
        color: homeworkUsesCupertino(context)
            ? CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
                context,
              )
            : scheme.surfaceContainerLow,
        shape: AppSquircle.shape(AppRadius.l),
      ),
      child: ClipSmoothRect(
        radius: AppSquircle.borderRadius(AppRadius.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _withDividers(),
        ),
      ),
    );
  }

  List<Widget> _withDividers() {
    final divided = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        divided.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.l),
            child: AppHairlineDivider.horizontal(),
          ),
        );
      }
      divided.add(children[i]);
    }
    return divided;
  }
}

class HomeworkFormSectionLabel extends StatelessWidget {
  const HomeworkFormSectionLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        0,
        AppSpacing.xs,
        AppSpacing.s,
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class HomeworkFormModalHeader extends StatelessWidget {
  const HomeworkFormModalHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppSheetDragHandle(),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.s,
            AppSpacing.xl,
            AppSpacing.l,
          ),
          child: Row(
            children: [
              const SizedBox(width: 40),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Schließen',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(CupertinoIcons.xmark_circle_fill),
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class HomeworkCreateKindSegmentedControl extends StatelessWidget {
  const HomeworkCreateKindSegmentedControl({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final HomeworkCreateKind value;
  final ValueChanged<HomeworkCreateKind> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: HomeworkFormSegmentedControl<HomeworkCreateKind>(
        value: value,
        onChanged: onChanged,
        segments: [
          for (final kind in HomeworkCreateKind.values)
            HomeworkFormSegment(value: kind, label: kind.label),
        ],
      ),
    );
  }
}

class HomeworkFormHeader extends StatelessWidget {
  const HomeworkFormHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppSheetDragHandle(),
        const SizedBox(height: AppSpacing.m),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
            color: scheme.onSurface,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}

class HomeworkFormPickerRow extends StatelessWidget {
  const HomeworkFormPickerRow({
    super.key,
    required this.label,
    required this.onTap,
    this.value,
    this.leading,
    this.enabled = true,
  });

  final String label;
  final String? value;
  final Widget? leading;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final effectiveOnTap = enabled ? onTap : null;
    final displayValue = value?.trim();

    if (homeworkUsesCupertino(context)) {
      return CupertinoListTile(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        leading: leading,
        title: Text(label),
        additionalInfo: displayValue == null
            ? null
            : SizedBox(
                width: MediaQuery.sizeOf(context).width * 0.38,
                child: Text(
                  displayValue,
                  maxLines: 2,
                  textAlign: TextAlign.end,
                ),
              ),
        trailing: const CupertinoListTileChevron(),
        onTap: effectiveOnTap,
      );
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: effectiveOnTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.l,
            vertical: AppSpacing.m + 2,
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: AppSpacing.m),
              ],
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: enabled
                        ? scheme.onSurface
                        : scheme.onSurface.withValues(alpha: 0.4),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (displayValue != null && displayValue.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.s),
                Flexible(
                  child: Text(
                    displayValue,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: enabled
                          ? scheme.onSurfaceVariant
                          : scheme.onSurface.withValues(alpha: 0.35),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: enabled
                    ? scheme.onSurfaceVariant.withValues(alpha: 0.7)
                    : scheme.onSurface.withValues(alpha: 0.25),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeworkFormField extends StatelessWidget {
  const HomeworkFormField({
    super.key,
    this.label,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.l,
      AppSpacing.m,
      AppSpacing.l,
      AppSpacing.m,
    ),
  });

  final String? label;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (label != null) ...[
            Text(
              label!,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.s),
          ],
          child,
        ],
      ),
    );
  }
}

class HomeworkFormInfoBanner extends StatelessWidget {
  const HomeworkFormInfoBanner({
    super.key,
    required this.message,
    this.icon = Icons.info_outline_rounded,
    this.tone = HomeworkFormInfoTone.neutral,
  });

  final String message;
  final IconData icon;
  final HomeworkFormInfoTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color bg, Color fg) = switch (tone) {
      HomeworkFormInfoTone.neutral => (
        scheme.primaryContainer.withValues(alpha: 0.45),
        scheme.onSurfaceVariant,
      ),
      HomeworkFormInfoTone.error => (
        scheme.errorContainer.withValues(alpha: 0.55),
        scheme.error,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.s,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: fg, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

enum HomeworkFormInfoTone { neutral, error }

class HomeworkFormSegmentedControl<T extends Object> extends StatelessWidget {
  const HomeworkFormSegmentedControl({
    super.key,
    required this.value,
    required this.onChanged,
    required this.segments,
  });

  final T value;
  final ValueChanged<T> onChanged;
  final List<HomeworkFormSegment<T>> segments;

  @override
  Widget build(BuildContext context) {
    if (homeworkUsesCupertino(context)) {
      return CupertinoSlidingSegmentedControl<T>(
        groupValue: value,
        disabledChildren: {
          for (final segment in segments)
            if (!segment.enabled) segment.value,
        },
        children: {
          for (final segment in segments)
            segment.value: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(segment.label),
            ),
        },
        onValueChanged: (next) {
          if (next != null) onChanged(next);
        },
      );
    }
    return SegmentedButton<T>(
      segments: [
        for (final segment in segments)
          ButtonSegment<T>(
            value: segment.value,
            label: Text(segment.label),
            enabled: segment.enabled,
          ),
      ],
      selected: {value},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}

class HomeworkFormSegment<T extends Object> {
  const HomeworkFormSegment({
    required this.value,
    required this.label,
    this.enabled = true,
  });

  final T value;
  final String label;
  final bool enabled;
}

class HomeworkFormFooter extends StatelessWidget {
  const HomeworkFormFooter({
    super.key,
    required this.onSubmit,
    required this.submitLabel,
    this.busy = false,
    this.submitEnabled = true,
    this.onCancel,
  });

  final VoidCallback onSubmit;
  final String submitLabel;
  final bool busy;
  final bool submitEnabled;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (homeworkUsesCupertino(context))
          CupertinoButton.filled(
            onPressed: busy || !submitEnabled ? null : onSubmit,
            child: busy
                ? const CupertinoActivityIndicator()
                : Text(submitLabel),
          )
        else
          FilledButton(
            onPressed: busy || !submitEnabled ? null : onSubmit,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.l),
              ),
            ),
            child: busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(submitLabel),
          ),
        if (onCancel != null) ...[
          const SizedBox(height: AppSpacing.s),
          if (homeworkUsesCupertino(context))
            CupertinoButton(
              onPressed: busy ? null : onCancel,
              child: const Text('Abbrechen'),
            )
          else
            TextButton(
              onPressed: busy ? null : onCancel,
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              child: const Text('Abbrechen'),
            ),
        ],
      ],
    );
  }
}
