import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/tasbih/domain/bead_loop.dart';

void main() {
  group('structure', () {
    test('33 beads: imam followed by 33 beads, no separators', () {
      final loop = BeadLoop(33);
      expect(loop.length, 34);
      expect(loop.items.first, LoopItemKind.imam);
      expect(loop.items.where((k) => k == LoopItemKind.bead).length, 33);
      expect(loop.items.contains(LoopItemKind.separator), isFalse);
    });

    test('99 beads are split into thirds by two separators', () {
      final loop = BeadLoop(99);
      expect(loop.length, 102);
      final separators = [
        for (var i = 0; i < loop.length; i++)
          if (loop.items[i] == LoopItemKind.separator) i,
      ];
      expect(separators, [34, 68]);
      // 33 beads before the first separator (after the imam), 33 between, 33 after.
      expect(loop.slotOfBead(32), 33);
      expect(loop.slotOfBead(33), 35);
      expect(loop.slotOfBead(66), 69);
    });
  });

  group('cursor', () {
    test('starts with the first bead at the gap and the imam just counted', () {
      final loop = BeadLoop(33);
      final c = loop.cursorFor(0);
      expect(loop.relativeSlot(1, c), 0); // first bead waits at the gap
      expect(loop.relativeSlot(0, c), -1); // imam has passed
    });

    test('advances one slot per bead', () {
      final loop = BeadLoop(33);
      for (var n = 0; n < 32; n++) {
        expect(loop.cursorFor(n + 1) - loop.cursorFor(n), 1);
      }
    });

    test('completing a loop passes the imam (two slots)', () {
      final loop = BeadLoop(33);
      expect(loop.cursorFor(33) - loop.cursorFor(32), 2);
    });

    test('passing a separator moves two slots', () {
      final loop = BeadLoop(99);
      expect(loop.cursorFor(33) - loop.cursorFor(32), 2);
      expect(loop.cursorFor(34) - loop.cursorFor(33), 1);
    });

    test('is strictly increasing over many loops', () {
      final loop = BeadLoop(99);
      for (var n = 0; n < 400; n++) {
        expect(loop.cursorFor(n + 1), greaterThan(loop.cursorFor(n)));
      }
    });
  });

  group('layout', () {
    test('relative slots wrap into half the loop on each side', () {
      final loop = BeadLoop(33);
      final c = loop.cursorFor(5);
      for (var i = 0; i < loop.length; i++) {
        final rel = loop.relativeSlot(i, c);
        expect(rel, greaterThanOrEqualTo(-loop.length / 2));
        expect(rel, lessThan(loop.length / 2));
      }
    });

    test('distance along the string is continuous through the gap', () {
      const anchor = 100.0, slot = 20.0, gap = 60.0;
      double d(double rel) => BeadLoop.distanceFor(rel, anchor: anchor, slot: slot, gap: gap);
      expect(d(0), anchor);
      expect(d(-1), anchor + gap + slot);
      expect(d(-0.5), closeTo(anchor + (gap + slot) / 2, 1e-9));
      expect(d(0.0001), closeTo(d(-0.0001), 0.02));
      expect(d(-0.9999), closeTo(d(-1.0001), 0.02));
      // Waiting beads queue before the anchor, counted beads after the gap.
      expect(d(3), anchor - 3 * slot);
      expect(d(-3), anchor + gap + 3 * slot);
    });

    test('undo animates backwards; resets roll forwards', () {
      final loop = BeadLoop(33);
      final at10 = loop.cursorFor(10);
      expect(loop.animationTarget(at10, loop.cursorFor(9)), loop.cursorFor(9));
      final resetTarget = loop.animationTarget(at10, loop.cursorFor(0));
      expect(resetTarget, greaterThan(at10));
      expect((resetTarget - loop.cursorFor(0)) % loop.length, 0);
    });

    test('a huge forward jump is reduced to less than one loop', () {
      final loop = BeadLoop(33);
      final from = loop.cursorFor(3);
      final to = loop.animationTarget(from, loop.cursorFor(3 + 33 * 50));
      expect(to - from, inInclusiveRange(0, loop.length));
    });
  });
}
