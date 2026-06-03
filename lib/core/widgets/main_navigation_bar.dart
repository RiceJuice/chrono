import 'dart:async';

import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

import '../../features/calendar/event_editor/presentation/pages/calendar_event_form_page.dart';
import '../../features/calendar/event_editor/presentation/providers/is_admin_provider.dart';
import '../../features/calendar/presentation/providers/calendar_providers.dart';
import '../haptics/app_haptics.dart';
import 'app_hairline_divider.dart';
import 'app_modal_sheet.dart';

class MainNavigationBar extends ConsumerWidget {
  const MainNavigationBar({super.key});

  static const _calendarPath = '/calendar';
  static const _homeworkPath = '/homework';
  static const _settingsPath = '/settings';

  /// Admin: Index des „Neuer Termin“-Tabs (öffnet Erstellen-Sheet).
  static const int _adminCreateTabIndex = 1;

  static const _iconLabelSpacingOffset = 5.0;
  static const _tabIconSize = 22.0;
  static const _calendarAssetPath = 'assets/domspatzen.svg';

  /// Sichtbare Motivgrenzen im Spatz-SVG (viewBox 0…1024).
  static const _sparrowViewBoxHeight = 1024.0;
  static const _sparrowVisualTopY = 139.0;
  static const _sparrowVisualBottomY = 889.5;

  static double get _sparrowVisualTopInset =>
      _tabIconSize * (_sparrowVisualTopY / _sparrowViewBoxHeight);

  /// Sichtbare Höhe des Zahnrad-Icons (Referenz für Hausaufgaben).
  static double get _settingsTabIconSize =>
      _tabIconSize *
      ((_sparrowVisualBottomY - _sparrowVisualTopY) / _sparrowViewBoxHeight);

  /// Material-[Icons.menu_book] wirkt bei gleicher pt-Größe größer als das Zahnrad.
  static const _homeworkIconOpticalScale = 0.86;

  static double get _homeworkTabIconSize =>
      _settingsTabIconSize * _homeworkIconOpticalScale;

  /// Optisch an Hausaufgaben/Zahnrad angeglichen (nicht am Spatz).
  static double get _createEventTabIconSize => _homeworkTabIconSize;

  Widget _buildTopAlignedTabIcon(Widget icon) {
    return Padding(
      padding: EdgeInsets.only(top: _sparrowVisualTopInset),
      child: icon,
    );
  }

  int _tabIndexFromLocation(String location, {required bool isAdmin}) {
    if (location.startsWith(_homeworkPath)) return isAdmin ? 2 : 1;
    if (location.startsWith(_settingsPath)) return isAdmin ? 3 : 2;
    return 0;
  }

  String? _routeTargetFromIndex(int index, {required bool isAdmin}) {
    if (!isAdmin) {
      return switch (index) {
        0 => _calendarPath,
        1 => _homeworkPath,
        _ => _settingsPath,
      };
    }
    return switch (index) {
      0 => _calendarPath,
      _adminCreateTabIndex => null,
      2 => _homeworkPath,
      _ => _settingsPath,
    };
  }

  void _openCreateEventSheet(BuildContext context, WidgetRef ref, String location) {
    if (AppModalSheetTracker.depth.value > 0) return;

    AppHaptics.light();

    void present() {
      if (!context.mounted) return;
      final day = ref.read(selectedDayProvider);
      unawaited(
        CalendarEventFormPage.showCreate(context, initialDay: day),
      );
    }

    if (location != _calendarPath) {
      context.go(_calendarPath);
      WidgetsBinding.instance.addPostFrameCallback((_) => present());
      return;
    }
    present();
  }

