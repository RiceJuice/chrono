import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ausstehende Navigation in den Ablaufplan eines Termins (z. B. nach Live-Activity-Tap).
class ScheduleLiveActivityOpenRequest extends Notifier<String?> {
  @override
  String? build() => null;

  void open(String eventId) => state = eventId;

  void clear() => state = null;
}

final scheduleLiveActivityOpenRequestProvider =
    NotifierProvider<ScheduleLiveActivityOpenRequest, String?>(
  ScheduleLiveActivityOpenRequest.new,
);
