import 'package:flutter/material.dart';
import '../domain/models/calendar_entry.dart'; 

class CalendarMockData {
  static List<CalendarEntry> getEntries() {
    return [
      // --- MONTAG, 02. MÄRZ 2026 ---
      CalendarEntry(
        id: '1',
        title: 'Mathe',
        subtitle: 'Volker Herfeld',
        location: 'Raum 2.07',
        startTime: DateTime(2026, 3, 2, 8, 45),
        endTime: DateTime(2026, 3, 2, 9, 30),
        accentColor: Colors.blueAccent,
        type: CalendarEntryType.lesson,
      ),
      CalendarEntry(
        id: '2',
        title: 'Englisch',
        subtitle: 'Volker Herfeld',
        location: 'Raum 2.07',
        startTime: DateTime(2026, 3, 2, 10, 0),
        endTime: DateTime(2026, 3, 2, 11, 30),
        accentColor: const Color(0xFFEAD4A4),
        type: CalendarEntryType.lesson,
      ),
      CalendarEntry(
        id: '3',
        title: 'Spaghetti Bolognese',
        subtitle: 'Nudeln mit Rinderhackfleisch',
        startTime: DateTime(2026, 3, 2, 12, 15),
        endTime: DateTime(2026, 3, 2, 13, 0),
        imageUrl: 'https://images.unsplash.com/photo-1598103442097-8b74394b95c6',
        accentColor: Colors.transparent,
        type: CalendarEntryType.meal,
        tags: ['Mit Linsen'],
      ),
      CalendarEntry(
        id: '4',
        title: 'Konzert: Pueri Gaudentes',
        subtitle: 'Mittwoch, 4. März 2026',
        location: 'St. Cäcilia',
        startTime: DateTime(2026, 3, 2, 14, 0),
        endTime: DateTime(2026, 3, 2, 17, 30),
        imageUrl: 'https://images.unsplash.com/photo-1515162305285-0293e4767cc2',
        accentColor: Colors.transparent,
        type: CalendarEntryType.event,
      ),
      
      // --- DIENSTAG, 03. MÄRZ 2026 ---
      CalendarEntry(
        id: '5',
        title: 'Informatik',
        subtitle: 'Dr. Tech',
        location: 'Labor 01',
        startTime: DateTime(2026, 3, 3, 9, 0),
        endTime: DateTime(2026, 3, 3, 10, 30),
        accentColor: Colors.greenAccent,
        type: CalendarEntryType.lesson,
      ),

      // --- MITTWOCH, 04. MÄRZ 2026 ---
      CalendarEntry(
        id: '7',
        title: 'Sport',
        subtitle: 'Hr. Trainer',
        location: 'Turnhalle Süd',
        startTime: DateTime(2026, 3, 4, 11, 15),
        endTime: DateTime(2026, 3, 4, 12, 45),
        accentColor: Colors.orangeAccent,
        type: CalendarEntryType.lesson,
      ),
    ];
  }
}