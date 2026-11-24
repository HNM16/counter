import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/services/haptics_service.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/tap_guard.dart';
import '../../dhikr/data/dhikr_seed.dart';
import '../../dhikr/domain/dhikr.dart';
import '../../dhikr/presentation/dhikr_providers.dart';
import '../../goals/domain/goal.dart';
import '../../goals/presentation/goal_providers.dart';
import '../../settings/domain/app_settings.dart';
import '../../settings/presentation/settings_controller.dart';
import '../../statistics/presentation/stats_providers.dart';
import '../data/session_repository_provider.dart';
import '../domain/counter_session.dart';

enum TasbihEventKind { roundCompleted, goalReached }

/// A moment worth celebrating, surfaced once to the UI.
@immutable
class TasbihEvent {
  const TasbihEvent({required this.serial, required this.kind, this.round = 0, this.goal});

  /// Unique, increasing id so listeners can react exactly once.
  final int serial;
  final TasbihEventKind kind;
  final int round;
  final Goal? goal;
}

@immutable
class TasbihState {
  const TasbihState(this.session, {this.event});

  final CounterSession session;
  final TasbihEvent? event;
}

/// Owns the live counting session.
///
/// Every interaction updates in-memory state synchronously (so the UI reacts
/// on the same frame) and is then written to SQLite through a serial queue,
/// which guarantees writes land in order and the counter survives restarts.
class TasbihController extends AsyncNotifier<TasbihState> {
  final _guard = TapGuard();
  Future<void> _writes = Future.value();
  Timer? _revisionDebounce;
  final Map<String, int> _today = {};
  String _todayKey = '';
  int _serial = 0;

  DateTime _now() => ref.read(clockProvider)();

  SessionRepository get _repo => ref.read(sessionRepositoryProvider);

  AppSettings get _settings => ref.read(settingsProvider);

  @override
  Future<TasbihState> build() async {
    ref.onDispose(() => _revisionDebounce?.cancel());
    // Warm up goals so the first count can already detect goal completion.
    ref.read(goalsProvider);
    ref.listen(structureRevisionProvider, (_, _) => _reloadToday());

    final repo = ref.watch(sessionRepositoryProvider);
    await _reloadToday();
    final active = await repo.loadActive();
    if (active != null) return TasbihState(active);

    final dhikr = await _initialDhikr();
    final session = await repo.insert(_startFor(dhikr, dhikr.suggestedCount ?? _settings.defaultTarget));
    return TasbihState(session);
  }

  Future<Dhikr> _initialDhikr() async {
    final dhikrRepo = ref.read(dhikrRepositoryProvider);
    final last = _settings.lastDhikrId;
    final byLast = last == null ? null : await dhikrRepo.byId(last);
    if (byLast != null) return byLast;
    final byDefault = await dhikrRepo.byId(DhikrSeed.defaultId);
    if (byDefault != null) return byDefault;
    final all = await dhikrRepo.all();
    return all.isNotEmpty ? all.first : DhikrSeed.entries.first;
  }

  CounterSession _startFor(Dhikr d, int target) => CounterSession.start(
    dhikrId: d.id,
    dhikrLabel: d.transliteration,
    dhikrArabic: d.arabic,
    target: target,
    now: _now(),
  );

  CounterSession? get _session => state.value?.session;

  // ---------------------------------------------------------------- counting

  /// Counts one repetition. Returns false when the input was ignored.
  bool increment() {
    final current = state.value;
    if (current == null) return false;
    final now = _now();
    if (!_guard.accept(now)) return false;

    final s = current.session;
    if (s.isPaused) {
      // A tap on a paused counter resumes it rather than counting, so a
      // stray touch while paused can never add a repetition.
      resume();
      return false;
    }

    final (next, type) = s.increment(now);
    if (type == CounterEventType.ignored) return false;

    _rollDay(now);
    final before = _today[s.dhikrId] ?? 0;
    final totalBefore = _today.values.fold<int>(0, (a, b) => a + b);
    _today[s.dhikrId] = before + 1;

    final goals = ref.read(goalsProvider).value ?? const <Goal>[];
    final crossed = GoalProgress.crossedBy(goals, dhikrId: s.dhikrId, before: before, totalBefore: totalBefore);

    TasbihEvent? event;
    if (crossed.isNotEmpty) {
      event = TasbihEvent(serial: ++_serial, kind: TasbihEventKind.goalReached, goal: crossed.first);
    } else if (type == CounterEventType.roundCompleted) {
      event = TasbihEvent(serial: ++_serial, kind: TasbihEventKind.roundCompleted, round: next.roundsCompleted);
    }

    state = AsyncData(TasbihState(next, event: event ?? current.event));
    _feedback(type, goalReached: crossed.isNotEmpty);
    _persist(next, dayDelta: 1, at: now);
    return true;
  }

  /// Undoes the last repetition.
  void undo() {
    final current = state.value;
    if (current == null || current.session.totalCount == 0) return;
    final now = _now();
    final s = current.session;
    final next = s.decrement(now);
    _rollDay(now);
    final today = _today[s.dhikrId] ?? 0;
    if (today > 0) _today[s.dhikrId] = today - 1;
    state = AsyncData(TasbihState(next, event: current.event));
    if (_settings.hapticsEnabled) ref.read(hapticsServiceProvider).play(HapticPattern.selection);
    _persist(next, dayDelta: -1, at: now);
  }

  void pause() => _replace((s, now) => s.pause(now));

