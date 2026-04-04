import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/auth_repository.dart';
import '../../providers/auth_repository_provider.dart';
import '../../routes/login_routes.dart';
import '../../widgets/buttons.dart';
import '../../widgets/login_text_field.dart';
import '../../widgets/top_bar/login_top_bar.dart';

enum _AuthHubSegment { signIn, register }

class AuthHubPage extends ConsumerStatefulWidget {
  const AuthHubPage({super.key});

  @override
  ConsumerState<AuthHubPage> createState() => _AuthHubPageState();
}

class _AuthHubPageState extends ConsumerState<AuthHubPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  _AuthHubSegment _segment = _AuthHubSegment.signIn;
  bool _busy = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitSignIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).signInWithPassword(
            email: _emailController.text,
            password: _passwordController.text,
          );
      if (!mounted) return;
      context.go('/calendar');
    } on AuthRepositoryException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFCBBBA0);
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LoginTopBar(canGoBack: false, onBack: () {}),
              const SizedBox(height: 20),
              Text(
                'Chrono',
                style: GoogleFonts.libreBaskerville(
                  color: Colors.white,
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              SegmentedButton<_AuthHubSegment>(
                segments: const [
                  ButtonSegment(
                    value: _AuthHubSegment.signIn,
                    label: Text('Anmelden'),
                  ),
                  ButtonSegment(
                    value: _AuthHubSegment.register,
                    label: Text('Registrieren'),
                  ),
                ],
                selected: {_segment},
                onSelectionChanged: (s) {
                  setState(() => _segment = s.first);
                },
                style: ButtonStyle(
                  foregroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return Colors.black;
                    }
                    return Colors.white70;
                  }),
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return accent;
                    }
                    return const Color(0xFF1A1A1A);
                  }),
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: _segment == _AuthHubSegment.signIn
                    ? Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            LoginTextField(
                              controller: _emailController,
                              hintText: 'E-mail',
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                final input = value?.trim() ?? '';
                                if (input.isEmpty) {
                                  return 'Bitte E-Mail eingeben.';
                                }
                                if (!emailRegex.hasMatch(input)) {
                                  return 'Bitte eine gültige E-Mail eingeben.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            LoginTextField(
                              controller: _passwordController,
                              hintText: 'Passwort',
                              obscureText: true,
                              validator: (value) {
                                final input = value ?? '';
                                if (input.isEmpty) {
                                  return 'Bitte Passwort eingeben.';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      )
                    : Center(
                        child: Text(
                          'Lege ein Konto an und durchlaufe die nächsten Schritte.',
                          style: GoogleFonts.libreBaskerville(
                            color: Colors.white70,
                            fontSize: 16,
                            height: 1.35,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
              ),
              Align(
                child: _segment == _AuthHubSegment.signIn
                    ? LoginPrimaryButton(
                        label: _busy ? 'Wird angemeldet…' : 'Anmelden',
                        color: accent,
                        onPressed: _busy ? null : _submitSignIn,
                      )
                    : LoginPrimaryButton(
                        label: 'Weiter zur Registrierung',
                        color: accent,
                        onPressed: _busy
                            ? null
                            : () => context.go(LoginPaths.register),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
