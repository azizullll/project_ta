import 'package:flutter/material.dart';

class ForgotPasswordController {
  final TextEditingController emailController = TextEditingController();

  bool validateEmail() {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      return false;
    }
    // Basic email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  void dispose() {
    emailController.dispose();
  }
}
