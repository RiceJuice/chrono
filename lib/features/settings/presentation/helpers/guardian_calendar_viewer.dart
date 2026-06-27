import 'package:chronoapp/features/login/domain/models/login_flow_role_ids.dart';
import 'package:chronoapp/features/login/domain/models/profile_gate_data.dart';
import 'package:chronoapp/features/settings/data/models/profile_snapshot.dart';

/// Elternteil mit bestätigter Kind-Verknüpfung — Kalenderfilter kommen vom Kind.
bool isGuardianCalendarViewer({
  required ProfileGateData gate,
  ProfileSnapshot? ownProfile,
}) {
  if (!gate.hasSession) return false;

  final role = (ownProfile?.role ?? gate.role)?.trim();
  if (role == LoginFlowRoleIds.student) return false;

  return gate.hasConfirmedGuardianLink;
}
