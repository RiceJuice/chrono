import 'package:flutter/material.dart';
import 'day_page.dart';

class EventListPageTransition extends StatelessWidget {
  const EventListPageTransition({
    super.key,
    required this.fromDate,
    required this.toDate,
    required this.isForward,
    required this.animation,
  });

  final DateTime fromDate;
  final DateTime toDate;
  final bool isForward;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
    final outgoingEndX = isForward ? -1.0 : 1.0;
    final incomingStartX = isForward ? 1.0 : -1.0;

    return IgnorePointer(
      child: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Stack(
          children: [
            SlideTransition(
              position: Tween<Offset>(
                begin: Offset.zero,
                end: Offset(outgoingEndX, 0),
              ).animate(curved),
              child: DayPage(
                key: ValueKey<String>('from-$fromDate'),
                date: fromDate,
              ),
            ),
            SlideTransition(
              position: Tween<Offset>(
                begin: Offset(incomingStartX, 0),
                end: Offset.zero,
              ).animate(curved),
              child: DayPage(
                key: ValueKey<String>('to-$toDate'),
                date: toDate,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
