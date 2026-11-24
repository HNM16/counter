import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../settings/domain/app_settings.dart';

/// Surface treatment used by the procedural bead renderer.
enum BeadFinish { wood, stone, marble, gem, pearl }

/// Everything the renderer needs to draw one material.
@immutable
class BeadSpec {
  const BeadSpec({
    required this.finish,
    required this.base,
    required this.highlight,
    required this.shade,
    required this.texture,
    required this.gloss,
    this.translucency = 0,
    this.seed = 0,
  });

  final BeadFinish finish;
  final Color base;
  final Color highlight;
  final Color shade;

  /// Grain / vein / cloud color.
  final Color texture;

  /// 0..1 strength of specular highlights.
  final double gloss;

  /// 0..1 inner glow for translucent gemstones.
  final double translucency;
  final int seed;

  factory BeadSpec.of(BeadMaterial material, {Color? tint}) {
    final s = _natural[material]!;
    if (tint == null) return s;
    return BeadSpec(
      finish: s.finish,
      base: tint,
      highlight: ColorTools.lighten(tint, 0.22),
      shade: ColorTools.darken(tint, 0.30),
      texture: s.finish == BeadFinish.marble ? ColorTools.darken(tint, 0.28) : ColorTools.darken(tint, 0.22),
      gloss: s.gloss,
      translucency: s.translucency,
      seed: s.seed,
    );
  }

  /// The untinted color of [material], used for swatches.
  static Color naturalColor(BeadMaterial material) => _natural[material]!.base;

  static final Map<BeadMaterial, BeadSpec> _natural = {
    BeadMaterial.walnut: const BeadSpec(
      finish: BeadFinish.wood,
      base: Color(0xFF6B4226),
      highlight: Color(0xFFA2724B),
      shade: Color(0xFF2B180C),
      texture: Color(0xFF3A2112),
      gloss: 0.38,
      seed: 1,
    ),
    BeadMaterial.sandalwood: const BeadSpec(
      finish: BeadFinish.wood,
      base: Color(0xFFB98B5B),
      highlight: Color(0xFFE2BE91),
      shade: Color(0xFF6A462A),
      texture: Color(0xFF835B36),
      gloss: 0.26,
      seed: 2,
    ),
    BeadMaterial.ebony: const BeadSpec(
      finish: BeadFinish.wood,
      base: Color(0xFF2A2420),
      highlight: Color(0xFF5E544C),
      shade: Color(0xFF090706),
      texture: Color(0xFF120E0B),
      gloss: 0.55,
      seed: 3,
    ),
    BeadMaterial.onyx: const BeadSpec(
      finish: BeadFinish.stone,
      base: Color(0xFF19191C),
      highlight: Color(0xFF4E4E55),
      shade: Color(0xFF020203),
      texture: Color(0xFF3A3A40),
      gloss: 0.95,
      seed: 4,
    ),
    BeadMaterial.turquoise: const BeadSpec(
      finish: BeadFinish.stone,
      base: Color(0xFF2E9F98),
      highlight: Color(0xFF86D9CE),
      shade: Color(0xFF125A55),
      texture: Color(0xFF4A3A2A),
      gloss: 0.6,
      seed: 5,
    ),
    BeadMaterial.amethyst: const BeadSpec(
      finish: BeadFinish.gem,
      base: Color(0xFF6C3E9E),
      highlight: Color(0xFFB993E4),
      shade: Color(0xFF2B1150),
      texture: Color(0xFFD7BEF5),
      gloss: 0.9,
      translucency: 0.75,
      seed: 6,
    ),
    BeadMaterial.marble: const BeadSpec(
      finish: BeadFinish.marble,
      base: Color(0xFFEDEAE4),
      highlight: Color(0xFFFFFFFF),
      shade: Color(0xFFB3ADA2),
      texture: Color(0xFF8F897F),
      gloss: 0.72,
      seed: 7,
    ),
    BeadMaterial.jade: const BeadSpec(
      finish: BeadFinish.gem,
      base: Color(0xFF3C8C61),
      highlight: Color(0xFF93D3A9),
      shade: Color(0xFF13432B),
      texture: Color(0xFFBFE8CC),
      gloss: 0.78,
      translucency: 0.5,
      seed: 8,
    ),
    BeadMaterial.pearl: const BeadSpec(
      finish: BeadFinish.pearl,
      base: Color(0xFFF0EBE2),
      highlight: Color(0xFFFFFFFF),
      shade: Color(0xFFC4B9A9),
      texture: Color(0xFFE6D3DA),
      gloss: 0.62,
      seed: 9,
    ),
    BeadMaterial.amber: const BeadSpec(
      finish: BeadFinish.gem,
      base: Color(0xFFD08718),
      highlight: Color(0xFFF8CC6E),
      shade: Color(0xFF743A04),
      texture: Color(0xFFFFE0A0),
      gloss: 0.86,
      translucency: 0.85,
      seed: 10,
    ),
  };

  @override
  bool operator ==(Object other) =>
      other is BeadSpec &&
      other.finish == finish &&
      other.base == base &&
      other.highlight == highlight &&
      other.shade == shade &&
      other.texture == texture &&
      other.gloss == gloss &&
      other.translucency == translucency &&
      other.seed == seed;

  @override
  int get hashCode => Object.hash(finish, base, highlight, shade, texture, gloss, translucency, seed);
}

/// Bead tints offered in addition to each material's natural color.
abstract final class BeadTints {
  static const options = <Color>[
    Color(0xFF7A4B2A), // chestnut
    Color(0xFF1E1E22), // charcoal
    Color(0xFF2B8C84), // turquoise
    Color(0xFF6A4294), // violet
    Color(0xFF2F7A55), // emerald
    Color(0xFF9E2F2A), // garnet
    Color(0xFF1F4E7A), // lapis
    Color(0xFFC79A3B), // honey
    Color(0xFFE9E4DA), // bone
  ];
}
