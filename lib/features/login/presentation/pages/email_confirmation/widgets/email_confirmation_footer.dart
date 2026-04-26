import 'package:flutter/material.dart';

import '../../credentials/credentials_page.dart';
import 'email_confirmation_ui.dart';

class EmailConfirmationFooter extends StatelessWidget {
  const EmailConfirmationFooter({
    super.key,
    required this.styles,
    required this.resendBusy,
    required this.onResend,
  });

  final EmailConfirmationTextStyles styles;
  final bool resendBusy;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: CredentialsPage.maxFormWidth),
      child: Text.rich(
        TextSpan(
          style: styles.footerMuted,
          children: [
            const TextSpan(text: 'Keine E-Mail gefunden? '),
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: resendBusy
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: styles.accentColor,
                      ),
                    )
                  : GestureDetector(
                      onTap: onResend,
                      child: Text('Erneut senden', style: styles.footerLink),
                    ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
