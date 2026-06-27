import 'models/homework_contribution.dart';
import 'models/homework_fragment.dart';
import 'models/homework_peer_suggestion.dart';
import 'models/homework_task.dart';

bool isPeerSuggestionAccepted({
  required HomeworkPeerSuggestion suggestion,
  required Iterable<HomeworkTask> ownTasks,
}) {
  return ownTasks.any(
    (task) =>
        task.subjectId == suggestion.subjectId &&
        task.fragments.any(
          (fragment) =>
              fragment.canonicalKey == suggestion.fragment.canonicalKey,
        ),
  );
}

List<HomeworkPeerSuggestion> computePendingPeerSuggestions({
  required Iterable<HomeworkContribution> contributions,
  required String ownProfileId,
  required Iterable<HomeworkTask> ownTasks,
  required Set<String> dismissedKeys,
  Set<String> optimisticHandledKeys = const {},
}) {
  final ownContributedKeys = <String>{};
  for (final contribution in contributions) {
    if (contribution.profileId != ownProfileId) continue;
    for (final fragment in contribution.fragments) {
      ownContributedKeys.add(fragment.canonicalKey);
    }
  }

  final pending = <HomeworkPeerSuggestion>[];
  final seenDismissalKeys = <String>{};

  for (final contribution in contributions) {
    if (contribution.profileId == ownProfileId) continue;

    for (final fragment in contribution.fragments) {
      if (ownContributedKeys.contains(fragment.canonicalKey)) continue;

      final dismissalKey = homeworkPeerDismissalKey(
        canonicalKey: fragment.canonicalKey,
        subjectId: contribution.subjectId,
        lessonDate: contribution.lessonDate,
      );
      if (dismissedKeys.contains(dismissalKey)) continue;
      if (optimisticHandledKeys.contains(dismissalKey)) continue;
      if (!seenDismissalKeys.add(dismissalKey)) continue;

      final suggestion = HomeworkPeerSuggestion(
        fragment: fragment,
        subjectId: contribution.subjectId,
        contributionId: contribution.id,
        lessonDate: contribution.lessonDate,
        dismissalKey: dismissalKey,
      );

      if (isPeerSuggestionAccepted(
        suggestion: suggestion,
        ownTasks: ownTasks,
      )) {
        continue;
      }

      pending.add(suggestion);
    }
  }

  return pending;
}

List<HomeworkFragment> mergeClassFragments(
  Iterable<HomeworkContribution> contributions, {
  String? subjectId,
  String? excludeProfileId,
}) {
  final seen = <String>{};
  final merged = <HomeworkFragment>[];

  for (final contribution in contributions) {
    if (subjectId != null && contribution.subjectId != subjectId) continue;
    if (excludeProfileId != null && contribution.profileId == excludeProfileId) {
      continue;
    }
    for (final fragment in contribution.fragments) {
      if (seen.add(fragment.canonicalKey)) {
        merged.add(fragment);
      }
    }
  }

  return merged;
}

List<HomeworkFragment> computeDeltaToUpload({
  required List<HomeworkFragment> localFragments,
  required Iterable<HomeworkContribution> classContributions,
  required String profileId,
}) {
  final peerHashes = <String>{};
  for (final contribution in classContributions) {
    if (contribution.profileId == profileId) continue;
    peerHashes.addAll(contribution.fragmentHashes);
    for (final fragment in contribution.fragments) {
      peerHashes.add(fragment.canonicalKey);
    }
  }

  return localFragments
      .where((f) => !peerHashes.contains(f.canonicalKey))
      .toList(growable: false);
}

List<String> fragmentHashesFor(List<HomeworkFragment> fragments) {
  return fragments.map((f) => f.canonicalKey).toList(growable: false);
}

List<HomeworkFragment> mergeOwnContributionFragments({
  required List<HomeworkFragment>? existingOwn,
  required List<HomeworkFragment> delta,
}) {
  final seen = <String>{};
  final merged = <HomeworkFragment>[];

  for (final fragment in [...?existingOwn, ...delta]) {
    if (seen.add(fragment.canonicalKey)) {
      merged.add(fragment);
    }
  }

  return merged;
}