  void resume() {
    _guard.reset();
    _replace((s, now) => s.resume(now));
  }

  void togglePause() => (_session?.isPaused ?? false) ? resume() : pause();

  void setTarget(int target) {
    if (target < 1) return;
    _replace((s, _) => s.withTarget(target));
  }

  void _replace(CounterSession Function(CounterSession s, DateTime now) change) {
    final current = state.value;
    if (current == null) return;
    final next = change(current.session, _now());
    if (next == current.session) return;
    state = AsyncData(TasbihState(next, event: current.event));
    _persist(next);
  }

  // --------------------------------------------------------------- lifecycle

  /// Saves the session to history and starts a fresh one with the same dhikr.
  /// Returns the finished session, or null when there was nothing to save.
  Future<CounterSession?> finish() async {
    final s = _session;
    if (s == null || s.totalCount == 0) return null;
    final ended = s.finish(_now());
    await _flush();
    await _repo.save(ended);
    await _startNew(s.dhikrId, s.dhikrLabel, s.dhikrArabic, s.target);
    _bumpStructure();
    return ended;
  }

  /// Clears the counter. When [keepInHistory] is false, the repetitions are
  /// discarded and removed from statistics.
  Future<void> reset({required bool keepInHistory}) async {
    final s = _session;
    if (s == null || s.totalCount == 0) return;
    if (keepInHistory) {
      await finish();
      return;
    }
    await _flush();
    if (s.id != null) await _repo.delete(s.id!);
    await _startNew(s.dhikrId, s.dhikrLabel, s.dhikrArabic, s.target);
    _bumpStructure();
  }

  /// Switches to [dhikr]. A session with repetitions is saved to history
  /// first; returns true when that happened.
  Future<bool> selectDhikr(Dhikr dhikr, {int? target}) async {
    await ref.read(settingsProvider.notifier).update((st) => st.copyWith(lastDhikrId: dhikr.id));
    final s = _session;
    final t = target ?? dhikr.suggestedCount ?? _settings.defaultTarget;
    if (s != null && s.dhikrId == dhikr.id) {
      if (target != null) setTarget(target);
      return false;
    }
    await _flush();
    var saved = false;
    if (s != null) {
      if (s.totalCount > 0) {
        await _repo.save(s.finish(_now()));
        saved = true;
      } else if (s.id != null) {
        await _repo.delete(s.id!);
      }
    }
    await _startNew(dhikr.id, dhikr.transliteration, dhikr.arabic, t);
    _bumpStructure();
    return saved;
  }

  /// Deletes every session (history and statistics) and starts a fresh
  /// session with the current dhikr.
  Future<void> clearAllHistory() async {
    final s = _session;
    await _flush();
    await _repo.clearAll();
    if (s != null) {
      await _startNew(s.dhikrId, s.dhikrLabel, s.dhikrArabic, s.target);
    }
    _bumpStructure();
  }

  Future<void> _startNew(String id, String label, String arabic, int target) async {
    final fresh = await _repo.insert(
      CounterSession.start(dhikrId: id, dhikrLabel: label, dhikrArabic: arabic, target: target, now: _now()),
    );
    _guard.reset();
    if (ref.mounted) state = AsyncData(TasbihState(fresh));
  }

  /// Waits until every pending write has reached the database.
  Future<void> _flush() => _writes;

  /// Public flush used when the app moves to the background.
  Future<void> flush() async {
    final s = _session;
    if (s != null && !s.isPaused && s.totalCount > 0) {
      // Bank the active time accumulated so far without pausing.
      _persist(s);
    }
    await _flush();
  }

  // ---------------------------------------------------------------- internals

  void _persist(CounterSession s, {int dayDelta = 0, DateTime? at}) {
    final repo = _repo;
    _writes = _writes.then((_) => repo.save(s, dayDelta: dayDelta, at: at)).catchError((Object e, StackTrace st) {
      debugPrint('Failed to persist session: $e\n$st');
    });
    _revisionDebounce?.cancel();
    _revisionDebounce = Timer(const Duration(milliseconds: 450), () {
      if (ref.mounted) ref.read(countingRevisionProvider.notifier).bump();
    });
  }

  void _bumpStructure() => ref.read(structureRevisionProvider.notifier).bump();

  void _rollDay(DateTime now) {
    final key = DayKey.of(now);
    if (key != _todayKey) {
      _todayKey = key;
      _today.clear();
    }
  }

  Future<void> _reloadToday() async {
    await _flush();
    final now = _now();
    final counts = await ref.read(statsRepositoryProvider).countsByDhikrOn(now);
    _todayKey = DayKey.of(now);
    _today
      ..clear()
      ..addAll(counts);
  }

  void _feedback(CounterEventType type, {required bool goalReached}) {
    final settings = _settings;
    if (settings.hapticsEnabled) {
      final pattern = goalReached
          ? HapticPattern.goal
          : type == CounterEventType.roundCompleted
          ? HapticPattern.round
          : settings.counterMode == CounterMode.beads
          ? HapticPattern.bead
          : HapticPattern.press;
      ref.read(hapticsServiceProvider).play(pattern);
    }
    if (settings.soundEnabled) {
      final sound = ref.read(soundServiceProvider);
      if (goalReached || type == CounterEventType.roundCompleted) {
        sound.play(SoundCue.chime);
      } else {
        sound.play(SoundCue.click);
      }
    }
  }
}

final tasbihControllerProvider = AsyncNotifierProvider<TasbihController, TasbihState>(TasbihController.new);