  void _onDestinationSelected({
    required BuildContext context,
    required WidgetRef ref,
    required String location,
    required int index,
    required bool isAdmin,
  }) {
    if (isAdmin && index == _adminCreateTabIndex) {
      _openCreateEventSheet(context, ref, location);
      return;
    }

    final target = _routeTargetFromIndex(index, isAdmin: isAdmin);
    if (target == null) return;

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
        width: _tabIconSize,
        height: _tabIconSize,
        child: icon,
      ),
    );
  }

  Widget _buildCalendarIcon({
    required BuildContext context,
    required bool selected,
  }) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SvgPicture.asset(
        _calendarAssetPath,
        height: _tabIconSize,
        width: _tabIconSize,
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
        colorFilter: selected
            ? null
            : ColorFilter.mode(
                Theme.of(context).colorScheme.onSurfaceVariant,
                BlendMode.srcIn,
              ),
      ),
    );
  }

  Widget _buildHomeworkIcon({
    required BuildContext context,
    required bool selected,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return _buildTopAlignedTabIcon(
      Icon(
        selected ? Icons.menu_book : Icons.menu_book_outlined,
        size: _homeworkTabIconSize,
        color: selected ? scheme.primary : scheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildCreateEventIcon({
    required BuildContext context,
    required bool selected,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return _buildTopAlignedTabIcon(
      Icon(
        selected ? Icons.event_available : Icons.event_available_outlined,
        size: _createEventTabIconSize,
        color: selected ? scheme.primary : scheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildSettingsIcon({
    required BuildContext context,
    required bool selected,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return _buildTopAlignedTabIcon(
      Icon(
        selected ? Icons.settings : Icons.settings_outlined,
        size: _settingsTabIconSize,
        color: selected ? scheme.primary : scheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildMaterialNavigationBar({
    required BuildContext context,
    required WidgetRef ref,
    required String location,
    required int currentIndex,
    required bool isAdmin,
  }) {
    final destinations = <NavigationDestination>[
      NavigationDestination(
        icon: _tabIconSlot(
          _buildCalendarIcon(
            context: context,
            selected: currentIndex == 0,
          ),
        ),
        label: 'Kalender',
      ),
      if (isAdmin)
        NavigationDestination(
          icon: _tabIconSlot(
            _buildCreateEventIcon(
              context: context,
              selected: currentIndex == _adminCreateTabIndex,
            ),
          ),
          label: 'Termin',
          tooltip: 'Neuer Termin',
        ),
      NavigationDestination(
        icon: _tabIconSlot(
          _buildHomeworkIcon(
            context: context,
            selected: currentIndex == (isAdmin ? 2 : 1),
          ),
        ),
        label: 'Aufgaben',
      ),
      NavigationDestination(
        icon: _tabIconSlot(
          _buildSettingsIcon(
            context: context,
            selected: currentIndex == (isAdmin ? 3 : 2),
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
          height: isAdmin ? 56 : null,
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
              ref: ref,
              location: location,
              index: index,
              isAdmin: isAdmin,
            );
          },
          destinations: destinations,
        ),
      ],
    );
  }

  Widget _buildIosNavigationBar({
    required BuildContext context,
    required WidgetRef ref,
    required String location,
    required int currentIndex,
    required bool isAdmin,
  }) {
    final inactiveIconColor =
        Theme.of(context).colorScheme.onSurfaceVariant;

    final items = <CNTabBarItem>[
      CNTabBarItem(
        label: 'Kalender',
        imageAsset: CNImageAsset(
          _calendarAssetPath,
          size: _tabIconSize,
          color: inactiveIconColor,
        ),
        activeImageAsset: CNImageAsset(
          _calendarAssetPath,
          size: _tabIconSize,
        ),
      ),
      if (isAdmin)
        CNTabBarItem(
          label: 'Termin',
          icon: CNSymbol('calendar.badge.plus', size: _createEventTabIconSize),
          activeIcon: CNSymbol(
            'calendar.badge.plus',
            size: _createEventTabIconSize,
          ),
        ),
      CNTabBarItem(
        label: 'Aufgaben',
        icon: CNSymbol('text.book.closed', size: _homeworkTabIconSize),
        activeIcon:
            CNSymbol('text.book.closed.fill', size: _homeworkTabIconSize),
      ),
      CNTabBarItem(
        label: 'Dein Chrono',
        icon: CNSymbol('gearshape', size: _settingsTabIconSize),
        activeIcon: CNSymbol('gearshape.fill', size: _settingsTabIconSize),
      ),
    ];

    // Kein SafeArea-Wrapper: Die native Glass-TabBar verwaltet den unteren
    // Safe-Area-Inset selbst und blurrt den dahinter durchscrollenden Inhalt.
    // Ein zusätzlicher SafeArea würde die Bar nach oben schieben und darunter
    // eine schwarze Box hinterlassen.
    return CNTabBar(
      autoHideOnModal: false,
      labelFontSize: 10,
      currentIndex: currentIndex,
      onTap: (index) {
        _onDestinationSelected(
          context: context,
          ref: ref,
          location: location,
          index: index,
          isAdmin: isAdmin,
        );
      },
      items: items,
    );
  }

  bool _useNativeIosTabBar() {
    return defaultTargetPlatform == TargetPlatform.iOS &&
        PlatformVersion.shouldUseNativeGlass;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
    final location = GoRouterState.of(context).uri.path;
    final currentIndex = _tabIndexFromLocation(location, isAdmin: isAdmin);
    if (_useNativeIosTabBar()) {
      return _buildIosNavigationBar(
        context: context,
        ref: ref,
        location: location,
        currentIndex: currentIndex,
        isAdmin: isAdmin,
      );
    }
    return _buildMaterialNavigationBar(
      context: context,
      ref: ref,
      location: location,
      currentIndex: currentIndex,
      isAdmin: isAdmin,
    );
  }
}
