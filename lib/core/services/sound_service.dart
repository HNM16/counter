import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

enum SoundCue { click, chime }

abstract interface class SoundService {
  Future<void> init();
  void play(SoundCue cue);
  Future<void> dispose();
}

/// Plays bundled, offline sound assets. Audio mixes with other apps and
/// respects the iOS silent switch so counting never interrupts music or calls.
class AudioSoundService implements SoundService {
  AudioPool? _clickPool;
  AudioPool? _chimePool;
  Future<void>? _initializing;

  static final _context = AudioContextConfig(
    focus: AudioContextConfigFocus.mixWithOthers,
    respectSilence: true,
  ).build();

  @override
  Future<void> init() => _initializing ??= _load();

  Future<void> _load() async {
    try {
      await AudioPlayer.global.setAudioContext(_context);
      _clickPool = await AudioPool.create(
        source: AssetSource('sounds/bead_click.wav'),
        maxPlayers: 4,
        minPlayers: 2,
        audioContext: _context,
        playerMode: PlayerMode.lowLatency,
      );
      _chimePool = await AudioPool.create(
        source: AssetSource('sounds/round_chime.wav'),
        maxPlayers: 2,
        audioContext: _context,
      );
    } catch (error, stack) {
      // Sound is a nicety; never let an audio backend failure break counting.
      debugPrint('Sound unavailable: $error\n$stack');
    }
  }

  @override
  void play(SoundCue cue) {
    final pool = switch (cue) {
      SoundCue.click => _clickPool,
      SoundCue.chime => _chimePool,
    };
    if (pool == null) {
      init();
      return;
    }
    pool.start(volume: cue == SoundCue.click ? 0.55 : 0.45).catchError((Object e) {
      debugPrint('Sound playback failed: $e');
      return () async {};
    });
  }

  @override
  Future<void> dispose() async {
    await _clickPool?.dispose();
    await _chimePool?.dispose();
  }
}

/// Used in tests and on platforms without audio support.
class SilentSoundService implements SoundService {
  const SilentSoundService();

  @override
  Future<void> init() async {}

  @override
  void play(SoundCue cue) {}

  @override
  Future<void> dispose() async {}
}
