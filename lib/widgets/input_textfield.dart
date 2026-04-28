import 'package:flutter/material.dart';
import 'package:soundstatus/core/widget/theme.dart';

class InputField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboard;
  final Widget? prefix;
  final bool obscure;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  const InputField({
    super.key,
    required this.hint,
    required this.controller,
    this.keyboard,
    this.prefix,
    this.obscure = false,
    this.suffix,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      obscureText: obscure,
      onChanged: onChanged,
      style: TextStyle(color: context.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: c.textMuted, fontSize: 14),
        prefixIcon: prefix,
        suffixIcon: suffix,
        filled: true,
        fillColor: c.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: AppColors.primaryColor,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
