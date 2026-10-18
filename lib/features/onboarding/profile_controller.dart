import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../models/user_profile.dart';

/// App-wide holder of the current profile. `null` means onboarding has not
/// been completed or skipped yet.
class ProfileController extends Notifier<UserProfile?> {
  @override
  UserProfile? build() => ref.read(profileRepositoryProvider).load();

  Future<void> save(UserProfile profile) async {
    await ref.read(profileRepositoryProvider).save(profile);
    state = profile;
  }

  Future<void> continueAsGuest() => save(UserProfile.guest());

  Future<void> clear() async {
    await ref.read(profileRepositoryProvider).clear();
    state = null;
  }
}

final profileProvider =
    NotifierProvider<ProfileController, UserProfile?>(ProfileController.new);
