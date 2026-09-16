import 'package:flutter/material.dart';

import 'login_screen.dart';

/// RegisterScreen = LoginScreen dalam mode daftar.
/// Route /register → layar identik tetapi berawal dari tab "Daftar Akun Baru".
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginScreen(initialMode: AuthMode.register);
  }
}