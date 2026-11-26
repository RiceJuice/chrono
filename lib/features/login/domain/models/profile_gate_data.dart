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
    this.artsSubject,
    this.languageSubject,
    this.timetableChoices = const {},
    required this.role,
    required this.voice,
    required this.choir,
    required this.diet,
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
      artsSubject = null,
      languageSubject = null,
      timetableChoices = const {},
      role = null,
      voice = null,
      choir = null,
      diet = null,
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
  final String? artsSubject;
  final String? languageSubject;
  final Map<String, dynamic> timetableChoices;
  final String? role;
  final String? voice;
  final String? choir;
  final String? diet;
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
    String? artsSubject,
    String? languageSubject,
    Map<String, dynamic>? timetableChoices,
    String? role,
    String? voice,
    String? choir,
    String? diet,
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
      artsSubject: artsSubject ?? this.artsSubject,
      languageSubject: languageSubject ?? this.languageSubject,
      timetableChoices: timetableChoices ?? this.timetableChoices,
      role: role ?? this.role,
      voice: voice ?? this.voice,
      choir: choir ?? this.choir,
      diet: diet ?? this.diet,
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
