import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'connectivity_notifier.dart';

/// Vollbild-Hinweis: ohne Internet ist keine Anmeldung möglich.
class NoConnectionPage extends StatefulWidget {
  const NoConnectionPage({super.key, required this.connectivity});

  final ConnectivityNotifier connectivity;

  @override
  State<NoConnectionPage> createState() => _NoConnectionPageState();
}

class _NoConnectionPageState extends State<NoConnectionPage> {
  bool _checking = false;

  Future<void> _onRetry() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      await widget.connectivity.recheck();
      if (!mounted) return;
      GoRouter.of(context).refresh();
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 72,
                color: scheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Keine Verbindung',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Für die Anmeldung wird eine Internetverbindung benötigt. '
                'Bitte prüfe dein Netzwerk und versuche es erneut. Danach kannst du ohne Internet weiterarbeiten.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    textStyle: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: _checking ? null : _onRetry,
                  icon: _checking
                      ? SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: scheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.refresh_rounded, size: 26),
                  label: Text(
                    _checking ? 'Verbindung wird geprüft …' : 'Erneut versuchen',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
