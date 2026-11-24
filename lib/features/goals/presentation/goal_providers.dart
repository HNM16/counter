import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../statistics/presentation/stats_providers.dart';
import '../data/sqlite_goal_repository.dart';
import '../domain/goal.dart';

final goalRepositoryProvider = Provider<GoalRepository>((ref) => SqliteGoalRepository(ref.watch(appDatabaseProvider)));

class GoalsController extends AsyncNotifier<List<Goal>> {
  GoalRepository get _repo => ref.read(goalRepositoryProvider);

  @override
  Future<List<Goal>> build() {
    // Goals are removed alongside deleted custom dhikr.
    ref.watch(structureRevisionProvider);
    return ref.watch(goalRepositoryProvider).all();
  }

  Future<void> add({required int target, String? dhikrId}) async {
    await _repo.insert(Goal(target: target, dhikrId: dhikrId, createdAt: ref.read(clockProvider)()));
    await _refresh();
  }

  Future<void> save(Goal goal) async {
    await _repo.update(goal);
    await _refresh();
  }

  Future<void> remove(Goal goal) async {
    final id = goal.id;
    if (id == null) return;
    state = AsyncData([...?state.value?.where((g) => g.id != id)]);
    await _repo.delete(id);
    await _refresh();
  }

  Future<void> _refresh() async {
    final items = await _repo.all();
    if (ref.mounted) state = AsyncData(items);
  }
}

final goalsProvider = AsyncNotifierProvider<GoalsController, List<Goal>>(GoalsController.new);

final goalProgressProvider = FutureProvider<List<GoalProgress>>((ref) async {
  final goals = await ref.watch(goalsProvider.future);
  final today = await ref.watch(todayByDhikrProvider.future);
  return GoalProgress.compute(goals, today);
});
