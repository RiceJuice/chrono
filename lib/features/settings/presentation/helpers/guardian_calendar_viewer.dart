import 'package:chronoapp/features/login/domain/models/login_flow_role_ids.dart';
import 'package:chronoapp/features/login/domain/models/profile_gate_data.dart';
import 'package:chronoapp/features/settings/data/models/profile_snapshot.dart';

/// Elternteil mit bestätigter Kind-Verknüpfung — Kalenderfilter kommen vom Kind.
bool isGuardianCalendarViewer({
  required ProfileGateData gate,
  ProfileSnapshot? ownProfile,
}) {
  if (!gate.hasSession) return false;

  final role = (gate.role ?? ownProfile?.role)?.trim();
  if (role == LoginFlowRoleIds.student) return false;
  // Losing the final link must not turn a parent into an unrestricted viewer.
  if (role == LoginFlowRoleIds.guardian) return true;

  return gate.hasConfirmedGuardianLink;
}
