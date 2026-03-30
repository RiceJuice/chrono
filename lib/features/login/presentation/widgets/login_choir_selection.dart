import 'package:flutter/material.dart';

import '../pages/select_choir/widgets/login_choir_card.dart';
import 'login_input_decoration.dart';

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
  late final PageController _controller = PageController(
    viewportFraction: 0.74,
    initialPage: widget.selectedPage,
  );

  static const _voices = ['Tenor', 'Sopran', 'Alt', 'Bass'];
  static const _choirs = ['JMK', 'DKM', 'JKM'];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: widget.onPageChanged,
            itemCount: _choirs.length,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final currentPage = _controller.hasClients
                      ? (_controller.page ?? widget.selectedPage.toDouble())
                      : widget.selectedPage.toDouble();
                  final distance = (currentPage - index).abs();
                  final scale = (1 - (distance * 0.08)).clamp(0.90, 1.0);
                  final opacity = (1 - (distance * 0.35)).clamp(0.35, 1.0);

                  return Transform.scale(
                    scale: scale,
                    child: Opacity(opacity: opacity, child: child),
                  );
                },
                child: LoginChoirCard(
                  label: _choirs[index],
                  isActive: index == widget.selectedPage,
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
                  width: selected ? 18 : 8,
                  height: 3,
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
        const SizedBox(height: 22),
        const Text('Stimme', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: widget.selectedVoice,
          dropdownColor: const Color(0xFF121212),
          iconEnabledColor: Colors.white,
          style: const TextStyle(color: Colors.white),
          decoration: loginInputDecoration('Stimme'),
          items: _voices
              .map(
                (voice) =>
                    DropdownMenuItem<String>(value: voice, child: Text(voice)),
              )
              .toList(),
          onChanged: (voice) {
            if (voice != null) {
              widget.onVoiceChanged(voice);
            }
          },
        ),
      ],
    );
  }
}
