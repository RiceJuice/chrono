import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'schedule_live_activity_service.dart';

/// Eine Plugin-Instanz für Event- und Stundenplan-Live-Activities.
final scheduleLiveActivityServiceProvider = Provider<ScheduleLiveActivityService>(
  (ref) {
    final service = ScheduleLiveActivityService();
    ref.onDispose(service.dispose);
    return service;
  },
);
