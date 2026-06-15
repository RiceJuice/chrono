import 'package:chronoapp/core/widgets/event_schedule_scroll_coordinator.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/presentation/providers/event_schedules_providers.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/widgets/bottom_modal_images.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/widgets/bottom_modal_schedule_section.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/widgets/bottom_modal_text.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/widgets/event_bottom_modal_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bilder + Metadaten (ohne Ablauf) für das Event-Detail-Sheet.
class EventBottomModalHeader extends StatelessWidget {
  const EventBottomModalHeader({super.key, required this.entry});

  final CalendarEntry entry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        BottomModalImages(
          entry: entry,
          imageOuterBorderRadius: AppRadius.sheet,
        ),
        BottomModalText(
          entry: entry,
          layout: BottomModalTextLayout.event,
          includeScheduleSection: false,
          titleStyle: GoogleFonts.libreBaskerville(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            height: 1.15,
          ),
        ),
      ],
    );
  }
}

/// Ablauf-Bereich für das Event-Detail-Sheet.
///
/// Mit [sliverLayout] als Sliver in [CustomScrollView] — Teil des gesamten
/// Sheet-Scrolls (Header + Ablauf).
class EventBottomModalSchedulePane extends ConsumerWidget {
  const EventBottomModalSchedulePane({
    super.key,
    required this.eventId,
    required this.entry,
    this.sliverLayout = false,
    this.sheetScrollController,
    this.scrollCoordinator,
    this.sheetSurfaceColor,
  });

  final String eventId;
  final CalendarEntry entry;
  final bool sliverLayout;
  final ScrollController? sheetScrollController;
  final EventScheduleScrollCoordinator? scrollCoordinator;
  final Color? sheetSurfaceColor;

  static TextStyle _eventTitleStyle(BuildContext context) {
    return GoogleFonts.libreBaskerville(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      height: 1.15,
    );
  }

  Widget _eventTitleBlock(BuildContext context) {
    return BottomModalText(
      entry: entry,
      layout: BottomModalTextLayout.event,
      includeScheduleSection: false,
      eventPart: BottomModalEventTextPart.titleOnly,
      titleStyle: _eventTitleStyle(context),
    );
  }

  Widget _eventDetailBlock(BuildContext context) {
    return BottomModalText(
      entry: entry,
      layout: BottomModalTextLayout.event,
      includeScheduleSection: false,
      eventPart: BottomModalEventTextPart.detailsOnly,
      titleStyle: _eventTitleStyle(context),
    );
  }

  Widget _eventImagesBlock() {
    return BottomModalImages(
      entry: entry,
      imageOuterBorderRadius: AppRadius.sheet,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedulesAsync = ref.watch(eventSchedulesForEntryProvider(eventId));

    return schedulesAsync.when(
      data: (schedules) {
        if (schedules.isEmpty) {
          return sliverLayout
              ? SliverToBoxAdapter(
                  child: EventBottomModalHeader(entry: entry),
                )
              : const SizedBox.shrink();
        }
        final section = BottomModalScheduleSection(
          schedules: schedules,
          eventLayout: true,
          scrollable: sliverLayout,
          sheetScrollController: sheetScrollController,
          scrollCoordinator: scrollCoordinator,
          stickyImages: sliverLayout ? _eventImagesBlock() : null,
          stickyTitleBlock: sliverLayout ? _eventTitleBlock(context) : null,
          scrollableDetailBlock:
              sliverLayout ? _eventDetailBlock(context) : null,
          stickyHeaderSurfaceColor:
              sliverLayout ? sheetSurfaceColor : null,
        );
        if (sliverLayout) return section;
        return Padding(
          padding: const EdgeInsets.only(
            top: EventBottomModalTypography.gapSection,
          ),
          child: section,
        );
      },
      loading: () => sliverLayout
          ? const SliverToBoxAdapter(
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          : const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
      error: (_, _) => sliverLayout
          ? const SliverToBoxAdapter(child: SizedBox.shrink())
          : const SizedBox.shrink(),
    );
  }
}

/// Legacy-Hülle — wird nur noch außerhalb des Sliver-Layouts genutzt.
class EventBottomModal extends StatelessWidget {
  final CalendarEntry entry;
  const EventBottomModal({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        EventBottomModalHeader(entry: entry),
        EventBottomModalSchedulePane(eventId: entry.id, entry: entry),
      ],
    );
  }
}
