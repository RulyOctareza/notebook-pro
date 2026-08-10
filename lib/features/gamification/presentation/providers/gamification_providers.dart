import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:notebook_pro/features/gamification/domain/achievement_catalog.dart';
import 'package:notebook_pro/features/gamification/domain/entities/achievement.dart';
import 'package:notebook_pro/features/gamification/domain/entities/gamification_profile.dart';
import 'package:notebook_pro/features/notes/presentation/providers/notes_providers.dart';

final gamificationProfileProvider = StreamProvider<GamificationProfile>((
  ref,
) async* {
  final repo = ref.watch(gamificationRepositoryProvider);
  await repo.getProfile(); // ensure row exists
  yield* repo.watchProfile();
});

final unlockedAchievementsProvider = StreamProvider<Set<String>>((ref) {
  return ref.watch(gamificationRepositoryProvider).watchUnlockedIds();
});

final achievementsWithStatusProvider = Provider<List<(Achievement, bool)>>((
  ref,
) {
  final unlocked = ref.watch(unlockedAchievementsProvider).valueOrNull ?? {};
  return kAchievementCatalog.map((a) => (a, unlocked.contains(a.id))).toList();
});

/// Recently unlocked achievements for toast UI.
final pendingUnlocksProvider = StateProvider<List<Achievement>>((ref) => []);
