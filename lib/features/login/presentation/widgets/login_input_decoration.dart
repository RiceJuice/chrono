import 'package:flutter/material.dart';

InputDecoration loginInputDecoration(String hintText) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: const TextStyle(color: Colors.white54, fontSize: 13),
    filled: true,
    fillColor: Colors.transparent,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.white30),
    ),
  );
}
