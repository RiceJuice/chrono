import 'package:chronoapp/core/widgets/app_modal_sheet.dart';
import 'package:chronoapp/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/calendar_week_layout_tokens.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/search/calendar_search_entrance_transition.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/search/calendar_search_layer.dart';
import 'package:chronoapp/features/settings/presentation/widgets/guardian_calendar_filter_sync.dart';
import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'calendar_search_bottom_bar.dart';
import 'ios_calendar_tab_icons_provider.dart';
import 'main_navigation_bar.dart';

/// Höhe der Tab-Leiste in [MainNavigationBar] (ohne System-Safe-Area).
const double kMainShellNavigationBarHeight = 56;

/// Unterer Inhaltsabstand in Shell-Branches — [extendBody] überlappt die Bar.
double mainShellBottomContentInset(BuildContext context) {
  return MediaQuery.paddingOf(context).bottom + kMainShellNavigationBarHeight;
}

/// Persistentes Gerüst für die Hauptbereiche (Kalender, Hausaufgaben, Einstellungen).
class MainShellScaffold extends ConsumerStatefulWidget {
  const MainShellScaffold({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<MainShellScaffold> createState() => _MainShellScaffoldState();
}

class _MainShellScaffoldState extends ConsumerState<MainShellScaffold>
    with SingleTickerProviderStateMixin {
  static const int _calendarBranchIndex = 0;

  final CNTabBarSearchController _searchController = CNTabBarSearchController();
  bool _modalOpen = false;
  bool _searchOverlayMounted = false;
  late final AnimationController _searchEntranceController;
  late final Animation<double> _searchEntranceAnimation;

  bool get _useNativeIosTabBar =>
      defaultTargetPlatform == TargetPlatform.iOS &&
      PlatformVersion.shouldUseNativeGlass;

  @override
  void initState() {
    super.initState();
    _searchEntranceController = AnimationController(
      vsync: this,
      duration: CalendarSearchEntranceTransition.duration,
      reverseDuration: CalendarSearchEntranceTransition.reverseDuration,
    );
    _searchEntranceAnimation = CurvedAnimation(
      parent: _searchEntranceController,
      curve: CalendarSearchEntranceTransition.curve,
      reverseCurve: CalendarSearchEntranceTransition.reverseCurve,
    );
    AppModalSheetTracker.depth.addListener(_onModalDepthChanged);
    _modalOpen = AppModalSheetTracker.depth.value > 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_useNativeIosTabBar) return;
      ref.read(iosCalendarTabIconsProvider.notifier).ensureLoaded(context);
    });
  }

  @override
  void dispose() {
    AppModalSheetTracker.depth.removeListener(_onModalDepthChanged);
    _searchEntranceController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchOpenChanged(bool? previous, bool next) {
    if (next) {
      if (!_searchOverlayMounted) {
        setState(() => _searchOverlayMounted = true);
      }
      _searchEntranceController.forward(from: 0);
      return;
    }

    if (previous != true) return;

    _searchEntranceController.reverse().whenComplete(() {
      if (!mounted) return;
      if (!ref.read(calendarSearchOpenProvider)) {
        setState(() => _searchOverlayMounted = false);
      }
    });
  }

  void _onModalDepthChanged() {
    final open = AppModalSheetTracker.depth.value > 0;
    if (open != _modalOpen && mounted) {
      setState(() => _modalOpen = open);
    }
  }

  void _closeSearch() {
    closeCalendarSearchMode(ref, searchController: _searchController);
  }

  @override
  Widget build(BuildContext context) {
    final isCalendarBranch =
        widget.navigationShell.currentIndex == _calendarBranchIndex;
    ref.listen(calendarSearchOpenProvider, _onSearchOpenChanged);
    final hideNavBar = isCalendarBranch &&
        calendarUsePhoneLandscapeChrome(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return GuardianCalendarFilterSync(
      child: Scaffold(
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CalendarSearchEntranceTransition.backdrop(
            animation: _searchEntranceAnimation,
            reduceMotion: reduceMotion,
            child: widget.navigationShell,
          ),
          if (_searchOverlayMounted)
            CalendarSearchEntranceTransition.layer(
              animation: _searchEntranceAnimation,
              reduceMotion: reduceMotion,
              child: CalendarSearchLayer(
                onClose: _closeSearch,
                entranceAnimation: _searchEntranceAnimation,
              ),
            ),
          if (_searchOverlayMounted && hideNavBar)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: CalendarSearchBottomBar(onClose: _closeSearch),
            ),
        ],
      ),
      bottomNavigationBar: hideNavBar
          ? null
          : _NavBarWithOverlay(
              isCalendarBranch: isCalendarBranch,
              searchBarVisible: _searchOverlayMounted,
              searchController: _searchController,
              modalOpen: _modalOpen,
              useNativeIosTabBar: _useNativeIosTabBar,
              onSearchClose: _closeSearch,
            ),
    ),
    );
  }
}

class _NavBarWithOverlay extends ConsumerWidget {
  const _NavBarWithOverlay({
    required this.isCalendarBranch,
    required this.searchBarVisible,
    required this.searchController,
    required this.modalOpen,
    required this.useNativeIosTabBar,
    required this.onSearchClose,
  });

  final bool isCalendarBranch;
  final bool searchBarVisible;
  final CNTabBarSearchController searchController;
  final bool modalOpen;
  final bool useNativeIosTabBar;
  final VoidCallback onSearchClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overlayOpen =
        isCalendarBranch && ref.watch(calendarViewModeOverlayOpenProvider);
    final scrimAlpha =
        defaultTargetPlatform == TargetPlatform.iOS ? 0.12 : 0.18;

    final Widget bar;
    if (searchBarVisible) {
      // Native CNTabBar feuert nur searchActiveChanged — keine sichtbare
      // Suchleiste. CalendarSearchBottomBar nutzt LiquidGlassContainer.
      bar = CalendarSearchBottomBar(
        onClose: onSearchClose,
      );
    } else {
      bar = MainNavigationBar(
        searchController: searchController,
      );
    }

    final navBar = (!modalOpen || !useNativeIosTabBar)
        ? bar
        : IndexedStack(
            index: 0,
            sizing: StackFit.passthrough,
            children: [
              const SizedBox.shrink(),
              bar,
            ],
          );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        navBar,
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
