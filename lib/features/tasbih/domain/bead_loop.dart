/// Kinds of items threaded on the tasbih string, in order.
enum LoopItemKind { imam, bead, separator }

/// Pure layout model of a tasbih loop.
///
/// A real tasbih is a closed loop: an imam (head) bead with a tassel, followed
/// by the counting beads, optionally split into thirds by separator beads on a
/// 99-bead tasbih. While counting, beads pass one at a time through a gap held
/// between the fingers. This class answers two questions:
///
/// 1. Where is the loop "cursor" (in item slots) for a given total count?
/// 2. Given a cursor, where along the string does each item sit, relative to
///    the gap?
///
/// Every item occupies one slot of length `d`. Positions are expressed as a
/// distance `s` along the string, measured in the direction beads travel.
class BeadLoop {
  BeadLoop(this.beadCount) : assert(beadCount > 0), items = _build(beadCount) {
    _beadSlots = [
      for (var i = 0; i < items.length; i++)
        if (items[i] == LoopItemKind.bead) i,
    ];
  }

  final int beadCount;
  final List<LoopItemKind> items;
  late final List<int> _beadSlots;

  /// Number of slots in the loop.
  int get length => items.length;

  static List<LoopItemKind> _build(int beads) {
    final out = <LoopItemKind>[LoopItemKind.imam];
    // Separators split 99-bead (and other multiples of 3 above 33) tasbihs
    // into equal thirds, the way physical tasbihs are made.
    final third = beads >= 66 && beads % 3 == 0 ? beads ~/ 3 : 0;
    for (var i = 0; i < beads; i++) {
      if (third > 0 && i > 0 && i % third == 0) out.add(LoopItemKind.separator);
      out.add(LoopItemKind.bead);
    }
    return out;
  }

  /// Slot index of the [n]th counting bead (0-based).
  int slotOfBead(int n) => _beadSlots[n % beadCount];

  /// Continuous cursor for [totalCount]. Increases monotonically with the
  /// count, by one slot per bead plus any separator/imam passed on the way.
  double cursorFor(int totalCount) {
    final loops = totalCount ~/ beadCount;
    return (loops * length + slotOfBead(totalCount % beadCount)).toDouble();
  }

  /// Signed slot offset of item [index] relative to [cursor], wrapped into
  /// `[-length/2, length/2)`. Zero means "waiting at the gap, next to count";
  /// negative values have already passed through the gap.
  double relativeSlot(int index, double cursor) {
    final half = length / 2;
    var rel = (index - cursor) % length;
    if (rel >= half) rel -= length;
    return rel;
  }

  /// Distance along the string for an item at relative slot [rel].
  ///
  /// [anchor] is where the next uncounted bead rests, [slot] the slot length
  /// and [gap] the bare string between the two clusters. Items still to be
  /// counted queue up before the anchor; counted items stack after the gap;
  /// the item in transit glides across the gap.
  static double distanceFor(double rel, {required double anchor, required double slot, required double gap}) {
    if (rel >= 0) return anchor - rel * slot;
    if (rel <= -1) return anchor + gap - rel * slot;
    return anchor - rel * (gap + slot);
  }

  /// Chooses the animation target equivalent to [target] (modulo the loop)
  /// that is reached by the shortest natural motion from [from].
  ///
  /// Small backward steps (undo) animate backwards; any larger jump (reset,
  /// session change) rolls forward so beads never rewind across the screen.
  double animationTarget(double from, double target) {
    final diff = target - from;
    if (diff >= 0 && diff <= length) return target;
    if (diff < 0 && diff >= -3) return target;
    if (diff > length) return target - (diff / length).floor() * length;
    final loops = ((from - target) / length).floor() + 1;
    return target + loops * length;
  }
}
