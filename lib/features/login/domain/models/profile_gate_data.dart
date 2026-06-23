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
    required this.activeChildId,
    required this.hasAnyGuardianLink,
    required this.hasConfirmedGuardianLink,
    required this.hasPendingGuardianLink,
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
        onboardingCompletedAt = null,
        activeChildId = null,
        hasAnyGuardianLink = false,
        hasConfirmedGuardianLink = false,
        hasPendingGuardianLink = false;

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
  final String? activeChildId;
  final bool hasAnyGuardianLink;
  final bool hasConfirmedGuardianLink;
  final bool hasPendingGuardianLink;

  bool get isOnboardingComplete => onboardingCompletedAt != null;

  ProfileGateData copyWith({
    bool? hasSession,
    bool? emailConfirmed,
    String? firstName,
    String? lastName,
    String? className,
    String? schoolTrack,
    String? role,
    String? voice,
    String? choir,
    DateTime? onboardingCompletedAt,
    String? activeChildId,
    bool? hasAnyGuardianLink,
    bool? hasConfirmedGuardianLink,
    bool? hasPendingGuardianLink,
  }) {
    return ProfileGateData(
      hasSession: hasSession ?? this.hasSession,
      emailConfirmed: emailConfirmed ?? this.emailConfirmed,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      className: className ?? this.className,
      schoolTrack: schoolTrack ?? this.schoolTrack,
      role: role ?? this.role,
      voice: voice ?? this.voice,
      choir: choir ?? this.choir,
      onboardingCompletedAt:
          onboardingCompletedAt ?? this.onboardingCompletedAt,
      activeChildId: activeChildId ?? this.activeChildId,
      hasAnyGuardianLink: hasAnyGuardianLink ?? this.hasAnyGuardianLink,
      hasConfirmedGuardianLink:
          hasConfirmedGuardianLink ?? this.hasConfirmedGuardianLink,
      hasPendingGuardianLink:
          hasPendingGuardianLink ?? this.hasPendingGuardianLink,
    );
  }
}
