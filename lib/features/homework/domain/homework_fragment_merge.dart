import 'models/homework_contribution.dart';
import 'models/homework_fragment.dart';

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
