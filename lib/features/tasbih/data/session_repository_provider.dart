import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../domain/counter_session.dart';
import 'sqlite_session_repository.dart';

final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => SqliteSessionRepository(ref.watch(appDatabaseProvider)),
);
