import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/calendar/presentation/providers/calendar_providers.dart';
import '../../features/calendar/presentation/widgets/calendar_week_layout_tokens.dart';
import 'app_modal_sheet.dart';
import 'main_navigation_bar.dart';

/// Persistentes Gerüst für die Hauptbereiche (Kalender, Hausaufgaben, Einstellungen).
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
        const _ModalAwareNavBar(),
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

/// Blendet die Main-Navigation bei offenen App-Modals auf iOS Glass aus
/// ([IndexedStack], UiKitView bleibt gemountet). Auf Android/Material bleibt
/// die Bar sichtbar — Modals liegen per Root-Navigator darüber.
class _ModalAwareNavBar extends StatefulWidget {
  const _ModalAwareNavBar();

  @override
  State<_ModalAwareNavBar> createState() => _ModalAwareNavBarState();
}

class _ModalAwareNavBarState extends State<_ModalAwareNavBar> {
  bool _modalOpen = false;

  bool get _useNativeIosTabBar =>
      defaultTargetPlatform == TargetPlatform.iOS &&
      PlatformVersion.shouldUseNativeGlass;

  @override
  void initState() {
    super.initState();
    AppModalSheetTracker.depth.addListener(_onModalDepthChanged);
    _modalOpen = AppModalSheetTracker.depth.value > 0;
  }

  @override
  void dispose() {
    AppModalSheetTracker.depth.removeListener(_onModalDepthChanged);
    super.dispose();
  }

  void _onModalDepthChanged() {
    final open = AppModalSheetTracker.depth.value > 0;
    if (open != _modalOpen && mounted) {
      setState(() => _modalOpen = open);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bar = MainNavigationBar(key: ValueKey('main-navigation-bar'));

    // Nur iOS Glass: native UiKitView kann Flutter-Modals überdecken (Issue #31).
    if (!_modalOpen || !_useNativeIosTabBar) {
      return bar;
    }

    return IndexedStack(
      index: 0,
      sizing: StackFit.passthrough,
      children: const [
        SizedBox.shrink(),
        bar,
      ],
    );
  }
}
