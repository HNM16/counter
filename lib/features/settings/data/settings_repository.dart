import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/app_settings.dart';

/// Persists [AppSettings] as individual SharedPreferences keys so that adding a
/// new setting never invalidates the ones already stored.
class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _p = 'settings.';

  AppSettings load() {
    const d = AppSettings();
    T pick<T extends Enum>(List<T> values, String key, T fallback) {
      final name = _prefs.getString('$_p$key');
      return values.where((v) => v.name == name).firstOrNull ?? fallback;
    }

    Color color(String key, Color fallback) {
      final v = _prefs.getInt('$_p$key');
      return v == null ? fallback : Color(v);
    }

    final tint = _prefs.getInt('${_p}beadTint');
    final beadCount = _prefs.getInt('${_p}beadCount') ?? d.beadCount;

    return AppSettings(
      themeMode: pick(AppThemeMode.values, 'themeMode', d.themeMode),
      accent: color('accent', d.accent),
      counterMode: pick(CounterMode.values, 'counterMode', d.counterMode),
      tasbihStyle: pick(TasbihStyle.values, 'tasbihStyle', d.tasbihStyle),
      beadMaterial: pick(BeadMaterial.values, 'beadMaterial', d.beadMaterial),
      beadTint: tint == null ? null : Color(tint),
      beadSize: pick(BeadSize.values, 'beadSize', d.beadSize),
      beadCount: AppSettings.beadCountOptions.contains(beadCount) ? beadCount : d.beadCount,
      tasbihBackground: pick(TasbihBackground.values, 'tasbihBackground', d.tasbihBackground),
      digitalDesign: pick(DigitalDesign.values, 'digitalDesign', d.digitalDesign),
      digitalLayout: pick(DigitalLayout.values, 'digitalLayout', d.digitalLayout),
      customDigitalBackground: color('customDigitalBackground', d.customDigitalBackground),
      customDigitalAccent: color('customDigitalAccent', d.customDigitalAccent),
      defaultTarget: (_prefs.getInt('${_p}defaultTarget') ?? d.defaultTarget).clamp(1, 100000),
      hapticsEnabled: _prefs.getBool('${_p}hapticsEnabled') ?? d.hapticsEnabled,
      soundEnabled: _prefs.getBool('${_p}soundEnabled') ?? d.soundEnabled,
      arabicScale: (_prefs.getDouble('${_p}arabicScale') ?? d.arabicScale).clamp(
        AppSettings.minArabicScale,
        AppSettings.maxArabicScale,
      ),
      textScale: (_prefs.getDouble('${_p}textScale') ?? d.textScale).clamp(
        AppSettings.minTextScale,
        AppSettings.maxTextScale,
      ),
      showTransliteration: _prefs.getBool('${_p}showTransliteration') ?? d.showTransliteration,
      showTranslation: _prefs.getBool('${_p}showTranslation') ?? d.showTranslation,
      lastDhikrId: _prefs.getString('${_p}lastDhikrId'),
    );
  }

  Future<void> save(AppSettings s) async {
    await Future.wait([
      _prefs.setString('${_p}themeMode', s.themeMode.name),
      _prefs.setInt('${_p}accent', s.accent.toARGB32()),
      _prefs.setString('${_p}counterMode', s.counterMode.name),
      _prefs.setString('${_p}tasbihStyle', s.tasbihStyle.name),
      _prefs.setString('${_p}beadMaterial', s.beadMaterial.name),
      if (s.beadTint == null) _prefs.remove('${_p}beadTint') else _prefs.setInt('${_p}beadTint', s.beadTint!.toARGB32()),
      _prefs.setString('${_p}beadSize', s.beadSize.name),
      _prefs.setInt('${_p}beadCount', s.beadCount),
      _prefs.setString('${_p}tasbihBackground', s.tasbihBackground.name),
      _prefs.setString('${_p}digitalDesign', s.digitalDesign.name),
      _prefs.setString('${_p}digitalLayout', s.digitalLayout.name),
      _prefs.setInt('${_p}customDigitalBackground', s.customDigitalBackground.toARGB32()),
      _prefs.setInt('${_p}customDigitalAccent', s.customDigitalAccent.toARGB32()),
      _prefs.setInt('${_p}defaultTarget', s.defaultTarget),
      _prefs.setBool('${_p}hapticsEnabled', s.hapticsEnabled),
      _prefs.setBool('${_p}soundEnabled', s.soundEnabled),
      _prefs.setDouble('${_p}arabicScale', s.arabicScale),
      _prefs.setDouble('${_p}textScale', s.textScale),
      _prefs.setBool('${_p}showTransliteration', s.showTransliteration),
      _prefs.setBool('${_p}showTranslation', s.showTranslation),
      if (s.lastDhikrId == null) _prefs.remove('${_p}lastDhikrId') else _prefs.setString('${_p}lastDhikrId', s.lastDhikrId!),
    ]);
  }

  Future<void> clear() async {
    final keys = _prefs.getKeys().where((k) => k.startsWith(_p)).toList();
    for (final k in keys) {
      await _prefs.remove(k);
    }
  }
}
