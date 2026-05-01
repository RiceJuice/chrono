import 'package:chronoapp/features/calendar/presentation/providers/calendar_view_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CalendarViewModeOverlay extends StatelessWidget {
  const CalendarViewModeOverlay({
    required this.isOpen,
    required this.options,
    required this.selectedMode,
    required this.onClose,
    required this.onSelected,
    super.key,
  });

  final bool isOpen;
  final List<CalendarViewOption> options;
  final CalendarViewMode selectedMode;
  final VoidCallback onClose;
  final ValueChanged<CalendarViewMode> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final topOffset = MediaQuery.paddingOf(context).top + kToolbarHeight;

    return IgnorePointer(
      ignoring: !isOpen,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: onClose,
            ),
          ),
          Positioned(
            top: topOffset,
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              opacity: isOpen ? 1 : 0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onClose,
                child: ColoredBox(color: Colors.black.withValues(alpha: 0.18)),
              ),
            ),
          ),
          Positioned(
            top: topOffset,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              opacity: isOpen ? 1 : 0,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                offset: isOpen ? Offset.zero : const Offset(0, -0.35),
                child: Material(
                  elevation: 0,
                  color: Colors.transparent,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(15),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainer,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(15),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final entry in options.indexed)
                            Padding(
                              padding: EdgeInsets.only(
                                top: entry.$1 == 0 ? 0 : 6,
                              ),
                              child: _CalendarViewModeTile(
                                option: entry.$2,
                                selected: entry.$2.mode == selectedMode,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  onSelected(entry.$2.mode);
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarViewModeTile extends StatelessWidget {
  const _CalendarViewModeTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final CalendarViewOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tileColor = selected
        ? scheme.primary.withValues(alpha: 0.08)
        : Colors.transparent;
    final foregroundColor = selected ? scheme.primary : scheme.onSurface;

    return Material(
      color: tileColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Icon(option.icon, color: foregroundColor, size: 21),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  option.label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              SizedBox(
                width: 28,
                child: selected
                    ? Icon(Icons.check_rounded, color: scheme.primary, size: 22)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
