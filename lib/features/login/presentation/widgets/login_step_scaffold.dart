import 'package:chronoapp/core/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/auth_repository.dart';
import '../../domain/models/login_flow_step.dart';
import '../routes/login_paths.dart';
import 'buttons.dart';
import 'login_flow_body.dart';
import 'login_flow_spacing.dart';
import 'login_split_screen.dart';
import 'login_step_layout.dart';

/// [LoginStepScaffold.validateBeforeProceed] hat `false` geliefert; kein Toast.
final class LoginStepProceedBlocked implements Exception {
  const LoginStepProceedBlocked();
}

/// Fehler wurde bereits auf der Seite angezeigt; kein zweiter Toast.
final class LoginStepErrorAlreadyShown implements Exception {
  const LoginStepErrorAlreadyShown();
}

class LoginStepScaffold extends StatelessWidget {
  const LoginStepScaffold({
    super.key,
    required this.step,
    required this.child,
    this.nextPath,
    this.validateBeforeProceed,
    this.onAsyncProceed,
    this.submitBusy = false,
    this.showPrimaryButton = true,
    this.titleOverride,
    this.subtitleOverride,
    this.submitLabel,
    this.footer,
    this.contentMaxWidth,
    this.primaryButtonMaxWidth,
    this.footerLeadHeight,
    this.footerTailHeight,
    this.bottomBehavior,
    this.footerSpacing = const LoginFooterSpacing(),
    this.plainTitleFont = false,
    this.headerPadding,
  });

  static const double defaultContentMaxWidth = 400;
  static const double desktopBreakpoint = LoginSplitScreen.defaultBreakpoint;
  static const double _primaryButtonHeight = 60;
  static const double _stepPageHorizontalInset = 20;
  static const double _stepPageBottomInset = 18;

  final LoginFlowStep step;
  final Widget child;
  final String? nextPath;
  final bool Function()? validateBeforeProceed;
  final Future<void> Function(void Function() goNext)? onAsyncProceed;
  final bool submitBusy;
  final bool showPrimaryButton;
  final String? titleOverride;
  final String? subtitleOverride;
  final String? submitLabel;
  final Widget? footer;
  final double? contentMaxWidth;
  final double? primaryButtonMaxWidth;
  final double? footerLeadHeight;
  final double? footerTailHeight;
  final LoginBottomBehavior? bottomBehavior;
  final LoginFooterSpacing footerSpacing;
  final bool plainTitleFont;
  final EdgeInsetsGeometry? headerPadding;

  Widget _wrapContentWidth(Widget content) {
    final Widget fullWidthContent = SizedBox(
      width: double.infinity,
      child: content,
    );
    final double? w = contentMaxWidth;
    if (w == null) return fullWidthContent;
    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: w),
        child: fullWidthContent,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final double titleSize = LoginFlowSpacing.headerTitleSize(
      context,
      desktop: plainTitleFont ? 32 : 44,
    );
    final double subtitleSize = LoginFlowSpacing.headerSubtitleSize(context);

