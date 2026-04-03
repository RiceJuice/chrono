import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/widgets/bottom_modal_images.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/widgets/bottom_modal_text.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EventBottomModal extends StatelessWidget {
  final CalendarEntry entry;
  const EventBottomModal({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // Empfohlen für Bottom Modals
      children: [
        BottomModalImages(entry: entry),
        BottomModalText(
          entry: entry, 
          // Hier wird die Schriftart korrekt zugewiesen:
          titleStyle: GoogleFonts.libreBaskerville(
            fontSize: 20, 
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}