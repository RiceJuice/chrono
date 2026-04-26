/// Projected snapshot der auth- und profile-Felder, die für das Onboarding-Gate
/// relevant sind. Wird vom ProfileGateNotifier gefüllt und vom Router gelesen.
class ProfileGateData {
  const ProfileGateData({
    required this.hasSession,
    required this.emailConfirmed,
    required this.firstName,
    required this.lastName,
    required this.className,
    required this.schoolTrack,
    required this.role,
    required this.voice,
    required this.choir,
    required this.onboardingCompletedAt,
  });

  const ProfileGateData.signedOut()
      : hasSession = false,
        emailConfirmed = false,
        firstName = null,
        lastName = null,
        className = null,
        schoolTrack = null,
        role = null,
        voice = null,
        choir = null,
        onboardingCompletedAt = null;

  final bool hasSession;
  final bool emailConfirmed;
  final String? firstName;
  final String? lastName;
  final String? className;
  final String? schoolTrack;
  final String? role;
  final String? voice;
  final String? choir;
  final DateTime? onboardingCompletedAt;

  bool get isOnboardingComplete => onboardingCompletedAt != null;
}
