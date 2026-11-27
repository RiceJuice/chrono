import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/login_flow_role_ids.dart';
import '../routes/login_paths.dart';
import '../state/login_flow_draft.dart';
import '../utils/login_flow_route.dart';
import 'login_flow_spacing.dart';
import 'login_split_screen.dart';
import 'top_bar/login_top_bar.dart';
import 'top_bar/step_indicator.dart';

/// Top-Bar und Schritt-Indikator — scrollen mit dem Seiteninhalt mit.
class LoginFlowChrome extends StatelessWidget {
  const LoginFlowChrome({
    super.key,
    required this.location,
    this.horizontalPadding = 20,
  });

  final String location;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final back = LoginFlowRoute.backPath(location);
    final step = LoginFlowRoute.stepNumber(location);
    final totalSteps =
        LoginFlowDraft.instance.role == LoginFlowRoleIds.guardian ||
            location == LoginPaths.selectChild
        ? 4
        : 5;
    final indicator = step == null
        ? null
        : LoginStepIndicator(currentStep: step, totalSteps: totalSteps);
    final isStart = location == LoginPaths.login;
    final isCompact = LoginFlowSpacing.isCompact(context);
    final isDesktop =
        MediaQuery.sizeOf(context).width >= LoginSplitScreen.defaultBreakpoint;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        isCompact ? 4 : 10,
        horizontalPadding,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LoginTopBar(
            onBack: back != null ? () => context.go(back) : null,
            middle: isDesktop && !isStart && step != null ? indicator : null,
          ),
          if (isDesktop && !isStart && step != null)
            SizedBox(height: isCompact ? 24 : 50)
          else if (!isStart && step != null) ...[
            SizedBox(height: LoginFlowSpacing.gapAfterTopBar(context)),
            indicator!,
            SizedBox(height: LoginFlowSpacing.gapAfterStepIndicator(context)),
          ],
        ],
      ),
    );
  }
}
