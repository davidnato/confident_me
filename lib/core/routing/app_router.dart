import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/challenges/challenge_detail_screen.dart';
import '../../features/challenges/challenge_library_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/home/home_shell.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/onboarding/profile_controller.dart';
import '../../features/onboarding/welcome_screen.dart';
import '../../features/placeholder/phase_placeholder_screen.dart';

abstract class AppRoutes {
  static const welcome = '/welcome';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const challenges = '/challenges';
  static const practice = '/practice';
  static const journal = '/journal';
  static const progress = '/progress';

  static String challengeDetail(String id) => '$challenges/$id';
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
              builder: (context, state) => const PhasePlaceholderScreen(
                title: 'Practice',
                icon: Icons.self_improvement_rounded,
                phase: 4,
                description:
                    'Guided breathing and conversation scenarios you can '
                    'rehearse at your own pace.',
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.journal,
              builder: (context, state) => const PhasePlaceholderScreen(
                title: 'Journal',
                icon: Icons.edit_note_rounded,
                phase: 4,
                description:
                    'A private place to reflect on what happened, what you '
                    'feared, and what you learned. Stored on this device.',
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.progress,
              builder: (context, state) => const PhasePlaceholderScreen(
                title: 'Progress',
                icon: Icons.insights_rounded,
                phase: 5,
                description:
                    'A gentle look at the effort you have put in, with '
                    'personal milestones and a weekly activity calendar.',
              ),
            ),
          ]),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
