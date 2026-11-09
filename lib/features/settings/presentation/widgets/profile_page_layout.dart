import 'package:flutter/material.dart';

import '../../../../core/widgets/main_shell_scaffold.dart';

/// A centered single column on iPhone, iPad and narrow app windows.
class ProfilePageLayout extends StatelessWidget {
  const ProfilePageLayout({
    super.key,
    required this.header,
    required this.account,
  });

  final Widget header;
  final Widget account;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        32 + mainShellBottomContentInset(context),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [header, const SizedBox(height: 28), account],
          ),
        ),
      ),
    );
  }
}
