import 'package:flutter/material.dart';

import '../../email_confirmation/widgets/email_confirmation_ui.dart';

class GuardianPendingBody extends StatelessWidget {
  const GuardianPendingBody({
    super.key,
    required this.childNames,
    required this.metrics,
    required this.styles,
    this.isSending = false,
    this.sendError,
  });

  final List<String> childNames;
  final EmailConfirmationLayoutMetrics metrics;
  final EmailConfirmationTextStyles styles;
  final bool isSending;
  final String? sendError;

  @override
  Widget build(BuildContext context) {
    final namesText = childNames.isEmpty
        ? 'deine Kinder'
        : childNames.join(', ');

    return Padding(
      padding: EdgeInsets.only(top: metrics.topGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isSending) ...[
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: styles.accentColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Anfragen werden gesendet …',
              style: styles.body.copyWith(
                color: styles.accentColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: metrics.iconBodyGap),
          ],
          if (sendError != null) ...[
            Text(
              sendError!,
              style: styles.body.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],
          Icon(
            Icons.notifications_active_rounded,
            size: 96,
            color: styles.accentColor,
          ),
          SizedBox(height: metrics.iconBodyGap),
          SizedBox(
            width: double.infinity,
            child: Text(
              'Anfrage gesendet',
              style: styles.subheading,
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: metrics.headingBodyGap),
          SizedBox(
            width: double.infinity,
            child: Text.rich(
              TextSpan(
                style: styles.body,
                children: [
                  TextSpan(
                    text: namesText,
                    style: styles.emailHighlight.copyWith(
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const TextSpan(
                    text:
                        ' erhält bzw. erhalten eine Push-Benachrichtigung. '
                        'Jedes Kind muss die Verknüpfung in der App öffnen und '
                        'bestätigen. Sobald mindestens ein Kind bestätigt hat, '
                        'geht es hier automatisch weiter.',
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
