import 'package:flutter/material.dart';

import 'email_confirmation_ui.dart';

class EmailConfirmationBody extends StatelessWidget {
  const EmailConfirmationBody({
    super.key,
    required this.email,
    required this.metrics,
    required this.styles,
  });

  final String email;
  final EmailConfirmationLayoutMetrics metrics;
  final EmailConfirmationTextStyles styles;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: metrics.topGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.mail_rounded, size: 96, color: styles.accentColor),
          SizedBox(height: metrics.iconBodyGap),
          SizedBox(
            width: double.infinity,
            child: Text(
              'Prüfe dein E-Mail-Postfach',
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
                  const TextSpan(text: 'Wir haben eine Bestätigungs-E-Mail an '),
                  TextSpan(text: email, style: styles.emailHighlight),
                  const TextSpan(
                    text:
                        ' geschickt. Tippe in der Nachricht auf den Link. '
                        'Sobald du bestätigt hast, geht es hier automatisch weiter.',
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
