import 'package:flutter/cupertino.dart';
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

  Widget _buildCalendarIcon({
    required BuildContext context,
    required bool selected,
    required bool useCupertinoColors,
  }) {
    return SvgPicture.asset(
      'assets/domspatzen.svg',
      height: 22,
      width: 22,
      colorFilter: selected
          ? null
          : ColorFilter.mode(
              useCupertinoColors
                  ? CupertinoColors.inactiveGray.resolveFrom(context)
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              BlendMode.srcIn,
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
              icon: Transform.translate(
                offset: const Offset(0, _iconLabelSpacingOffset),
                child: _buildCalendarIcon(
                  context: context,
                  selected: currentIndex == 0,
                  useCupertinoColors: false,
                ),
              ),
              label: 'Kalender',
            ),
            NavigationDestination(
              icon: Transform.translate(
                offset: const Offset(0, _iconLabelSpacingOffset),
                child: Icon(
                  currentIndex == 1 ? Icons.settings : Icons.settings_outlined,
                  color: currentIndex == 1
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 22,
                ),
              ),
              label: 'Dein Chrono',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCupertinoNavigationBar({
    required BuildContext context,
    required WidgetRef ref,
    required String location,
    required int currentIndex,
  }) {
    final borderColor = CupertinoColors.separator.resolveFrom(context);
    final backgroundColor = CupertinoDynamicColor.withBrightness(
      color: const Color.fromRGBO(248, 248, 248, 0.76),
      darkColor: const Color.fromRGBO(30, 30, 30, 0.72),
    ).resolveFrom(context);

    return CupertinoTabBar(
      currentIndex: currentIndex,
      iconSize: 22,
      activeColor: CupertinoColors.activeBlue.resolveFrom(context),
      inactiveColor: CupertinoColors.inactiveGray.resolveFrom(context),
      backgroundColor: backgroundColor,
      border: Border(top: BorderSide(color: borderColor, width: 0)),
      onTap: (index) {
        _onDestinationSelected(
          context: context,
          ref: ref,
          location: location,
          index: index,
        );
      },
      items: [
        BottomNavigationBarItem(
          icon: _buildCalendarIcon(
            context: context,
            selected: currentIndex == 0,
            useCupertinoColors: true,
          ),
          label: 'Kalender',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            currentIndex == 1
                ? CupertinoIcons.settings_solid
                : CupertinoIcons.settings,
          ),
          label: 'Dein Chrono',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final currentIndex = _indexFromLocation(location);
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _buildCupertinoNavigationBar(
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
