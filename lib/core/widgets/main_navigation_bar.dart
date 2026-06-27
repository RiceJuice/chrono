import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

import '../../features/calendar/presentation/providers/calendar_providers.dart';
import '../../features/calendar/presentation/widgets/search/calendar_search_layer.dart';
import '../../features/settings/presentation/helpers/guardian_child_permissions.dart';
import '../haptics/app_haptics.dart';
import 'app_hairline_divider.dart';
import 'domspatzen_icon_metrics.dart';
import 'ios_calendar_tab_icons_provider.dart';

class MainNavigationBar extends ConsumerStatefulWidget {
  const MainNavigationBar({super.key});

  @override
  ConsumerState<MainNavigationBar> createState() => _MainNavigationBarState();
}

class _MainNavigationBarState extends ConsumerState<MainNavigationBar> {
  bool _iosCalendarIconLoadScheduled = false;

  static const _calendarPath = '/calendar';
  static const _homeworkPath = '/homework';
  static const _settingsPath = '/settings';

  static const _iconLabelSpacingOffset = 5.0;
  static const _materialTabIconSlotSize = 28.0;
  static const _materialTabGlyphSize = 22.0;
  static const _iosTabGlyphSize = 17.0;

  int _tabIndexFromLocation(String location, {required bool showHomework}) {
    if (location.startsWith(_settingsPath)) {
      return showHomework ? 2 : 1;
    }
    if (showHomework && location.startsWith(_homeworkPath)) return 1;
    return 0;
  }

  String _routeTargetFromIndex(int index, {required bool showHomework}) {
    if (!showHomework) {
      return index == 1 ? _settingsPath : _calendarPath;
    }
    return switch (index) {
      0 => _calendarPath,
      1 => _homeworkPath,
      _ => _settingsPath,
    };
  }

