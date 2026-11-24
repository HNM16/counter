import 'package:flutter/services.dart';

/// Distinct tactile signatures for the moments that matter while counting.
enum HapticPattern {
  /// A single count on the bead tasbih: very light, like a bead clicking.
  bead,

  /// A single count on the digital counter: crisp button press.
  press,

  /// A full round completed.
  round,

  /// A daily goal reached.
  goal,

  /// Small UI selection changes.
  selection,
}

abstract interface class HapticsService {
  Future<void> play(HapticPattern pattern);
}

class SystemHapticsService implements HapticsService {
  const SystemHapticsService();

  @override
  Future<void> play(HapticPattern pattern) async {
    switch (pattern) {
      case HapticPattern.bead:
      case HapticPattern.selection:
        await HapticFeedback.selectionClick();
      case HapticPattern.press:
        await HapticFeedback.lightImpact();
      case HapticPattern.round:
        await HapticFeedback.mediumImpact();
        await Future<void>.delayed(const Duration(milliseconds: 110));
        await HapticFeedback.lightImpact();
      case HapticPattern.goal:
        await HapticFeedback.heavyImpact();
        await Future<void>.delayed(const Duration(milliseconds: 140));
        await HapticFeedback.mediumImpact();
        await Future<void>.delayed(const Duration(milliseconds: 140));
        await HapticFeedback.lightImpact();
    }
  }
}
