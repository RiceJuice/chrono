import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../data/klassen_repository.dart';

final klassenRepositoryProvider = Provider<KlassenRepository>((ref) {
  return KlassenRepository(ref.watch(dbProvider));
});

final availableClassesProvider = StreamProvider<List<String>>((ref) {
  final repository = ref.watch(klassenRepositoryProvider);
  return repository.watchClasses();
});