  void _scheduleIosCalendarIconLoad() {
    if (!_useNativeIosTabBar() || _iosCalendarIconLoadScheduled) {
      return;
    }
    _iosCalendarIconLoadScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _iosCalendarIconLoadScheduled = false;
      if (!mounted || !_useNativeIosTabBar()) return;
      ref.read(iosCalendarTabIconsProvider.notifier).ensureLoaded(context);
    });
  }

  void _onDestinationSelected({
    required BuildContext context,
    required String location,
    required int index,
    required bool showHomework,
  }) {
    final target = _routeTargetFromIndex(index, showHomework: showHomework);
    final searchOpen = ref.read(calendarSearchOpenProvider);

    if (target == _calendarPath && searchOpen) {
      AppHaptics.light();
      exitCalendarSearchToCalendarTab(
        ref,
        context,
      );
      return;
    }

    if (target == _calendarPath && location == _calendarPath) {
      final now = DateTime.now().toLocal();
      final today = DateTime(now.year, now.month, now.day);
      ref.read(selectedDayProvider.notifier).update(today);
      ref.read(focusedDayProvider.notifier).update(today);
      return;
    }
    if (target != location) {
      AppHaptics.light();
      context.go(target);
    }
  }

  Widget _tabIconSlot(Widget icon) {
    return Transform.translate(
      offset: const Offset(0, _iconLabelSpacingOffset),
      child: SizedBox(
        width: _materialTabIconSlotSize,
        height: _materialTabIconSlotSize,
        child: Center(child: icon),
      ),
    );
  }

  Color _tabIconColor(BuildContext context, {required bool selected}) {
    final scheme = Theme.of(context).colorScheme;
    return selected ? scheme.primary : scheme.onSurfaceVariant;
  }

  Widget _buildCalendarIcon({
    required BuildContext context,
    required bool selected,
    required double glyphSize,
  }) {
    final assetSize = DomspatzenIconMetrics.assetSizeForGlyph(glyphSize);
    return SvgPicture.asset(
      DomspatzenIconMetrics.assetPath,
      height: assetSize,
      width: assetSize,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(
        _tabIconColor(context, selected: selected),
        BlendMode.srcIn,
      ),
    );
  }

  Widget _buildHomeworkIcon({
    required BuildContext context,
    required bool selected,
    required double glyphSize,
  }) {
    return Icon(
      selected ? Icons.menu_book : Icons.menu_book_outlined,
      size: glyphSize,
      color: _tabIconColor(context, selected: selected),
    );
  }

  Widget _buildSettingsIcon({
    required BuildContext context,
    required bool selected,
    required double glyphSize,
  }) {
    return Icon(
      selected ? Icons.settings : Icons.settings_outlined,
      size: glyphSize,
      color: _tabIconColor(context, selected: selected),
    );
  }

  Widget _buildMaterialNavigationBar({
    required BuildContext context,
    required String location,
    required int currentIndex,
    required bool showHomework,
  }) {
    final destinations = <NavigationDestination>[
      NavigationDestination(
        icon: _tabIconSlot(
          _buildCalendarIcon(
            context: context,
            selected: false,
            glyphSize: _materialTabGlyphSize,
          ),
        ),
        selectedIcon: _tabIconSlot(
          _buildCalendarIcon(
            context: context,
            selected: true,
            glyphSize: _materialTabGlyphSize,
          ),
        ),
        label: 'Kalender',
      ),
      if (showHomework)
        NavigationDestination(
          icon: _tabIconSlot(
            _buildHomeworkIcon(
              context: context,
              selected: false,
              glyphSize: _materialTabGlyphSize,
            ),
          ),
          selectedIcon: _tabIconSlot(
            _buildHomeworkIcon(
              context: context,
              selected: true,
              glyphSize: _materialTabGlyphSize,
            ),
          ),
          label: 'Aufgaben',
        ),
      NavigationDestination(
        icon: _tabIconSlot(
          _buildSettingsIcon(
            context: context,
            selected: false,
            glyphSize: _materialTabGlyphSize,
          ),
        ),
        selectedIcon: _tabIconSlot(
          _buildSettingsIcon(
            context: context,
            selected: true,
            glyphSize: _materialTabGlyphSize,
          ),
        ),
        label: 'Dein Chrono',
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppHairlineDivider.horizontal(),
        NavigationBar(
          height: 56,
          selectedIndex: currentIndex,
          labelPadding: const EdgeInsets.only(top: 2),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            return const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              leadingDistribution: TextLeadingDistribution.even,
              letterSpacing: 0,
            );
          }),
          onDestinationSelected: (index) {
            _onDestinationSelected(
              context: context,
              location: location,
              index: index,
              showHomework: showHomework,
            );
          },
          destinations: destinations,
        ),
      ],
    );
  }

  Widget _buildIosNavigationBar({
    required BuildContext context,
    required String location,
    required int currentIndex,
    required IosCalendarTabIconSet? tabIcons,
    required bool showHomework,
  }) {
    final iosSparrowAssetSize =
        DomspatzenIconMetrics.assetSizeForGlyph(_iosTabGlyphSize);
    final inactiveBytes = tabIcons?.inactive;
    final activeBytes = tabIcons?.active;

    final items = <CNTabBarItem>[
      CNTabBarItem(
        label: 'Kalender',
        icon: inactiveBytes == null
            ? const CNSymbol('calendar', size: _iosTabGlyphSize)
            : null,
        activeIcon: activeBytes == null
            ? const CNSymbol('calendar', size: _iosTabGlyphSize)
            : null,
        imageAsset: inactiveBytes != null
            ? CNImageAsset(
                DomspatzenIconMetrics.assetPath,
                size: iosSparrowAssetSize,
                imageData: inactiveBytes,
                imageFormat: 'png',
              )
            : null,
        activeImageAsset: activeBytes != null
            ? CNImageAsset(
                DomspatzenIconMetrics.assetPath,
                size: iosSparrowAssetSize,
                imageData: activeBytes,
                imageFormat: 'png',
              )
            : null,
      ),
      if (showHomework)
        CNTabBarItem(
          label: 'Aufgaben',
          icon: CNSymbol('text.book.closed', size: _iosTabGlyphSize),
          activeIcon:
              CNSymbol('text.book.closed.fill', size: _iosTabGlyphSize),
        ),
      CNTabBarItem(
        label: 'Dein Chrono',
        icon: CNSymbol('gearshape', size: _iosTabGlyphSize),
        activeIcon: CNSymbol('gearshape.fill', size: _iosTabGlyphSize),
      ),
    ];

    return CNTabBar(
      key: ValueKey(
        'main-nav-${tabIcons?.brightness.name}-'
        '${inactiveBytes?.length}-${activeBytes?.length}-$showHomework',
      ),
      autoHideOnModal: false,
      labelFontSize: 10,
      currentIndex: currentIndex,
      onTap: (index) {
        _onDestinationSelected(
          context: context,
          location: location,
          index: index,
          showHomework: showHomework,
        );
      },
      items: items,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleIosCalendarIconLoad();
  }

  bool _useNativeIosTabBar() {
    return defaultTargetPlatform == TargetPlatform.iOS &&
        PlatformVersion.shouldUseNativeGlass;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final showHomework = ref.watch(guardianHomeworkTabVisibleProvider);
    final currentIndex =
        _tabIndexFromLocation(location, showHomework: showHomework);

    if (!showHomework && location.startsWith(_homeworkPath)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.go(_calendarPath);
      });
    }

    if (_useNativeIosTabBar()) {
      final tabIcons = ref.watch(iosCalendarTabIconsProvider);
      return _buildIosNavigationBar(
        context: context,
        location: location,
        currentIndex: currentIndex,
        tabIcons: tabIcons,
        showHomework: showHomework,
      );
    }
    return _buildMaterialNavigationBar(
      context: context,
      location: location,
      currentIndex: currentIndex,
      showHomework: showHomework,
    );
  }
}
