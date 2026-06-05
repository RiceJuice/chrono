import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/calendar_event_change_summary.dart';

class EventBroadcastException implements Exception {
  EventBroadcastException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Ruft die Edge Function `notify-event-change` auf (Admin-JWT).
class EventBroadcastService {
  EventBroadcastService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<void> notifyChange({
    required String eventId,
    required CalendarEventChangeSummary summary,
  }) async {
    final body = summary.toRequestBody(eventId: eventId);

    final response = await _client.functions.invoke(
      'notify-event-change',
      body: body,
    );

    if (response.status != 200) {
      final data = response.data;
      final message = data is Map && data['error'] != null
          ? data['error'].toString()
          : 'Benachrichtigung fehlgeschlagen (${response.status}).';
      throw EventBroadcastException(message);
    }
  }
}
