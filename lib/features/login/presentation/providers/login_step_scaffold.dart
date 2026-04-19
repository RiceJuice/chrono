import 'package:chronoapp/core/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/auth_repository.dart';
import '../../domain/models/login_flow_step.dart';
import '../routes/login_routes.dart';
import '../widgets/buttons.dart';
import '../widgets/login_scroll_surface.dart';

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
    /// Wenn false: [footer] wird NICHT im Scrollbereich platziert, sondern
    /// als festes Element im äußeren Layout direkt über dem Primärbutton.
    /// Dadurch scrollt der Footer nicht mit dem Seiteninhalt mit; nur der
    /// Primärbutton (+ Footer als fixer Block) wandert mit der Tastatur.
    this.footerInScrollArea = true,
    /// Titel in der Theme-Standard-Schrift (ohne Libre Baskerville).
    this.plainTitleFont = false,
    /// Zusätzliches Padding um Titel/Untertitel (z. B. wenn der Seiten-Body ohne
    /// horizontales Inset volle Breite nutzt, der Header aber wie andere Steps
    /// eingerückt sein soll).
    this.headerPadding,
  });

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

  /// Wenn true: Seitentitel nutzt [ThemeData.textTheme] (Sans), nicht Libre Baskerville.
  final bool plainTitleFont;

  /// Optional: horizontales/vertikales Padding nur für den Kopfbereich (Titel).
  final EdgeInsetsGeometry? headerPadding;

  List<Widget> _wrappedHeader(BuildContext context) {
    final List<Widget> items = _header(context);
    final EdgeInsetsGeometry? p = headerPadding;
    if (p == null) return items;
    return [
      Padding(
        padding: p,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items,
        ),
      ),
    ];
  }

  Widget _wrapContentWidth(Widget child) {
    final double? w = contentMaxWidth;
    if (w == null) return child;
    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: w),
        child: child,
      ),
    );
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
      Text(
        titleOverride ?? step.title,
        style: titleStyle,
      ),
      if (subtitleOverride != null)
        Text(
          subtitleOverride!,
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: 16,
            fontWeight: FontWeight.w400,
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

  Widget _buildPrimaryButton(BuildContext context, {required double horizontalPadding}) {
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
                  showAppToast(
                    context,
                    message,
                    kind: AppToastKind.error,
                  );
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
    final double buttonHorizontalPadding = location == LoginPaths.choir ? 20 : 0;

    // Footer-Block nur dann im Scrollbereich rendern, wenn gewünscht.
    final List<Widget> scrollFooterBlock =
        footerInScrollArea ? _footerBlock() : const [];

    Widget scrollArea = centerChildInScrollViewport
        ? LayoutBuilder(
            builder: (BuildContext context, BoxConstraints viewport) {
              return _LoginCenteredViewportBody(
                viewportHeight: viewport.maxHeight,
                header: _wrappedHeader(context),
                form: _wrapContentWidth(child),
                footer: scrollFooterBlock,
              );
            },
          )
        : LoginScrollSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._wrappedHeader(context),
                _wrapContentWidth(child),
                ...scrollFooterBlock,
              ],
            ),
          );

    // Fixer Footer außerhalb des Scrollbereichs + Button, der mit der Tastatur
    // nach oben wandert (Footer bleibt an seiner Bildschirmposition und wird
    // ggf. von der Tastatur überdeckt). Voraussetzung: Scaffold mit
    // resizeToAvoidBottomInset: false (siehe LoginOnboardingShell).
    if (!footerInScrollArea && footer != null && showPrimaryButton) {
      final double tail = footerTailHeight ?? 32;
      // Reservierter Platz am Ende des Columns, damit Formular/Footer den
      // absolut positionierten Button nicht überlappen.
      final double buttonReserve = _primaryButtonHeight + tail;
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
            child: _buildPrimaryButton(
              context,
              horizontalPadding: buttonHorizontalPadding,
            ),
          ),
        ],
      );
    }

    // Standardlayout: Scroll + Button in einer Column (Button folgt der
    // Tastatur automatisch, weil der Scaffold den Body verkleinert).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: scrollArea),
        if (!footerInScrollArea && footer != null) ...[
          Align(alignment: Alignment.center, child: footer!),
          SizedBox(height: footerTailHeight ?? 32),
        ],
        if (showPrimaryButton)
          _buildPrimaryButton(
            context,
            horizontalPadding: buttonHorizontalPadding,
          ),
      ],
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

class _LoginCenteredViewportBodyState extends State<_LoginCenteredViewportBody> {
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
    return LoginScrollSurface(
      child: SizedBox(
        height: widget.viewportHeight,
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              key: _headerKey,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.header,
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double hExp = constraints.maxHeight;
                  double yAlign = 0;
                  if (_headerHeight > 0 && hExp > 0) {
                    // Mitte im Expanded um headerHeight nach oben: y = -2 * header / hExp;
                    // leichtes + nach unten (Alignment näher an 0).
                    yAlign =
                        (-2 * _headerHeight / hExp + 0.1).clamp(-1.0, 0.0);
                  }
                  return Align(
                    alignment: Alignment(0, yAlign),
                    child: widget.form,
                  );
                },
              ),
            ),
            ...widget.footer,
          ],
        ),
      ),
    );
  }
}