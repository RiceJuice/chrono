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
        // Jetzt als Liste von Strings
        imageUrls: [
          'https://images.unsplash.com/photo-1598103442097-8b74394b95c6',
          'https://images.unsplash.com/photo-1622973536968-3ead9e780960', // Zusätzliches Pasta-Bild
        ],
        accentColor: Colors.transparent,
        type: CalendarEntryType.meal,
        tags: ['Mit Linsen'],
      ),

      CalendarEntry(
        id: '4',
        title: "Pueri Gaudentes",
        subtitle: 'Mittwoch, 4. März 2026',
        location: 'St. Cäcilia',
        startTime: DateTime(2026, 3, 2, 14, 0),
        endTime: DateTime(2026, 3, 2, 17, 30),
        // Jetzt als Liste von Strings
        imageUrls: [
          "https://cdn-static.matricula-online.eu/media/parish_images/3240px-St_C%C3%A4cilia_-_Regensburg_0811.jpg",
          "https://bistum-regensburg.de//fileadmin/Bilder/News_u._Kirchenjahr/News_2021/News_2021_12/211206_100_Jahre_Pfarrei_Caecilia_Regensburg_Header.JPG",
          "https://data.matricula-online.eu/de/deutschland/regensburg/regensburg-st-caecilia/"

        ],
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
