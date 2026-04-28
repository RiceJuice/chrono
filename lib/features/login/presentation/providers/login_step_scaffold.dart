import 'package:chronoapp/core/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/auth_repository.dart';
import '../../domain/models/login_flow_step.dart';
import '../routes/login_routes.dart';
import '../widgets/buttons.dart';
import '../widgets/login_scroll_surface.dart';
import '../widgets/login_step_layout.dart';

/// [LoginStepScaffold.canProceed] hat `false` geliefert; kein zusätzlicher Toast.
final class LoginStepProceedBlocked implements Exception {
  const LoginStepProceedBlocked();
}

/// Fehler wurde bereits auf der Seite angezeigt (z. B. Toast); kein zweiter Toast.
final class LoginStepErrorAlreadyShown implements Exception {
  const LoginStepErrorAlreadyShown();
}

class LoginStepScaffold extends StatelessWidget {
  const LoginStepScaffold({
    super.key,
    required this.step,
    required this.child,
    this.nextPath,
    this.canProceed,
    this.onAsyncProceed,
    this.submitBusy = false,
    this.showPrimaryButton = true,
    this.titleOverride,
    this.subtitleOverride,
    this.submitLabel,
    this.footer,

    /// Wenn true: [child] wird im Scroll-Viewport zentriert, aber um die gemessene
    /// Header-Höhe nach oben versetzt (optisch näher an der Bildschirmmitte).
    /// [SingleChildScrollView] bleibt unverändert.
    this.centerChildInScrollViewport = false,
    this.contentMaxWidth,
    this.primaryButtonMaxWidth,
    this.footerLeadHeight,
    this.footerTailHeight,

    /// Legacy-Schalter, falls [bottomBehavior] nicht gesetzt ist.
    this.footerInScrollArea = true,

    /// Explizites Bottom-Verhalten für Footer/Button.
    this.bottomBehavior,

    /// Titel in der Theme-Standard-Schrift (ohne Libre Baskerville).
    this.plainTitleFont = false,

    /// Zusätzliches Padding um Titel/Untertitel (z. B. wenn der Seiten-Body ohne
    /// horizontales Inset volle Breite nutzt, der Header aber wie andere Steps
    /// eingerückt sein soll).
    this.headerPadding,
  });

  static const double defaultContentMaxWidth = 400;
  static const double desktopBreakpoint = 800;

  final LoginFlowStep step;
  final Widget child;
  final String? nextPath;
  final bool Function()? canProceed;
  final Future<void> Function(void Function() goNext)? onAsyncProceed;
  final bool submitBusy;
  final bool showPrimaryButton;
  final String? titleOverride;
  final String? subtitleOverride;
  final String? submitLabel;
  final Widget? footer;
  final bool centerChildInScrollViewport;

  /// Begrenzt die Breite von [child] (zentriert). `null` = volle Breite.
  final double? contentMaxWidth;

  /// Begrenzt die Breite des Primärbuttons. `null` = volle Breite wie bisher.
  final double? primaryButtonMaxWidth;

  /// Abstand zwischen Hauptinhalt und [footer] im Scrollbereich (Standard: 160).
  final double? footerLeadHeight;

  /// Abstand unterhalb von [footer] im Scrollbereich (Standard: 32).
  final double? footerTailHeight;

  /// Steuert, ob [footer] im Scrollbereich (true, Standard) oder als festes
  /// Element zwischen Scrollbereich und Primärbutton (false) platziert wird.
  final bool footerInScrollArea;
  final LoginBottomBehavior? bottomBehavior;

  /// Wenn true: Seitentitel nutzt [ThemeData.textTheme] (Sans), nicht Libre Baskerville.
  final bool plainTitleFont;

  /// Optional: horizontales/vertikales Padding nur für den Kopfbereich (Titel).
  final EdgeInsetsGeometry? headerPadding;

