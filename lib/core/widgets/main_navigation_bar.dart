import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

import '../../features/calendar/presentation/providers/calendar_providers.dart';
import '../../features/calendar/presentation/widgets/search/calendar_search_layer.dart';
import '../haptics/app_haptics.dart';
import 'app_glass_icon_button.dart';
import 'app_hairline_divider.dart';
import 'domspatzen_icon_metrics.dart';

class MainNavigationBar extends ConsumerStatefulWidget {
  const MainNavigationBar({
    required this.searchController,
    super.key,
  });

  final CNTabBarSearchController searchController;

  @override
  ConsumerState<MainNavigationBar> createState() => _MainNavigationBarState();
}

class _MainNavigationBarState extends ConsumerState<MainNavigationBar> {
  Uint8List? _iosInactiveCalendarIcon;
  Uint8List? _iosActiveCalendarIcon;
  Brightness? _iosIconBrightness;

  static const _calendarPath = '/calendar';
  static const _homeworkPath = '/homework';
  static const _settingsPath = '/settings';

  static const _iconLabelSpacingOffset = 5.0;
  static const _materialTabIconSlotSize = 28.0;
  static const _materialTabGlyphSize = 22.0;
  static const _iosTabGlyphSize = 17.0;

  int _tabIndexFromLocation(String location) {
    if (location.startsWith(_homeworkPath)) return 1;
    if (location.startsWith(_settingsPath)) return 2;
    return 0;
  }

  String _routeTargetFromIndex(int index) {
    return switch (index) {
      0 => _calendarPath,
      1 => _homeworkPath,
      _ => _settingsPath,
    };
  }

  void _openSearchMode() {
    AppHaptics.light();
    ref.read(calendarSearchOpenProvider.notifier).open();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_useNativeIosTabBar()) {
      _ensureIosCalendarIcons();
    }
  }

  Future<void> _ensureIosCalendarIcons() async {
    final brightness = Theme.of(context).brightness;
    if (_iosIconBrightness == brightness &&
        _iosInactiveCalendarIcon != null &&
        _iosActiveCalendarIcon != null) {
      return;
    }

    final inactiveColor = _tabIconColor(context, selected: false);
    final activeColor = _tabIconColor(context, selected: true);
    final results = await Future.wait([
      DomspatzenIconMetrics.renderTabIconPngBytes(
        color: inactiveColor,
        glyphSize: _iosTabGlyphSize,
      ),
      DomspatzenIconMetrics.renderTabIconPngBytes(
        color: activeColor,
        glyphSize: _iosTabGlyphSize,
      ),
    ]);

    if (!mounted || Theme.of(context).brightness != brightness) return;
    setState(() {
      _iosIconBrightness = brightness;
      _iosInactiveCalendarIcon = results[0];
      _iosActiveCalendarIcon = results[1];
    });
  }

  void _onDestinationSelected({
    required BuildContext context,
    required String location,
    required int index,
  }) {
    final target = _routeTargetFromIndex(index);
    final searchOpen = ref.read(calendarSearchOpenProvider);

    if (target == _calendarPath && searchOpen) {
      AppHaptics.light();
      exitCalendarSearchToCalendarTab(
        ref,
        context,
        searchController: widget.searchController,
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: NavigationBar(
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
                  );
                },
                destinations: destinations,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12, bottom: 6),
              child: AppGlassIconButton(
                icon: Icons.search,
                tooltip: 'Suchen',
                onPressed: _openSearchMode,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIosNavigationBar({
    required BuildContext context,
    required String location,
    required int currentIndex,
  }) {
    final iosSparrowAssetSize =
        DomspatzenIconMetrics.assetSizeForGlyph(_iosTabGlyphSize);
    final inactiveIconColor = _tabIconColor(context, selected: false);
    final activeIconColor = _tabIconColor(context, selected: true);

    final items = <CNTabBarItem>[
      CNTabBarItem(
        label: 'Kalender',
        imageAsset: _iosInactiveCalendarIcon != null
            ? CNImageAsset(
                DomspatzenIconMetrics.assetPath,
                size: iosSparrowAssetSize,
                imageData: _iosInactiveCalendarIcon,
                imageFormat: 'png',
              )
            : CNImageAsset(
                DomspatzenIconMetrics.assetPath,
                size: iosSparrowAssetSize,
                color: inactiveIconColor,
              ),
        activeImageAsset: _iosActiveCalendarIcon != null
            ? CNImageAsset(
                DomspatzenIconMetrics.assetPath,
                size: iosSparrowAssetSize,
                imageData: _iosActiveCalendarIcon,
                imageFormat: 'png',
              )
            : CNImageAsset(
                DomspatzenIconMetrics.assetPath,
                size: iosSparrowAssetSize,
                color: activeIconColor,
              ),
      ),
      CNTabBarItem(
        label: 'Aufgaben',
        icon: CNSymbol('text.book.closed', size: _iosTabGlyphSize),
        activeIcon: CNSymbol('text.book.closed.fill', size: _iosTabGlyphSize),
      ),
      CNTabBarItem(
        label: 'Dein Chrono',
        icon: CNSymbol('gearshape', size: _iosTabGlyphSize),
        activeIcon: CNSymbol('gearshape.fill', size: _iosTabGlyphSize),
      ),
    ];

    return CNTabBar(
      key: ValueKey(
        'main-nav-${_iosInactiveCalendarIcon != null}-${_iosActiveCalendarIcon != null}',
      ),
      autoHideOnModal: false,
      labelFontSize: 10,
      currentIndex: currentIndex,
      onTap: (index) {
        _onDestinationSelected(
          context: context,
          location: location,
          index: index,
        );
      },
      items: items,
      searchItem: CNTabBarSearchItem(
        placeholder: 'Finde den richtigen Termin',
        automaticallyActivatesSearch: true,
        onSearchChanged: (query) {
          ref.read(calendarSearchQueryProvider.notifier).updateQuery(query);
        },
        onSearchActiveChanged: (active) {
          if (active) {
            ref.read(calendarSearchOpenProvider.notifier).open();
            ref
                .read(calendarSearchInputFocusedProvider.notifier)
                .update(true);
            return;
          }
          ref.read(calendarSearchInputFocusedProvider.notifier).dismiss();
          closeCalendarSearchMode(
            ref,
            searchController: widget.searchController,
            deactivateNativeSearch: false,
          );
        },
        style: CNTabBarSearchStyle(
          iconSize: _iosTabGlyphSize,
          buttonSize: 44,
          searchBarHeight: 44,
          searchBarBorderRadius: 24,
          searchBarPadding: const EdgeInsets.only(left: 12, right: 44),
        ),
      ),
      searchController: widget.searchController,
    );
  }

  bool _useNativeIosTabBar() {
    return defaultTargetPlatform == TargetPlatform.iOS &&
        PlatformVersion.shouldUseNativeGlass;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final currentIndex = _tabIndexFromLocation(location);
    if (_useNativeIosTabBar()) {
      return _buildIosNavigationBar(
        context: context,
        location: location,
        currentIndex: currentIndex,
      );
    }
    return _buildMaterialNavigationBar(
      context: context,
      location: location,
      currentIndex: currentIndex,
    );
  }
}
