import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:mobx/mobx.dart';

import '../../shared/branding/branding_scope.dart';
import '../../shared/services/app_logger.dart';
import '../../shared/widgets/error_snack_bar.dart';
import 'auth_store.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _store = Modular.get<AuthStore>();
  late final ReactionDisposer _errorDisposer;

  @override
  void initState() {
    super.initState();
    AppLogger.info('screen.register.opened');
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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    AppLogger.info('screen.register.submit_tapped');
    if (!_formKey.currentState!.validate()) {
      AppLogger.warning('screen.register.validation_failed');
      showErrorSnackBar(context, 'Preencha nome, e-mail e uma senha válida.');
      return;
    }

    AppLogger.info('screen.register.calling_store');
    final success = await _store.register(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
    );
    AppLogger.info('screen.register.store_returned', context: {
      'success': success,
    });

    if (success) {
      AppLogger.info('screen.register.navigate_projects');
      Modular.to.navigate('/projects/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appName = BrandingScope.of(context).appName;

    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Text(appName,
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text('Criar conta',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Nome'),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Informe o nome'
                          : null,
                    ),
                    const SizedBox(height: 12),
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
                      validator: (value) => value != null && value.length >= 6
                          ? null
                          : 'Use ao menos 6 caracteres',
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
                        icon: const Icon(Icons.person_add),
                        label: Text(_store.isLoading.value
                            ? 'Criando...'
                            : 'Criar conta'),
                      ),
                    ),
                    Observer(
                      builder: (_) => _store.loadingPhase.value == null
                          ? const SizedBox.shrink()
                          : Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                _store.loadingPhase.value!,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
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
