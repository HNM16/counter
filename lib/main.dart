import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'bootstrap.dart';

Future<void> main() async {
  final container = await bootstrap();
  runApp(UncontrolledProviderScope(container: container, child: const SakinaApp()));
}
