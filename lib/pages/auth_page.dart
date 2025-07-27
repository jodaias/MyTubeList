import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/firebase_profile_provider.dart';
import '../providers/local_profiles_provider.dart';
import '../utils/confirmation_modal.dart';
import '../models/profile_model.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  ProfileModel? _selectedProfile;

  @override
  void initState() {
    super.initState();
    // Verificar se recebeu um perfil como argumento
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['profile'] != null) {
        _selectedProfile = args['profile'] as ProfileModel;
        _usernameController.text = _selectedProfile!.username ?? '';
        _passwordController.text = '';
        setState(() {
          _isLogin = true;
        });

        // Se usernameReadOnly é true, não fazer login automático
        final usernameReadOnly = args['usernameReadOnly'] as bool? ?? false;
        if (!usernameReadOnly) {
          // Fazer login automático apenas se não for modo somente leitura
          _handleSubmit();
        }
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _selectedProfile != null
              ? 'Login - ${_selectedProfile!.name}'
              : (_isLogin ? 'Login' : 'Criar Conta'),
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo ou título
                const Icon(
                  Icons.person,
                  size: 80,
                  color: Colors.green,
                ),
                const SizedBox(height: 20),
                Text(
                  _isLogin ? 'Faça Login' : 'Crie sua Conta',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),

                // Campo Username
                TextFormField(
                  controller: _usernameController,
                  enabled:
                      _selectedProfile == null, // Disable se perfil selecionado
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.none,
                  onChanged: (value) {
                    // Remover espaços, acentos e converter para minúsculo
                    String cleanValue = value
                        .toLowerCase() // Converter para minúsculo
                        .replaceAll(RegExp(r'\s'), '') // Remove espaços
                        .replaceAll(RegExp(r'[áàâãä]'), 'a')
                        .replaceAll(RegExp(r'[éèêë]'), 'e')
                        .replaceAll(RegExp(r'[íìîï]'), 'i')
                        .replaceAll(RegExp(r'[óòôõö]'), 'o')
                        .replaceAll(RegExp(r'[úùûü]'), 'u')
                        .replaceAll(
                            RegExp(r'[çÇ]'), 'c') // Converter ç e Ç para c
                        .replaceAll(RegExp(r'[^a-z0-9_]'),
                            ''); // Apenas letras, números e underscore

                    if (value != cleanValue) {
                      final selection = _usernameController.selection;
                      _usernameController.value = TextEditingValue(
                        text: cleanValue,
                        selection:
                            TextSelection.collapsed(offset: cleanValue.length),
                      );
                    }
                  },
                  decoration: InputDecoration(
                    labelText: _selectedProfile != null
                        ? 'Usuário selecionado'
                        : 'Nome de usuário',
                    hintText: 'Ex: joao123',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person),
                    suffixIcon: _selectedProfile !=
                            null // Mostrar ícone de cadeado se read-only
                        ? const Icon(Icons.lock, color: Colors.grey)
                        : null,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Digite um nome de usuário';
                    }
                    if (value.length < 3) {
                      return 'Nome de usuário deve ter pelo menos 3 caracteres';
                    }
                    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(value)) {
                      return 'Apenas letras minúsculas, números e underscore';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Campo Senha
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  keyboardType: TextInputType.visiblePassword,
                  onChanged: (value) {
                    // Remover espaços e acentos da senha
                    String cleanValue = value
                        .replaceAll(RegExp(r'\s'), '') // Remove espaços
                        .replaceAll(RegExp(r'[áàâãä]'), 'a')
                        .replaceAll(RegExp(r'[éèêë]'), 'e')
                        .replaceAll(RegExp(r'[íìîï]'), 'i')
                        .replaceAll(RegExp(r'[óòôõö]'), 'o')
                        .replaceAll(RegExp(r'[úùûü]'), 'u');

                    if (value != cleanValue) {
                      final selection = _passwordController.selection;
                      _passwordController.value = TextEditingValue(
                        text: cleanValue,
                        selection:
                            TextSelection.collapsed(offset: cleanValue.length),
                      );
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    hintText: 'Digite sua senha',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Digite sua senha';
                    }
                    if (value.length < 6) {
                      return 'A senha deve ter pelo menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Campo Nome (apenas para registro)
                if (!_isLogin) ...[
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome completo',
                      hintText: 'Digite seu nome',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.badge),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Digite seu nome';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Mensagem de erro
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Botão de login/criar conta
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _selectedProfile != null
                                ? 'Entrar'
                                : (_isLogin ? 'Entrar' : 'Criar Conta'),
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Botão para alternar entre login e criar conta (só mostrar se não recebeu perfil)
                if (_selectedProfile == null)
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() {
                              _isLogin = !_isLogin;
                              _errorMessage = null;
                            });
                          },
                    child: Text(
                      _isLogin
                          ? 'Não tem uma conta? Criar conta'
                          : 'Já tem uma conta? Entrar',
                      style: TextStyle(color: Colors.green[700]),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final firebaseProvider = context.read<FirebaseProfileProvider>();
      final localProfilesProvider = context.read<LocalProfilesProvider>();
      bool success;

      if (_isLogin) {
        success = await firebaseProvider.signInWithUsername(
          _usernameController.text.trim(),
          _passwordController.text,
        );
      } else {
        success = await firebaseProvider.createUserWithPassword(
          _usernameController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
        );

        // Se criou conta com sucesso, salvar perfil localmente
        if (success) {
          try {
            final newProfile = ProfileModel(
              id: _usernameController.text.trim(),
              name: _nameController.text.trim(),
              username: _usernameController.text.trim(),
              password: null, // Não armazenar senha localmente
            );

            await localProfilesProvider.addProfile(newProfile);
          } catch (e) {
            // Não falhar se não conseguir salvar localmente
          }
        }
      }

      if (success) {
        // Navegar para a página principal
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() {
          _errorMessage =
              _isLogin ? 'Usuário ou senha incorretos' : 'Erro ao criar conta';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
