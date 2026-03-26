import 'package:flutter/material.dart';
import '../domain/models/calendar_entry.dart'; 

class CalendarMockData {
  static List<CalendarEntry> getEntries() {
    final now = DateTime.now();
    // Normalize to local date at midnight
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dayAfterTomorrow = today.add(const Duration(days: 2));

    return [
      // --- HEUTE ---
      CalendarEntry(
        id: '1',
        title: 'Mathe',
        subtitle: 'Volker Herfeld',
        location: 'Raum 2.07',
        startTime: today.copyWith(hour: 8, minute: 45),
        endTime: today.copyWith(hour: 9, minute: 30),
        accentColor: Colors.blueAccent,
        type: CalendarEntryType.lesson,
      ),
      CalendarEntry(
        id: '2',
        title: 'Englisch',
        subtitle: 'Volker Herfeld',
        location: 'Raum 2.07',
        startTime: today.copyWith(hour: 10, minute: 0),
        endTime: today.copyWith(hour: 11, minute: 30),
        accentColor: const Color(0xFFEAD4A4),
        type: CalendarEntryType.lesson,
      ),
      CalendarEntry(
        id: '3',
        title: 'Spaghetti Bolognese',
        subtitle: 'Nudeln mit Rinderhackfleisch',
        startTime: today.copyWith(hour: 12, minute: 15),
        endTime: today.copyWith(hour: 13, minute: 0),
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
        startTime: today.copyWith(hour: 14, minute: 0),
        endTime: today.copyWith(hour: 17, minute: 30),
        imageUrl: 'https://images.unsplash.com/photo-1515162305285-0293e4767cc2',
        accentColor: Colors.transparent,
        type: CalendarEntryType.event,
      ),
      
      // --- WEITERE TAGE ---
      CalendarEntry(
        id: '5',
        title: 'Informatik',
        subtitle: 'Dr. Tech',
        location: 'Labor 01',
        startTime: tomorrow.copyWith(hour: 09, minute: 00),
        endTime: tomorrow.copyWith(hour: 10, minute: 30),
        accentColor: Colors.greenAccent,
        type: CalendarEntryType.lesson,
      ),
      CalendarEntry(
        id: '7',
        title: 'Sport',
        subtitle: 'Hr. Trainer',
        location: 'Turnhalle Süd',
        startTime: dayAfterTomorrow.copyWith(hour: 11, minute: 15),
        endTime: dayAfterTomorrow.copyWith(hour: 12, minute: 45),
        accentColor: Colors.orangeAccent,
        type: CalendarEntryType.lesson,
      ),
    ];
  }
}