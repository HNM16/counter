import 'package:flutter/foundation.dart';

/// What happened as the result of a counting action.
enum CounterEventType {
  /// A regular repetition was counted.
  counted,

  /// The repetition completed a round; the next round starts automatically.
  roundCompleted,

  /// Input was ignored (session paused or ended).
  ignored,
}

/// Immutable state of a counting session plus the pure rules that advance it.
///
/// A session counts repetitions of one dhikr in rounds of [target]. When a
/// round completes, the next round begins automatically on the following
/// repetition. Time is tracked as *active* time: gaps between interactions
/// longer than [idleCap] are not counted, so leaving the app open does not
/// inflate the session duration.
@immutable
class CounterSession {
  const CounterSession({
    required this.dhikrId,
    required this.dhikrLabel,
    required this.dhikrArabic,
    required this.target,
    required this.startedAt,
    required this.lastActivityAt,
    this.id,
    this.totalCount = 0,
    this.activeDuration = Duration.zero,
    this.isPaused = false,
    this.endedAt,
  }) : assert(target > 0),
       assert(totalCount >= 0);

  factory CounterSession.start({
    required String dhikrId,
    required String dhikrLabel,
    required String dhikrArabic,
    required int target,
    required DateTime now,
  }) => CounterSession(
    dhikrId: dhikrId,
    dhikrLabel: dhikrLabel,
    dhikrArabic: dhikrArabic,
    target: target < 1 ? 1 : target,
    startedAt: now,
    lastActivityAt: now,
  );

  static const idleCap = Duration(seconds: 60);

  final int? id;
  final String dhikrId;

  /// Snapshot of the transliteration, so history survives library edits.
  final String dhikrLabel;
  final String dhikrArabic;

  /// Repetitions per round.
  final int target;
  final int totalCount;
  final Duration activeDuration;
  final bool isPaused;
  final DateTime startedAt;
  final DateTime lastActivityAt;
  final DateTime? endedAt;

  bool get isActive => endedAt == null;

  int get roundsCompleted => totalCount ~/ target;

  /// True right after a round was completed (and before the next count).
  bool get isAtRoundBoundary => totalCount > 0 && totalCount % target == 0;

  /// The number shown to the user: 1..target, or 0 before the first count.
  int get displayCount => isAtRoundBoundary ? target : totalCount % target;

  /// 1-based round the user is currently in (the completed round while at a
  /// boundary).
  int get currentRound => isAtRoundBoundary ? roundsCompleted : roundsCompleted + 1;

  double get roundProgress => displayCount / target;

  /// Active time including the in-flight interval since the last interaction.
  Duration liveDuration(DateTime now) {
    if (isPaused || !isActive || totalCount == 0) return activeDuration;
    return activeDuration + _cappedGap(now);
  }

  Duration _cappedGap(DateTime now) {
    final gap = now.difference(lastActivityAt);
    if (gap.isNegative) return Duration.zero;
    return gap > idleCap ? idleCap : gap;
  }

  /// Counts one repetition.
  (CounterSession, CounterEventType) increment(DateTime now) {
    if (isPaused || !isActive) return (this, CounterEventType.ignored);
    // The very first repetition starts the clock; time spent choosing a dhikr
    // before counting is not part of the session.
    final added = totalCount == 0 ? Duration.zero : _cappedGap(now);
    final next = copyWith(totalCount: totalCount + 1, activeDuration: activeDuration + added, lastActivityAt: now);
    final type = next.totalCount % target == 0 ? CounterEventType.roundCompleted : CounterEventType.counted;
    return (next, type);
  }

  /// Removes the most recent repetition (undo). Never goes below zero.
  CounterSession decrement(DateTime now) {
    if (!isActive || totalCount == 0) return this;
    return copyWith(totalCount: totalCount - 1, lastActivityAt: now);
  }

  CounterSession pause(DateTime now) {
    if (isPaused || !isActive) return this;
    final added = totalCount == 0 ? Duration.zero : _cappedGap(now);
    return copyWith(isPaused: true, activeDuration: activeDuration + added, lastActivityAt: now);
  }

  CounterSession resume(DateTime now) {
    if (!isPaused || !isActive) return this;
    return copyWith(isPaused: false, lastActivityAt: now);
  }

  /// Changes the round size. The total is preserved; rounds are re-derived.
  CounterSession withTarget(int newTarget) => copyWith(target: newTarget < 1 ? 1 : newTarget);

  CounterSession finish(DateTime now) {
    if (!isActive) return this;
    final paused = pause(now);
    return paused.copyWith(endedAt: now, isPaused: false);
  }

  CounterSession copyWith({
    int? id,
    int? target,
    int? totalCount,
    Duration? activeDuration,
    bool? isPaused,
    DateTime? lastActivityAt,
    DateTime? endedAt,
  }) {
    return CounterSession(
      id: id ?? this.id,
      dhikrId: dhikrId,
      dhikrLabel: dhikrLabel,
      dhikrArabic: dhikrArabic,
      target: target ?? this.target,
      totalCount: totalCount ?? this.totalCount,
      activeDuration: activeDuration ?? this.activeDuration,
      isPaused: isPaused ?? this.isPaused,
      startedAt: startedAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      endedAt: endedAt ?? this.endedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CounterSession &&
      other.id == id &&
      other.dhikrId == dhikrId &&
      other.dhikrLabel == dhikrLabel &&
      other.dhikrArabic == dhikrArabic &&
      other.target == target &&
      other.totalCount == totalCount &&
      other.activeDuration == activeDuration &&
      other.isPaused == isPaused &&
      other.startedAt == startedAt &&
      other.lastActivityAt == lastActivityAt &&
      other.endedAt == endedAt;

  @override
  int get hashCode => Object.hash(
    id,
    dhikrId,
    dhikrLabel,
    dhikrArabic,
    target,
    totalCount,
    activeDuration,
    isPaused,
    startedAt,
    lastActivityAt,
    endedAt,
  );

  @override
  String toString() => 'CounterSession(id: $id, dhikr: $dhikrId, total: $totalCount/$target, paused: $isPaused)';
}

/// Persistence contract for sessions.
abstract interface class SessionRepository {
  /// The unfinished session, if any.
  Future<CounterSession?> loadActive();

  /// Inserts a new session and returns it with its id.
  Future<CounterSession> insert(CounterSession session);

  /// Persists [session]. When [dayDelta] is non-zero, the per-day count for
  /// the day of [at] is adjusted in the same transaction.
  Future<void> save(CounterSession session, {int dayDelta = 0, DateTime? at});

  Future<void> delete(int id);

  /// Finished and in-progress sessions, newest first.
  Future<List<CounterSession>> history({int limit = 50, int offset = 0});

  /// Deletes every session (history and statistics).
  Future<void> clearAll();
}
