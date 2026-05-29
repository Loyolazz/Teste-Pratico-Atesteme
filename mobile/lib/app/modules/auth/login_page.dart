import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:mobx/mobx.dart';

import '../../shared/branding/branding_scope.dart';
import '../../shared/widgets/error_snack_bar.dart';
import 'auth_store.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _store = Modular.get<AuthStore>();
  late final ReactionDisposer _errorDisposer;

  @override
  void initState() {
    super.initState();
    _errorDisposer = reaction<String?>(
      (_) => _store.error.value,
      (message) {
        if (message != null) {
          showErrorSnackBar(context, message);
        }
      },
    );
  }

  @override
  void dispose() {
    _errorDisposer();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      showErrorSnackBar(context, 'Preencha e-mail e senha para entrar.');
      return;
    }

    final success = await _store.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success) {
      Modular.to.navigate('/projects/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appName = BrandingScope.of(context).appName;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(appName,
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'E-mail'),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Informe o e-mail'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Senha'),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Informe a senha'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Observer(
                      builder: (_) => _store.error.value == null
                          ? const SizedBox.shrink()
                          : Text(_store.error.value!,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error)),
                    ),
                    const SizedBox(height: 16),
                    Observer(
                      builder: (_) => FilledButton.icon(
                        onPressed: _store.isLoading.value ? null : _submit,
                        icon: const Icon(Icons.login),
                        label: Text(
                            _store.isLoading.value ? 'Entrando...' : 'Entrar'),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Modular.to.navigate('/auth/register'),
                      child: const Text('Criar cadastro'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
