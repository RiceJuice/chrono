import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

import '../../features/calendar/presentation/providers/calendar_providers.dart';
import 'app_hairline_divider.dart';

class MainNavigationBar extends ConsumerWidget {
  const MainNavigationBar({super.key});

  static const _calendarPath = '/calendar';
  static const _settingsPath = '/settings';
  static const _iconLabelSpacingOffset = 5.0;
  static const _tabIconSize = 22.0;
  /// Material-Icons wirken größer als das Spatz-SVG — optisch angleichen.
  static const _settingsTabIconSize = 19.5;
  static const _calendarAssetPath = 'assets/domspatzen.svg';

  int _indexFromLocation(String location) {
    if (location.startsWith(_settingsPath)) return 1;
    return 0;
  }

  String _targetFromIndex(int index) {
    return index == 0 ? _calendarPath : _settingsPath;
  }

  void _onDestinationSelected({
    required BuildContext context,
    required WidgetRef ref,
    required String location,
    required int index,
  }) {
    final target = _targetFromIndex(index);
    if (target == _calendarPath && location == _calendarPath) {
      final now = DateTime.now().toLocal();
      final today = DateTime(now.year, now.month, now.day);
      ref.read(selectedDayProvider.notifier).update(today);
      ref.read(focusedDayProvider.notifier).update(today);
      return;
    }
    if (target != location) {
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
    return SvgPicture.asset(
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
    );
  }

  Widget _buildSettingsIcon({
    required BuildContext context,
    required bool selected,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Icon(
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
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppHairlineDivider.horizontal(),
        NavigationBar(
          selectedIndex: currentIndex,
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
            );
          },
          destinations: [
            NavigationDestination(
              icon: _tabIconSlot(
                _buildCalendarIcon(
                  context: context,
                  selected: currentIndex == 0,
                ),
              ),
              label: 'Kalender',
            ),
            NavigationDestination(
              icon: _tabIconSlot(
                _buildSettingsIcon(
                  context: context,
                  selected: currentIndex == 1,
                ),
              ),
              label: 'Dein Chrono',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIosNavigationBar({
    required BuildContext context,
    required WidgetRef ref,
    required String location,
    required int currentIndex,
  }) {
    final inactiveIconColor =
        Theme.of(context).colorScheme.onSurfaceVariant;

    // Kein SafeArea-Wrapper: Die native Glass-TabBar verwaltet den unteren
    // Safe-Area-Inset selbst und blurrt den dahinter durchscrollenden Inhalt.
    // Ein zusätzlicher SafeArea würde die Bar nach oben schieben und darunter
    // eine schwarze Box hinterlassen.
    return CNTabBar(
      // Nicht auto-hide: sonst wird die native UiKitView bei Modals zerstört und
      // beim Schließen neu aufgebaut (Theme-Flash, Tab-Sprung). Das Ausblenden
      // übernimmt [_ModalAwareNavBar] per IndexedStack ohne Platform-View-Recreate.
      autoHideOnModal: false,
      iconSize: _tabIconSize,
      currentIndex: currentIndex,
      onTap: (index) {
        _onDestinationSelected(
          context: context,
          ref: ref,
          location: location,
          index: index,
        );
      },
      items: [
        CNTabBarItem(
          label: 'Kalender',
          imageAsset: CNImageAsset(
            _calendarAssetPath,
            size: _tabIconSize,
            color: inactiveIconColor,
          ),
          activeImageAsset: const CNImageAsset(
            _calendarAssetPath,
            size: _tabIconSize,
          ),
        ),
        const CNTabBarItem(
          label: 'Dein Chrono',
          icon: CNSymbol('gearshape'),
          activeIcon: CNSymbol('gearshape.fill'),
        ),
      ],
    );
  }

  bool _useNativeIosTabBar() {
    return defaultTargetPlatform == TargetPlatform.iOS &&
        PlatformVersion.shouldUseNativeGlass;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final currentIndex = _indexFromLocation(location);
    if (_useNativeIosTabBar()) {
      return _buildIosNavigationBar(
        context: context,
        ref: ref,
        location: location,
        currentIndex: currentIndex,
      );
    }
    return _buildMaterialNavigationBar(
      context: context,
      ref: ref,
      location: location,
      currentIndex: currentIndex,
    );
  }
}
