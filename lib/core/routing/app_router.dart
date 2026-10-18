import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/challenges/challenge_detail_screen.dart';
import '../../features/challenges/challenge_library_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/home/home_shell.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/onboarding/profile_controller.dart';
import '../../features/onboarding/welcome_screen.dart';
import '../../features/affirmations/affirmations_screen.dart';
import '../../features/breathing/breathing_screen.dart';
import '../../features/journal/journal_editor_screen.dart';
import '../../features/journal/journal_screen.dart';
import '../../features/practice/practice_hub_screen.dart';
import '../../features/social_practice/rehearsal_screen.dart';
import '../../features/social_practice/scenario_screen.dart';
import '../../features/progress/progress_screen.dart';
import '../../features/settings/settings_screen.dart';

abstract class AppRoutes {
  static const welcome = '/welcome';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const challenges = '/challenges';
  static const practice = '/practice';
  static const journal = '/journal';
  static const progress = '/progress';
  static const settings = '/settings';

  static String challengeDetail(String id) => '$challenges/$id';

  static const breathing = '/practice/breathing';
  static const affirmations = '/practice/affirmations';
  static String scenario(String id) => '/practice/scenario/$id';
  static String scenarioRehearse(String id) => '/practice/scenario/$id/rehearse';

  static const journalNew = '/journal/new';
  static String journalEdit(String id) => '/journal/edit/$id';
}

final routerProvider = Provider<GoRouter>((ref) {
  // The router is created once. When the profile changes (onboarding done or
  // data deleted) we only ask it to re-run `redirect`, so navigation history
  // is not thrown away.
  final refresh = ValueNotifier<int>(0);
  ref.listen(profileProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: refresh,
    redirect: (context, state) {
      final hasProfile = ref.read(profileProvider) != null;
      final location = state.matchedLocation;
      final inIntro =
          location == AppRoutes.welcome || location == AppRoutes.onboarding;
      if (!hasProfile && !inIntro) return AppRoutes.welcome;
      if (hasProfile && location == AppRoutes.welcome) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => const HomeScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.challenges,
              builder: (context, state) => const ChallengeLibraryScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) => ChallengeDetailScreen(
                    challengeId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.practice,
              builder: (context, state) => const PracticeHubScreen(),
              routes: [
                GoRoute(
                  path: 'breathing',
                  builder: (context, state) => const BreathingScreen(),
                ),
                GoRoute(
                  path: 'affirmations',
                  builder: (context, state) => const AffirmationsScreen(),
                ),
                GoRoute(
                  path: 'scenario/:id',
                  builder: (context, state) => ScenarioScreen(
                    scenarioId: state.pathParameters['id']!,
                  ),
                  routes: [
                    GoRoute(
                      path: 'rehearse',
                      builder: (context, state) => RehearsalScreen(
                        scenarioId: state.pathParameters['id']!,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.journal,
              builder: (context, state) => const JournalScreen(),
              routes: [
                GoRoute(
                  path: 'new',
                  builder: (context, state) => const JournalEditorScreen(),
                ),
                GoRoute(
                  path: 'edit/:id',
                  builder: (context, state) => JournalEditorScreen(
                    entryId: state.pathParameters['id'],
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.progress,
              builder: (context, state) => const ProgressScreen(),
            ),
          ]),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
