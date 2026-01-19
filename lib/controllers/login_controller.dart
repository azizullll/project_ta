import 'package:flutter/material.dart';

class LoginController {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool validateForm() {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      return false;
    }

    // Basic email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(emailController.text)) {
      return false;
    }

    return true;
  }

  void dispose() {
    emailController.dispose();
    passwordController.dispose();
  }
}
