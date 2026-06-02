import 'package:supabase_flutter/supabase_flutter.dart';

import 'calendar_image_url_resolver.dart';

/// Gemeinsame Kalender-Bilddienste (ein Resolver + URL-Cache für die ganze App).
abstract final class CalendarImages {
  static final CalendarImageUrlResolver urlResolver = CalendarImageUrlResolver(
    supabase: Supabase.instance.client,
  );
}
