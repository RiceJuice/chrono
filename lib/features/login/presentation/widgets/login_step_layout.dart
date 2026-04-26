import 'package:flutter/material.dart';

/// Definiert, wie Footer und Primärbutton im unteren Bereich angeordnet werden.
enum LoginBottomBehavior {
  /// Footer liegt im Scrollinhalt.
  footerInScroll,

  /// Footer bleibt fix über dem keyboard-aware Primärbutton.
  footerFixed,

  /// Kein besonderer Footer-Bereich.
  none,
}

/// Vertikale Abstände rund um den Footer-Block.
class LoginFooterSpacing {
  const LoginFooterSpacing({this.lead = 160, this.tail = 32});

  final double lead;
  final double tail;
}

/// Gemeinsame Layout-Hülle für Scrollfläche, Footer und Primärbutton.
class LoginStepLayout extends StatelessWidget {
  const LoginStepLayout({
    super.key,
    required this.scrollArea,
    required this.bottomBehavior,
    required this.showPrimaryButton,
    required this.primaryButton,
    this.footer,
    this.primaryButtonHeight = 60,
    this.footerSpacing = const LoginFooterSpacing(),
  });

  final Widget scrollArea;
  final LoginBottomBehavior bottomBehavior;
  final bool showPrimaryButton;
  final Widget primaryButton;
  final Widget? footer;
  final double primaryButtonHeight;
  final LoginFooterSpacing footerSpacing;

  @override
  Widget build(BuildContext context) {
    final bool hasFooter = footer != null;

    if (bottomBehavior == LoginBottomBehavior.footerFixed &&
        hasFooter &&
        showPrimaryButton) {
      final double buttonReserve = primaryButtonHeight + footerSpacing.tail;
      final double bottomInset = MediaQuery.viewInsetsOf(context).bottom;

      return Stack(
        fit: StackFit.expand,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: scrollArea),
              Align(alignment: Alignment.center, child: footer!),
              SizedBox(height: buttonReserve),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset,
            child: primaryButton,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: scrollArea),
        if (bottomBehavior == LoginBottomBehavior.footerFixed && hasFooter) ...[
          Align(alignment: Alignment.center, child: footer!),
          SizedBox(height: footerSpacing.tail),
        ],
        if (showPrimaryButton) primaryButton,
      ],
    );
  }
}
