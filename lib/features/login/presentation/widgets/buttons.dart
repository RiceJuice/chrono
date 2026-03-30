import 'package:flutter/material.dart';

class LoginPrimaryButton extends StatelessWidget {
  const LoginPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.black,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