  Widget _buildHeader(BuildContext context) {
    final EdgeInsetsGeometry? p = headerPadding;
    Widget header = SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _header(context),
      ),
    );
    if (p != null) {
      header = Padding(padding: p, child: header);
    }
    return header;
  }

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

  Widget _buildContentBlock(BuildContext context) {
    return _wrapContentWidth(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          SizedBox(width: double.infinity, child: child),
        ],
      ),
    );
  }

  List<Widget> _wrappedHeader(
    BuildContext context, {
    required bool alignWithContent,
  }) {
    Widget header = _buildHeader(context);
    if (alignWithContent) {
      final double headerMaxWidth =
          contentMaxWidth ?? primaryButtonMaxWidth ?? defaultContentMaxWidth;
      header = Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: headerMaxWidth),
          child: header,
        ),
      );
    }
    return [header];
  }

  List<Widget> _header(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextStyle titleStyle = plainTitleFont
        ? (theme.textTheme.headlineMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 32,
                height: 1.2,
              ) ??
              TextStyle(
                color: scheme.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 32,
                height: 1.2,
              ))
        : GoogleFonts.libreBaskerville(
            color: scheme.onSurface,
            fontSize: 44,
            fontWeight: FontWeight.w700,
          );
    return [
      Align(
        alignment: Alignment.centerLeft,
        child: Text(
          titleOverride ?? step.title,
          textAlign: TextAlign.left,
          style: titleStyle,
        ),
      ),
      if (subtitleOverride != null)
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            subtitleOverride!,
            textAlign: TextAlign.left,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
    ];
  }

  List<Widget> _footerBlock() {
    if (footer == null) return const [];
    return [
      SizedBox(height: footerLeadHeight ?? 160),
      Align(alignment: Alignment.center, child: footer!),
      SizedBox(height: footerTailHeight ?? 32),
    ];
  }

  /// Höhe des Primärbuttons (siehe [LoginPrimaryButton.height] = 60).
  static const double _primaryButtonHeight = 60;

  EdgeInsets _scrollPaddingForBottomBehavior(BuildContext context) {
    final LoginBottomBehavior resolvedBottomBehavior =
        bottomBehavior ??
        (footerInScrollArea
            ? LoginBottomBehavior.footerInScroll
            : LoginBottomBehavior.footerFixed);
    if (resolvedBottomBehavior != LoginBottomBehavior.footerFixed) {
      return EdgeInsets.zero;
    }

    // Bei fixem Footer liegt der Button als Overlay im unteren Bereich.
    // Extra Bottom-Padding hält den letzten Formbereich trotz Tastatur erreichbar.
    final double tail = footerTailHeight ?? 32;
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final double reserved = _primaryButtonHeight + tail + keyboardInset + 16;
    return EdgeInsets.only(bottom: reserved);
  }

  Widget _buildPrimaryButton(
    BuildContext context, {
    required double horizontalPadding,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
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
              final shouldProceed = canProceed?.call() ?? true;
              if (!shouldProceed) {
                throw const LoginStepProceedBlocked();
              }

              void goNext() {
                final path = nextPath;
                if (path == null) {
                  context.go('/calendar');
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
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isDesktop = constraints.maxWidth > desktopBreakpoint;
        final String location = GoRouterState.of(context).matchedLocation;
        final double buttonHorizontalPadding = location == LoginPaths.choir
            ? 20
            : 0;
        final LoginBottomBehavior resolvedBottomBehavior =
            bottomBehavior ??
            (footerInScrollArea
                ? LoginBottomBehavior.footerInScroll
                : LoginBottomBehavior.footerFixed);

        // Footer-Block nur dann im Scrollbereich rendern, wenn gewünscht.
        final List<Widget> scrollFooterBlock =
            resolvedBottomBehavior == LoginBottomBehavior.footerInScroll
            ? _footerBlock()
            : const [];

        Widget scrollArea = centerChildInScrollViewport
            ? LayoutBuilder(
                builder: (BuildContext context, BoxConstraints viewport) {
                  return _LoginCenteredViewportBody(
                    viewportHeight: viewport.maxHeight,
                    header: _wrappedHeader(
                      context,
                      alignWithContent: isDesktop,
                    ),
                    form: _wrapContentWidth(child),
                    footer: scrollFooterBlock,
                  );
                },
              )
            : LoginScrollSurface(
                scrollPadding: _scrollPaddingForBottomBehavior(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [_buildContentBlock(context), ...scrollFooterBlock],
                ),
              );

        final Widget layout = LoginStepLayout(
          scrollArea: scrollArea,
          bottomBehavior: resolvedBottomBehavior,
          footer: footer,
          footerSpacing: LoginFooterSpacing(
            lead: footerLeadHeight ?? 160,
            tail: footerTailHeight ?? 32,
          ),
          primaryButtonHeight: _primaryButtonHeight,
          showPrimaryButton: showPrimaryButton,
          primaryButton: _buildPrimaryButton(
            context,
            horizontalPadding: buttonHorizontalPadding,
          ),
        );

        return layout;
      },
    );
  }
}

/// Zentriert [form] im [Expanded]-Bereich, verschiebt die optische Mitte um die
/// gemessene [header]-Höhe nach oben (ohne Stack/Overlay).
class _LoginCenteredViewportBody extends StatefulWidget {
  const _LoginCenteredViewportBody({
    required this.viewportHeight,
    required this.header,
    required this.form,
    required this.footer,
  });

  final double viewportHeight;
  final List<Widget> header;
  final Widget form;
  final List<Widget> footer;

  @override
  State<_LoginCenteredViewportBody> createState() =>
      _LoginCenteredViewportBodyState();
}

class _LoginCenteredViewportBodyState
    extends State<_LoginCenteredViewportBody> {
  final GlobalKey _headerKey = GlobalKey();
  double _headerHeight = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(_measureHeader);
  }

  @override
  void didUpdateWidget(covariant _LoginCenteredViewportBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback(_measureHeader);
  }

  void _measureHeader(_) {
    final BuildContext? ctx = _headerKey.currentContext;
    if (ctx == null) return;
    final RenderBox? box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final double h = box.size.height;
    if ((h - _headerHeight).abs() > 0.5) {
      setState(() => _headerHeight = h);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double topSpacer = _headerHeight <= 0
        ? 0
        : ((widget.viewportHeight - _headerHeight) * 0.12).clamp(0.0, 72.0);

    return LoginScrollSurface(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: widget.viewportHeight),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                key: _headerKey,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.header,
              ),
              SizedBox(height: topSpacer),
              Align(alignment: Alignment.topCenter, child: widget.form),
              ...widget.footer,
            ],
          ),
        ),
      ),
    );
  }
}
