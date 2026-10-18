import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../models/challenge_category.dart';
import '../../models/difficulty.dart';
import '../../models/user_profile.dart';
import 'profile_controller.dart';

class OnboardingState {
  const OnboardingState({
    this.step = 0,
    this.name = '',
    this.goals = const {},
    this.focus,
    this.socialDifficulty = 3,
    this.smallGoal = '',
  });

  final int step;
  final String name;
  final Set<ChallengeCategory> goals;
  final String? focus;
  final int socialDifficulty;
  final String smallGoal;

  OnboardingState copyWith({
    int? step,
    String? name,
    Set<ChallengeCategory>? goals,
    String? focus,
    bool clearFocus = false,
    int? socialDifficulty,
    String? smallGoal,
  }) =>
      OnboardingState(
        step: step ?? this.step,
        name: name ?? this.name,
        goals: goals ?? this.goals,
        focus: clearFocus ? null : (focus ?? this.focus),
        socialDifficulty: socialDifficulty ?? this.socialDifficulty,
        smallGoal: smallGoal ?? this.smallGoal,
      );
}

/// Holds the in-progress answers. Every question is optional, so [finish] works
/// at any point. If a profile already exists (editing later), answers are
/// pre-filled from it.
class OnboardingController extends AutoDisposeNotifier<OnboardingState> {
  /// name + four questions
  static const stepCount = 5;

  /// People who find social situations harder (3-5) start with Beginner
  /// challenges; people who find them easier (1-2) start at Intermediate.
  /// They can change this later and can always use "Make this easier".
  static Difficulty difficultyFor(int socialDifficulty) =>
      socialDifficulty >= 3 ? Difficulty.easy : Difficulty.medium;

  @override
  OnboardingState build() {
    final existing = ref.read(profileProvider);
    if (existing == null) return const OnboardingState();
    return OnboardingState(
      name: existing.displayName,
      goals: existing.selectedGoals.toSet(),
      focus: existing.improvementFocus,
      socialDifficulty: existing.socialDifficulty,
      smallGoal: existing.smallGoal,
    );
  }

  void setName(String value) => state = state.copyWith(name: value);

  void setSmallGoal(String value) => state = state.copyWith(smallGoal: value);

  void setSocialDifficulty(int level) =>
      state = state.copyWith(socialDifficulty: level.clamp(1, 5).toInt());

  void toggleGoal(ChallengeCategory category) {
    final next = {...state.goals};
    if (!next.add(category)) next.remove(category);
    state = state.copyWith(goals: next);
  }

  /// Tapping the selected option again clears it.
  void setFocus(String option) {
    state = state.focus == option
        ? state.copyWith(clearFocus: true)
        : state.copyWith(focus: option);
  }

  void next() {
    if (state.step < stepCount - 1) {
      state = state.copyWith(step: state.step + 1);
    }
  }

  void back() {
    if (state.step > 0) state = state.copyWith(step: state.step - 1);
  }

  UserProfile buildProfile({UserProfile? existing, String? id, DateTime? now}) {
    final s = state;
    return UserProfile(
      id: existing?.id ?? id ?? const Uuid().v4(),
      createdAt: existing?.createdAt ?? now ?? DateTime.now(),
      displayName: s.name.trim(),
      selectedGoals: ChallengeCategory.values.where(s.goals.contains).toList(),
      improvementFocus: s.focus,
      socialDifficulty: s.socialDifficulty,
      smallGoal: s.smallGoal.trim(),
      preferredDifficulty: difficultyFor(s.socialDifficulty),
    );
  }

  Future<void> finish() async {
    final existing = ref.read(profileProvider);
    await ref
        .read(profileProvider.notifier)
        .save(buildProfile(existing: existing));
  }
}

final onboardingControllerProvider =
    AutoDisposeNotifierProvider<OnboardingController, OnboardingState>(
  OnboardingController.new,
);
