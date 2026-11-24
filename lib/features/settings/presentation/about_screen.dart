import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/arabic_text.dart';
import '../../../shared/widgets/geometric_pattern.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;

    Widget para(String title, String body) => Padding(
      padding: const EdgeInsets.only(bottom: Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: text.titleMedium),
          const SizedBox(height: Space.xxs),
          Text(body, style: text.bodyMedium),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.xxl),
        children: [
          Center(child: AppEmblem(size: 64, color: c.accent, accent: c.gold)),
          const SizedBox(height: Space.md),
          Center(child: Text('Sakina', style: text.headlineLarge)),
          const Center(child: ArabicText('سَكِينَة', size: 26)),
          Center(child: Text('Tranquility', style: text.bodyMedium)),
          const SizedBox(height: Space.xxl),
          para(
            'A calm companion for remembrance',
            'Sakina is a digital tasbih for daily dhikr. Count with a realistic bead tasbih or a minimal digital '
                'counter, set gentle goals, and see your consistency over time.',
          ),
          para(
            'Private by design',
            'Everything stays on your device. Sakina has no account, no analytics and makes no network requests. '
                'Your sessions, goals and settings are stored locally and survive restarts.',
          ),
          para(
            'About the library',
            'Suggested repetition numbers are shown only where a well-known narration mentions one, with its '
                'source for further reading. Where no number is mentioned, you choose your own. Sakina does not '
                'issue religious rulings; please consult a qualified scholar for guidance.',
          ),
          para(
            'Typography',
            'Arabic is set in Amiri, interface text in Manrope and numerals in Cormorant Garamond, all under the '
                'SIL Open Font License and bundled with the app.',
          ),
          const SizedBox(height: Space.md),
          Text('Version 1.0.0', style: text.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
