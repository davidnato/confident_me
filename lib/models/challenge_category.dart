/// The eight challenge categories. [id] is stored on disk, so never change an
/// existing id - only add new ones.
enum ChallengeCategory {
  startingConversations('starting_conversations', 'Starting conversations'),
  everydayInteractions('everyday_interactions', 'Everyday interactions'),
  expressingOpinions('expressing_opinions', 'Expressing opinions'),
  assertiveness('assertiveness', 'Assertiveness'),
  publicSpeaking('public_speaking', 'Public speaking'),
  socialParticipation('social_participation', 'Social participation'),
  selfConfidence('self_confidence', 'Self-confidence'),
  awkwardMoments('awkward_moments', 'Handling awkward moments');

  const ChallengeCategory(this.id, this.label);

  final String id;
  final String label;

  static ChallengeCategory? fromId(String? id) {
    for (final category in values) {
      if (category.id == id) return category;
    }
    return null;
  }
}
