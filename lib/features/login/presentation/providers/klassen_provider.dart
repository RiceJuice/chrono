import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../data/klassen_repository.dart';

final klassenRepositoryProvider = Provider<KlassenRepository>((ref) {
  return KlassenRepository(
    ref.watch(dbProvider),
    loadRemoteClasses: () async {
      final rows = await Supabase.instance.client
          .from('klassen')
          .select('class_name');
      return rows.map((row) => row['class_name']?.toString() ?? '').toList();
    },
  );
});

final availableClassesProvider = StreamProvider<List<String>>((ref) {
  final repository = ref.watch(klassenRepositoryProvider);
  return repository.watchClasses();
});
