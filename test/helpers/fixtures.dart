import 'package:confident_me/models/affirmation.dart';
import 'package:confident_me/models/challenge_category.dart';
import 'package:confident_me/models/challenge_progress.dart';
import 'package:confident_me/models/confidence_challenge.dart';
import 'package:confident_me/models/difficulty.dart';
import 'package:confident_me/models/social_scenario.dart';

ConfidenceChallenge testChallenge(
  String id,
  ChallengeCategory category,
  Difficulty difficulty, {
  int minutes = 5,
}) =>
    ConfidenceChallenge(
      id: id,
      title: 'Title $id',
      description: 'Description for $id',
      category: category,
      difficulty: difficulty,
      estimatedMinutes: minutes,
      preparation: 'Prepare for $id',
      instructions: const ['First step', 'Second step', 'Third step'],
      reflectionPrompt: 'How did $id go?',
      xpReward: difficulty.defaultXp,
      easierStep: 'A smaller version of $id',
    );

/// Small library with a known shape (used by planner and widget tests).
List<ConfidenceChallenge> fixtureChallenges() => [
      testChallenge('conv_easy', ChallengeCategory.startingConversations,
          Difficulty.easy),
      testChallenge('daily_easy', ChallengeCategory.everydayInteractions,
          Difficulty.easy),
      testChallenge('quick_easy', ChallengeCategory.selfConfidence,
          Difficulty.easy, minutes: 2),
      testChallenge('opin_medium', ChallengeCategory.expressingOpinions,
          Difficulty.medium, minutes: 10),
      testChallenge('assert_medium', ChallengeCategory.assertiveness,
          Difficulty.medium),
      testChallenge('speak_hard', ChallengeCategory.publicSpeaking,
          Difficulty.hard, minutes: 20),
    ];

List<Affirmation> fixtureAffirmations() => const [
      Affirmation(id: 'a1', text: 'Fixture affirmation text.'),
    ];

ChallengeProgress record(
  String challengeId,
  ChallengeStatus status,
  DateTime at, {
  DateTime? postponedUntil,
}) =>
    ChallengeProgress(
      id: 'rec_${challengeId}_${status.id}_${at.microsecondsSinceEpoch}',
      challengeId: challengeId,
      status: status,
      updatedAt: at,
      startedAt: at,
      completedAt: status == ChallengeStatus.completed ? at : null,
      postponedUntil: postponedUntil,
    );

List<SocialScenario> fixtureScenarios() => const [
      SocialScenario(
        id: 'intro',
        title: 'Introducing yourself',
        description: 'Say who you are.',
        setting: 'A class',
        conversationStarters: ['Hi, I am [name].'],
        followUpQuestions: ['What brought you here?'],
        prompts: [
          PracticePrompt(heard: 'Nice to meet you!', suggestions: ['Nice to meet you too.']),
          PracticePrompt(heard: 'What do you do?', suggestions: ['I study [subject].']),
        ],
        listeningTips: ['Look at the person.'],
      ),
      SocialScenario(
        id: 'pause',
        title: 'Handling an awkward pause',
        description: 'It goes quiet.',
        setting: 'Anywhere',
        conversationStarters: ['Anything fun this week?'],
        followUpQuestions: [],
        prompts: [
          PracticePrompt(heard: '(silence)', suggestions: ['Take a breath.']),
        ],
        listeningTips: [],
      ),
    ];
