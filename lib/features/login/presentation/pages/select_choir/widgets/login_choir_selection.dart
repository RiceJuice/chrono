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
  static const _choirs = ['Giehl', 'DKM', 'Rädlinger', 'Szucies', 'Schola'];

  late final PageController _controller = PageController(
    viewportFraction: 0.74,
    initialPage: _initialPageOffset + widget.selectedPage,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 350,
          width: double.infinity,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (index) {
              HapticFeedback.mediumImpact();
              widget.onPageChanged(index % _choirs.length);
            },
            itemBuilder: (context, index) {
              final choirIndex = index % _choirs.length;
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final initialVirtualPage =
                      (_initialPageOffset + widget.selectedPage).toDouble();
                  final hasSingleAttachedPageView =
                      _controller.positions.length == 1;
                  final currentPage = hasSingleAttachedPageView
                      ? (_controller.page ?? initialVirtualPage)
                      : initialVirtualPage;
                  final distance = (currentPage - index).abs();
                  final scale = (1 - (distance * 0.08)).clamp(0.90, 1.0);
                  final opacity = (1 - (distance * 0.35)).clamp(0.35, 1.0);

                  return Transform.scale(
                    scale: scale,
                    child: Opacity(opacity: opacity, child: child),
                  );
                },
                child: LoginChoirCard(
                  label: _choirs[choirIndex],
                  isActive: choirIndex == widget.selectedPage,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_choirs.length, (index) {
              final selected = index == widget.selectedPage;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: selected ? 24 : 12,
                  height: 4,
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFFCBBBA0)
                        : Colors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              );
            }),
          ),
        ),

      ],
    );
  }
}

