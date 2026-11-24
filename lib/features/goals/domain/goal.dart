import 'package:flutter/foundation.dart';

/// A daily repetition goal, for one dhikr or for all dhikr combined.
@immutable
class Goal {
  const Goal({required this.target, required this.createdAt, this.id, this.dhikrId});

  static const presets = [33, 99, 100, 1000];

  final int? id;

  /// `null` means the goal counts every dhikr.
  final String? dhikrId;
  final int target;
  final DateTime createdAt;

  bool get isOverall => dhikrId == null;

  Goal copyWith({int? id, String? dhikrId, bool overall = false, int? target}) => Goal(
    id: id ?? this.id,
    dhikrId: overall ? null : (dhikrId ?? this.dhikrId),
    target: target ?? this.target,
    createdAt: createdAt,
  );

  @override
  bool operator ==(Object other) =>
      other is Goal && other.id == id && other.dhikrId == dhikrId && other.target == target;

  @override
  int get hashCode => Object.hash(id, dhikrId, target);
}

/// A goal together with today's progress towards it.
@immutable
class GoalProgress {
  const GoalProgress({required this.goal, required this.current});

  final Goal goal;
  final int current;

  bool get isComplete => current >= goal.target;

  double get fraction => goal.target == 0 ? 1 : (current / goal.target).clamp(0.0, 1.0);

  int get remaining => isComplete ? 0 : goal.target - current;

  /// Computes progress for [goals] from today's counts per dhikr.
  static List<GoalProgress> compute(List<Goal> goals, Map<String, int> todayByDhikr) {
    final total = todayByDhikr.values.fold<int>(0, (a, b) => a + b);
    return [
      for (final g in goals) GoalProgress(goal: g, current: g.isOverall ? total : (todayByDhikr[g.dhikrId] ?? 0)),
    ];
  }

  /// Combined completion across goals, each capped at its own target, so one
  /// over-achieved goal cannot hide another unfinished one.
  static double overall(List<GoalProgress> items) {
    if (items.isEmpty) return 0;
    final target = items.fold<int>(0, (a, p) => a + p.goal.target);
    final done = items.fold<int>(0, (a, p) => a + (p.current > p.goal.target ? p.goal.target : p.current));
    return target == 0 ? 0 : done / target;
  }

  /// Goals whose target was crossed when today's count for [dhikrId] moved
  /// from [before] to [before] + 1 (and the overall total from [totalBefore]).
  static List<Goal> crossedBy(
    List<Goal> goals, {
    required String dhikrId,
    required int before,
    required int totalBefore,
  }) {
    return [
      for (final g in goals)
        if (g.isOverall
            ? totalBefore < g.target && totalBefore + 1 >= g.target
            : g.dhikrId == dhikrId && before < g.target && before + 1 >= g.target)
          g,
    ];
  }
}

abstract interface class GoalRepository {
  Future<List<Goal>> all();

  Future<Goal> insert(Goal goal);

  Future<void> update(Goal goal);

  Future<void> delete(int id);
}