    final TextStyle titleStyle = plainTitleFont
        ? (theme.textTheme.headlineMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: titleSize,
                height: 1.2,
              ) ??
              TextStyle(
                color: scheme.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: titleSize,
                height: 1.2,
              ))
        : GoogleFonts.libreBaskerville(
            color: scheme.onSurface,
            fontSize: titleSize,
            fontWeight: FontWeight.w700,
          );

    Widget header = SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titleOverride ?? step.title,
            style: titleStyle,
          ),
          if (subtitleOverride != null) ...[
            SizedBox(height: LoginFlowSpacing.gapAfterFieldLabel(context)),
            Text(
              subtitleOverride!,
              style: theme.textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.78),
                    fontSize: subtitleSize,
                    fontWeight: FontWeight.w400,
                    height: 1.35,
                  ) ??
                  TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.78),
                    fontSize: subtitleSize,
                    fontWeight: FontWeight.w400,
                    height: 1.35,
                  ),
            ),
          ],
        ],
      ),
    );

    final EdgeInsetsGeometry? p = headerPadding;
    if (p != null) {
      header = Padding(padding: p, child: header);
    }
    return header;
  }

  List<Widget> _footerInScrollBlock(LoginFooterSpacing spacing) {
    if (footer == null) return const [];
    return [
      SizedBox(height: footerLeadHeight ?? spacing.lead),
      Align(alignment: Alignment.center, child: footer!),
      SizedBox(height: footerTailHeight ?? spacing.tail),
    ];
  }

  EdgeInsets _scrollPadding(
    BuildContext context,
    LoginBottomBehavior behavior,
    LoginFooterSpacing spacing,
  ) {
    if (behavior != LoginBottomBehavior.footerFixed) {
      return EdgeInsets.zero;
    }

    final double tail = footerTailHeight ?? spacing.tail;
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final double bottomGap =
        keyboardInset > 0 ? keyboardInset + 16 : _stepPageBottomInset;
    final double reserved = _primaryButtonHeight + tail + bottomGap;
    return EdgeInsets.only(bottom: reserved);
  }

  double _pageHorizontalInset(String location) =>
      location == LoginPaths.login ? 0 : _stepPageHorizontalInset;

  Widget _wrapBottomArea(String location, Widget content) {
    final double inset = _pageHorizontalInset(location);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: inset),
      child: _wrapContentWidth(content),
    );
  }

  Widget _buildPrimaryButton(
    BuildContext context, {
    required String location,
  }) {
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final double horizontalInset = _pageHorizontalInset(location);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalInset,
        0,
        horizontalInset,
        keyboardInset > 0 ? 0 : _stepPageBottomInset,
      ),
      child: Align(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: primaryButtonMaxWidth ?? double.infinity,
          ),
          child: LoginPrimaryButton(
            label: submitLabel ?? 'Speichern',
            color: step.accentColor,
            isLoading: submitBusy,
            onPressed: () async {
              final shouldProceed = validateBeforeProceed?.call() ?? true;
              if (!shouldProceed) {
                throw const LoginStepProceedBlocked();
              }

              void goNext() {
                final path = nextPath;
                if (path == null) {
                  context.go(LoginPaths.success);
                  return;
                }
                context.go(path);
              }

              final asyncProceed = onAsyncProceed;
              if (asyncProceed != null) {
                try {
                  await asyncProceed(goNext);
                } catch (e) {
                  if (e is LoginStepErrorAlreadyShown) {
                    rethrow;
                  }
                  if (!context.mounted) return;
                  final message = e is AuthRepositoryException
                      ? e.message
                      : 'Der Schritt konnte nicht abgeschlossen werden. Bitte erneut versuchen.';
                  showAppToast(context, message, kind: AppToastKind.error);
                  rethrow;
                }
              } else {
                goNext();
              }
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    final LoginBottomBehavior resolvedBottomBehavior =
        bottomBehavior ?? LoginBottomBehavior.footerInScroll;
    final LoginFooterSpacing spacing = LoginFooterSpacing(
      lead: footerLeadHeight ?? footerSpacing.lead,
      tail: footerTailHeight ?? footerSpacing.tail,
    );

    final List<Widget> scrollFooterBlock =
        resolvedBottomBehavior == LoginBottomBehavior.footerInScroll
            ? _footerInScrollBlock(spacing)
            : const [];

    final Widget scrollArea = LoginFlowBody(
      location: location,
      scrollPadding: _scrollPadding(context, resolvedBottomBehavior, spacing),
      includeChrome: true,
      fillViewport: false,
      child: _wrapContentWidth(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            SizedBox(height: LoginFlowSpacing.gapAfterHeader(context)),
            child,
            ...scrollFooterBlock,
          ],
        ),
      ),
    );

    return LoginStepLayout(
      scrollArea: scrollArea,
      bottomBehavior: resolvedBottomBehavior,
      footer: resolvedBottomBehavior == LoginBottomBehavior.footerFixed &&
              footer != null
          ? _wrapBottomArea(location, footer!)
          : null,
      footerSpacing: spacing,
      primaryButtonHeight: _primaryButtonHeight,
      showPrimaryButton: showPrimaryButton,
      primaryButton: _buildPrimaryButton(context, location: location),
    );
  }
}
