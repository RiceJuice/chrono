import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'login_choir_card.dart';

class LoginChoirSelection extends StatefulWidget {
  const LoginChoirSelection({
    super.key,
    required this.selectedPage,
    required this.selectedVoice,
    required this.onPageChanged,
    required this.onVoiceChanged,
  });

  final int selectedPage;
  final String selectedVoice;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<String> onVoiceChanged;

  @override
  State<LoginChoirSelection> createState() => _LoginChoirSelectionState();
}

class _LoginChoirSelectionState extends State<LoginChoirSelection> {
  static const int _initialPageOffset = 10000;
  static const double _targetPageExtent = 305;
  static const _choirs = ['DKM', 'Giehl', 'Rädlinger', 'Schola', 'Szuczies'];
  static const _choirImages = [
    'assets/Carusell/Heiß.jpg',
    'assets/Carusell/Giehl.jpg',
    'assets/Carusell/Rädlinger.jpg',
    null,
    'assets/Carusell/Szuczies.jpg',
  ];

  PageController? _controller;
  double? _viewportFraction;

  int get _initialVirtualPage => _initialPageOffset + widget.selectedPage;

  void _configureController(double viewportWidth) {
    final double viewportFraction = _targetPageExtent / viewportWidth;
    final PageController? currentController = _controller;
    if (currentController != null &&
        (_viewportFraction! - viewportFraction).abs() < 0.001) {
      return;
    }

    final int initialPage = currentController?.hasClients == true
        ? (currentController!.page ?? _initialVirtualPage.toDouble()).round()
        : _initialVirtualPage;
    _viewportFraction = viewportFraction;
    _controller = PageController(
      viewportFraction: viewportFraction,
      initialPage: initialPage,
    );
    if (currentController != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        currentController.dispose();
      });
    }
  }

  double _carouselCurrentPage() {
    final PageController? controller = _controller;
    final double initialVirtualPage = _initialVirtualPage.toDouble();
    final bool ready =
        controller != null &&
        controller.hasClients &&
        controller.positions.length == 1;
    if (!ready) return initialVirtualPage;
    return controller.page ?? initialVirtualPage;
  }

  int _activeChoirIndex() {
    final double page = _carouselCurrentPage();
    final int n = _choirs.length;
    return (page.round() % n + n) % n;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final double screenHeight = MediaQuery.sizeOf(context).height;
    final double carouselHeight = (screenHeight * 0.44).clamp(330.0, 430.0);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double carouselViewportWidth = screenWidth;
        _configureController(carouselViewportWidth);
        final PageController controller = _controller!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: carouselHeight,
              width: double.infinity,
              child: OverflowBox(
                alignment: Alignment.center,
                minWidth: carouselViewportWidth,
                maxWidth: carouselViewportWidth,
                child: SizedBox(
                  width: carouselViewportWidth,
                  height: carouselHeight,
                  child: PageView.builder(
                    controller: controller,
                    clipBehavior: Clip.none,
                    onPageChanged: (index) {
                      HapticFeedback.mediumImpact();
                      widget.onPageChanged(index % _choirs.length);
                    },
                    itemBuilder: (context, index) {
                      final choirIndex = index % _choirs.length;
                      return AnimatedBuilder(
                        animation: controller,
                        builder: (context, _) {
                          final currentPage = _carouselCurrentPage();
                          final distance = (currentPage - index).abs();
                          final scale = (1 - (distance * 0.05)).clamp(
                            0.94,
                            1.0,
                          );
                          final activeChoirIndex = _activeChoirIndex();
                          final Alignment scaleAlignment = index < currentPage
                              ? Alignment.centerLeft
                              : index > currentPage
                              ? Alignment.centerRight
                              : Alignment.center;

                          return Transform.scale(
                            scale: scale,
                            alignment: scaleAlignment,
                            child: LoginChoirCard(
                              label: _choirs[choirIndex],
                              isActive: choirIndex == activeChoirIndex,
                              imageAsset: _choirImages[choirIndex],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                final activeChoirIndex = _activeChoirIndex();
                return Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_choirs.length, (index) {
                      final selected = index == activeChoirIndex;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: selected ? 24 : 12,
                          height: 4,
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFFCBBBA0)
                                : scheme.onSurface.withValues(alpha: 0.28),
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
