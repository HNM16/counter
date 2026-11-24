import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/tasbih/domain/counter_session.dart';

void main() {
  final t0 = DateTime(2026, 3, 1, 8);

  CounterSession start({int target = 33}) =>
      CounterSession.start(dhikrId: 'x', dhikrLabel: 'X', dhikrArabic: 'س', target: target, now: t0);

  CounterSession countN(CounterSession s, int n, {Duration every = const Duration(seconds: 1)}) {
    var cur = s;
    var at = cur.lastActivityAt;
    for (var i = 0; i < n; i++) {
      at = at.add(every);
      cur = cur.increment(at).$1;
    }
    return cur;
  }

  group('counting', () {
    test('increments by exactly one per call', () {
      final (s, type) = start().increment(t0.add(const Duration(seconds: 1)));
      expect(s.totalCount, 1);
      expect(s.displayCount, 1);
      expect(type, CounterEventType.counted);
    });

    test('completes a round on the target and starts the next automatically', () {
      var s = countN(start(), 32);
      expect(s.displayCount, 32);
      expect(s.roundsCompleted, 0);

      final (atBoundary, type) = s.increment(s.lastActivityAt.add(const Duration(seconds: 1)));
      expect(type, CounterEventType.roundCompleted);
      expect(atBoundary.totalCount, 33);
      expect(atBoundary.roundsCompleted, 1);
      expect(atBoundary.isAtRoundBoundary, isTrue);
      // The completed round stays visible as "33 of 33" until the next count.
      expect(atBoundary.displayCount, 33);
      expect(atBoundary.currentRound, 1);
      expect(atBoundary.roundProgress, 1.0);

      s = countN(atBoundary, 1);
      expect(s.displayCount, 1);
      expect(s.currentRound, 2);
      expect(s.roundsCompleted, 1);
    });

    test('tracks many rounds correctly', () {
      final s = countN(start(target: 33), 100);
      expect(s.totalCount, 100);
      expect(s.roundsCompleted, 3);
      expect(s.displayCount, 1);
      expect(s.currentRound, 4);
    });

    test('a target of one completes a round on every count', () {
      var s = start(target: 1);
      for (var i = 1; i <= 3; i++) {
        final r = s.increment(t0.add(Duration(seconds: i)));
        expect(r.$2, CounterEventType.roundCompleted);
        s = r.$1;
      }
      expect(s.roundsCompleted, 3);
    });

    test('rejects invalid targets by clamping to one', () {
      expect(start(target: 0).target, 1);
      expect(start().withTarget(-5).target, 1);
    });

    test('changing the target keeps the total and re-derives rounds', () {
      final s = countN(start(target: 33), 66).withTarget(100);
      expect(s.totalCount, 66);
      expect(s.roundsCompleted, 0);
      expect(s.displayCount, 66);
    });
  });

  group('pause, undo and finish', () {
    test('a paused session ignores counts', () {
      final paused = countN(start(), 5).pause(t0.add(const Duration(seconds: 10)));
      final (s, type) = paused.increment(t0.add(const Duration(seconds: 11)));
      expect(type, CounterEventType.ignored);
      expect(s.totalCount, 5);
    });

    test('resume allows counting again', () {
      final resumed = countN(start(), 5).pause(t0.add(const Duration(seconds: 10))).resume(t0.add(const Duration(minutes: 5)));
      expect(resumed.isPaused, isFalse);
      expect(resumed.increment(t0.add(const Duration(minutes: 5, seconds: 1))).$1.totalCount, 6);
    });

    test('undo removes the last count and never goes below zero', () {
      var s = countN(start(), 2);
      s = s.decrement(t0).decrement(t0).decrement(t0);
      expect(s.totalCount, 0);
    });

    test('undo across a round boundary goes back into the previous round', () {
      final s = countN(start(), 34).decrement(t0);
      expect(s.totalCount, 33);
      expect(s.isAtRoundBoundary, isTrue);
      expect(s.displayCount, 33);
    });

    test('a finished session ignores further input', () {
      final ended = countN(start(), 3).finish(t0.add(const Duration(minutes: 1)));
      expect(ended.isActive, isFalse);
      expect(ended.increment(t0.add(const Duration(minutes: 2))).$2, CounterEventType.ignored);
      expect(ended.decrement(t0).totalCount, 3);
    });
  });

  group('active time', () {
    test('the first count starts the clock', () {
      final (s, _) = start().increment(t0.add(const Duration(minutes: 3)));
      expect(s.activeDuration, Duration.zero);
    });

    test('accumulates the time between counts', () {
      final s = countN(start(), 11, every: const Duration(seconds: 2));
      // 10 gaps of 2s after the first count.
      expect(s.activeDuration, const Duration(seconds: 20));
    });

    test('caps idle gaps so leaving the app open does not inflate duration', () {
      var s = countN(start(), 2);
      s = s.increment(s.lastActivityAt.add(const Duration(hours: 2))).$1;
      expect(s.activeDuration, const Duration(seconds: 1) + CounterSession.idleCap);
    });

    test('pausing banks the in-flight time and stops the clock', () {
      final counted = countN(start(), 2);
      final paused = counted.pause(counted.lastActivityAt.add(const Duration(seconds: 5)));
      expect(paused.activeDuration, const Duration(seconds: 6));
      expect(paused.liveDuration(paused.lastActivityAt.add(const Duration(hours: 1))), paused.activeDuration);
    });

    test('live duration includes the current interval up to the cap', () {
      final s = countN(start(), 2);
      expect(s.liveDuration(s.lastActivityAt.add(const Duration(seconds: 7))), const Duration(seconds: 8));
      expect(s.liveDuration(s.lastActivityAt.add(const Duration(hours: 7))), const Duration(seconds: 1) + CounterSession.idleCap);
    });

    test('a clock that moves backwards adds no time', () {
      final s = countN(start(), 2);
      final (next, _) = s.increment(s.lastActivityAt.subtract(const Duration(minutes: 10)));
      expect(next.activeDuration, s.activeDuration);
    });
  });
}
