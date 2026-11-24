/// Rejects input events that arrive faster than a human can intentionally
/// count. This prevents double counting from touch bounce, a tap and a swipe
/// being recognised for the same gesture, or two fingers landing together.
///
/// The threshold is deliberately well below a fast deliberate cadence
/// (roughly 8 taps per second, i.e. 125 ms apart).
class TapGuard {
  TapGuard({this.minInterval = const Duration(milliseconds: 70)});

  final Duration minInterval;
  DateTime? _last;

  /// Returns true when an input at [now] should be accepted.
  bool accept(DateTime now) {
    final last = _last;
    if (last != null) {
      final elapsed = now.difference(last);
      // A clock that jumped backwards (manual time change) must not lock input.
      if (!elapsed.isNegative && elapsed < minInterval) return false;
    }
    _last = now;
    return true;
  }

  void reset() => _last = null;
}
