import 'package:flutter/material.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';

InputDecoration loginInputDecoration(String hintText) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: const TextStyle(fontSize: 13),
    filled: true,
    fillColor: Colors.transparent,
    contentPadding: AppInsets.inputContent,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.s),
      borderSide: BorderSide(
        color: Colors.white.withValues(alpha: AppOpacity.low),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.s),
      borderSide: const BorderSide(color: Colors.white30),
    ),
  );
}
