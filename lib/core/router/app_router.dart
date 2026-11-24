import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/dhikr/presentation/dhikr_editor_screen.dart';
import '../../features/dhikr/presentation/dhikr_library_screen.dart';
import '../../features/goals/presentation/goals_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/reminders/presentation/reminders_screen.dart';
import '../../features/settings/presentation/about_screen.dart';
import '../../features/settings/presentation/customization_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/statistics/presentation/history_screen.dart';
import '../../features/statistics/presentation/statistics_screen.dart';
import '../../features/tasbih/presentation/tasbih_screen.dart';
import '../../shared/widgets/app_shell.dart';
import 'routes.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.home,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.home, builder: (context, state) => const HomeScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.tasbih, builder: (context, state) => const TasbihScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.stats, builder: (context, state) => const StatisticsScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.settings, builder: (context, state) => const SettingsScreen())],
          ),
        ],
      ),
      GoRoute(
        path: Routes.library,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const DhikrLibraryScreen(),
        routes: [
          GoRoute(
            path: 'new',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) => const DhikrEditorScreen(),
          ),
          GoRoute(
            path: 'edit/:id',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) => DhikrEditorScreen(dhikrId: state.pathParameters['id']),
          ),
        ],
      ),
      GoRoute(
        path: Routes.goals,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const GoalsScreen(),
      ),
      GoRoute(
        path: Routes.reminders,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const RemindersScreen(),
      ),
      GoRoute(
        path: Routes.history,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: Routes.customize,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CustomizationScreen(),
      ),
      GoRoute(
        path: Routes.about,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AboutScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
