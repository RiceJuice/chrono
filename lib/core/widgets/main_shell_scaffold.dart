import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/calendar/presentation/providers/calendar_providers.dart';
import '../../features/calendar/presentation/widgets/calendar_week_layout_tokens.dart';
import 'main_navigation_bar.dart';

/// Persistentes Gerüst für die Hauptbereiche (Kalender, Einstellungen).
///
/// Die [MainNavigationBar] lebt hier im Shell und überlebt damit den
/// Tab-Wechsel (kein Neuaufbau der nativen Glass-TabBar mehr). Der Body wird
/// von der [StatefulNavigationShell] als `IndexedStack` gehalten, sodass der
/// jeweilige Branch-State (Scrollposition etc.) erhalten bleibt.
class MainShellScaffold extends ConsumerWidget {
  const MainShellScaffold({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const int _calendarBranchIndex = 0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCalendarBranch =
        navigationShell.currentIndex == _calendarBranchIndex;
    // Handy im Querformat zeigt den Kalender im Vollbild ohne untere Leiste.
    final hideNavBar = isCalendarBranch &&
        calendarUsePhoneLandscapeChrome(context);

    return Scaffold(
      // Inhalt scrollt hinter der (Glass-)Navbar durch; die Navbar-Höhe wird
      // über MediaQuery.padding.bottom an die Branches weitergereicht.
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: hideNavBar
          ? null
          : _NavBarWithOverlay(isCalendarBranch: isCalendarBranch),
    );
  }
}

/// Navbar plus optionaler Abdunkelungs-Scrim, der beim offenen
/// View-Mode-Overlay des Kalenders über die Navigationsleiste gelegt wird.
class _NavBarWithOverlay extends ConsumerWidget {
  const _NavBarWithOverlay({required this.isCalendarBranch});

  final bool isCalendarBranch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overlayOpen =
        isCalendarBranch && ref.watch(calendarViewModeOverlayOpenProvider);
    final scrimAlpha =
        defaultTargetPlatform == TargetPlatform.iOS ? 0.12 : 0.18;

    return Stack(
      children: [
        const MainNavigationBar(),
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !overlayOpen,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              opacity: overlayOpen ? 1 : 0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => ref
                    .read(calendarViewModeOverlayOpenProvider.notifier)
                    .set(isOpen: false),
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: scrimAlpha),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
