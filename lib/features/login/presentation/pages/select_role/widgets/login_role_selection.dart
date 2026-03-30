import 'package:flutter/material.dart';

import '../../../widgets/login_choice_card.dart';

class LoginRoleSelection extends StatelessWidget {
  const LoginRoleSelection({
    super.key,
    required this.selectedRole,
    required this.onSelect,
  });

  final String selectedRole;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LoginChoiceCard(
          title: 'Schüler',
          isSelected: selectedRole == 'Schüler',
          activeColor: const Color(0xFFCBBBA0),
          onTap: () => onSelect('Schüler'),
        ),
        const SizedBox(height: 12),
        LoginChoiceCard(
          title: 'Elternteil',
          isSelected: selectedRole == 'Elternteil',
          activeColor: const Color(0xFF0B5A38),
          onTap: () => onSelect('Elternteil'),
        ),
      ],
    );
  }
}
