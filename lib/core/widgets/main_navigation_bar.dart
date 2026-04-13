import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

import '../../features/calendar/presentation/providers/calendar_providers.dart';

class MainNavigationBar extends ConsumerWidget {
  const MainNavigationBar({super.key});

  static const _calendarPath = '/calendar';
  static const _settingsPath = '/settings';
  static const _iconLabelSpacingOffset = 5.0;


  int _indexFromLocation(String location) {
    if (location.startsWith(_settingsPath)) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final currentIndex = _indexFromLocation(location);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(),
        NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (int index) {
            final target = index == 0 ? _calendarPath : _settingsPath;
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
          },
          destinations: [
            NavigationDestination(
              icon: Transform.translate(
                offset: const Offset(0, _iconLabelSpacingOffset),
                child: SvgPicture.asset(
                  'assets/domspatzen.svg',
                  height: 24,
                  width: 24,
                  colorFilter: currentIndex != 0
                      ? ColorFilter.mode(
                          Theme.of(context).colorScheme.onSurfaceVariant,
                          BlendMode.srcIn,
                        )
                      : null,
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
                ),
              ),
              label: 'Dein Chrono',
            ),
          ],
        ),
      ],
    );
  }
}
