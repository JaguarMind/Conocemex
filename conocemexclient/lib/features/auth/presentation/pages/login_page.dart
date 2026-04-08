import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/login_viewmodel.dart';
import '../widgets/login_form.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<LoginViewModel>(
        builder: (context, viewModel, _) {
          return SafeArea(
            child: LoginForm(viewModel: viewModel),
          );
        },
      ),
    );
  }
}
