import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/firebase_profile_provider.dart';
import '../providers/local_profiles_provider.dart';
import '../models/profile_model.dart';
import '../services/biometric_service.dart';

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

  final BiometricService _biometricService = BiometricService();
  bool _biometricAvailable = false;
  bool _biometricEnabledForProfile = false;

  @override
  void initState() {
    super.initState();
    // Verificar se recebeu um perfil como argumento
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['profile'] != null) {
        _selectedProfile = args['profile'] as ProfileModel;
        _usernameController.text = _selectedProfile?.username ?? '';
        _passwordController.text = '';
        setState(() {
          _isLogin = true;
        });

        // Verificar biometria
        await _checkBiometric();

        // Se usernameReadOnly é true, não fazer login automático
        final usernameReadOnly = args['usernameReadOnly'] as bool? ?? false;
        if (!usernameReadOnly) {
          // Fazer login automático apenas se não for modo somente leitura
          _handleSubmit();
        } else if (_biometricAvailable && _biometricEnabledForProfile) {
          // Tentar login biométrico automaticamente
          _handleBiometricLogin();
        }
      }
    });
  }

  Future<void> _checkBiometric() async {
    final available = await _biometricService.isBiometricAvailable();
    bool enabled = false;
    if (available && _selectedProfile != null) {
      enabled = await _biometricService
          .isBiometricEnabledForProfile(_selectedProfile!.id);
    }
    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _biometricEnabledForProfile = enabled;
      });
    }
  }

  Future<void> _handleBiometricLogin() async {
    if (_selectedProfile == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authenticated = await _biometricService.authenticate();
      if (!authenticated) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final credentials =
          await _biometricService.getCredentials(_selectedProfile!.id);
      if (credentials == null) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Credenciais biométricas não encontradas. Faça login com senha.';
          _biometricEnabledForProfile = false;
        });
        return;
      }

      final firebaseProvider = context.read<FirebaseProfileProvider>();
      final success = await firebaseProvider.signInWithUsername(
        credentials['username']!,
        credentials['password']!,
      );

      if (success) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // Credenciais inválidas - pode ser que a senha mudou
        await _biometricService.removeCredentials(_selectedProfile!.id);
        setState(() {
          _errorMessage =
              'Credenciais expiradas. Faça login com senha novamente.';
          _biometricEnabledForProfile = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
                    onPressed: (_isLoading) ? null : _handleSubmit,
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

                // Botão de login biométrico
                if (_isLogin &&
                    _biometricAvailable &&
                    _biometricEnabledForProfile &&
                    _selectedProfile != null) ...[
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('ou', style: TextStyle(color: Colors.grey)),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _handleBiometricLogin,
                      icon: const Icon(Icons.fingerprint, size: 28),
                      label: const Text(
                        'Entrar com Biometria',
                        style: TextStyle(fontSize: 16),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green[700],
                        side: BorderSide(color: Colors.green[700]!),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Botão para alternar entre login e criar conta (só mostrar se não recebeu perfil)
                if (_selectedProfile == null) ...[
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
                // Botão "Esqueci minha senha" (apenas no modo login)
                if (_isLogin)
                  TextButton(
                    onPressed: (_isLoading) ? null : _showPasswordResetDialog,
                    child: Text(
                      'Esqueci minha senha',
                      style: TextStyle(
                        color: Colors.orange[700],
                      ),
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
              password: null, // Não armazenar senha localmente por segurança
            );

            await localProfilesProvider.addProfile(newProfile);
          } catch (e) {
            // Não falhar se não conseguir salvar localmente
          }
        }
      }

      if (success) {
        // Oferecer salvar biometria após login com senha
        if (_isLogin &&
            _biometricAvailable &&
            !_biometricEnabledForProfile &&
            _selectedProfile != null) {
          await _offerBiometricSetup();
        }
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

  Future<void> _offerBiometricSetup() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ativar Biometria'),
        content: const Text(
          'Deseja usar biometria (impressão digital / reconhecimento facial) para entrar na próxima vez?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Não'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.fingerprint),
            label: const Text('Ativar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (result == true && _selectedProfile != null) {
      await _biometricService.saveCredentials(
        _selectedProfile!.id,
        _usernameController.text.trim(),
        _passwordController.text,
      );
    }
  }

  // Remover métodos _incrementLoginAttempts, _resetLoginAttempts, _saveLoginAttemptsHive, _loadLoginAttemptsHive, _isAccountLocked, _getRemainingLockoutTime

  Future<void> _showPasswordResetDialog() async {
    final emailController = TextEditingController();
    String? resetMessage;
    Color? resetMessageColor;
    bool isResetting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Recuperar Senha'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Digite o email associado à sua conta para receber um link de recuperação:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'seu@email.com',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Digite um email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return 'Digite um email válido';
                      }
                      return null;
                    },
                  ),
                  if (resetMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: resetMessageColor?.withValues(alpha: 0.1) ??
                            Colors.green[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: resetMessageColor ?? Colors.green),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            resetMessageColor == Colors.red
                                ? Icons.error
                                : Icons.check_circle,
                            color: resetMessageColor ?? Colors.green,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              resetMessage ?? '',
                              style: TextStyle(
                                color: resetMessageColor ?? Colors.green,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed:
                      isResetting ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isResetting
                      ? null
                      : () async {
                          setState(() {
                            isResetting = true;
                            resetMessage = null;
                          });

                          try {
                            final firebaseProvider =
                                context.read<FirebaseProfileProvider>();
                            final emailText = emailController.text;
                            if (emailText.trim().isEmpty) {
                              setState(() {
                                resetMessage = 'Digite um email válido';
                                resetMessageColor = Colors.red;
                              });
                              return;
                            }
                            final success = await firebaseProvider
                                .sendPasswordResetEmail(emailText.trim());

                            if (success) {
                              setState(() {
                                resetMessage =
                                    'Email enviado! Verifique sua caixa de entrada.';
                                resetMessageColor = Colors.green;
                              });

                              // Fechar modal após 2 segundos
                              Future.delayed(const Duration(seconds: 2), () {
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              });
                            } else {
                              setState(() {
                                resetMessage =
                                    'Erro ao enviar email. Verifique o email.';
                                resetMessageColor = Colors.red;
                              });
                            }
                          } catch (e) {
                            setState(() {
                              resetMessage = 'Erro: ${e.toString()}';
                              resetMessageColor = Colors.red;
                            });
                          } finally {
                            setState(() {
                              isResetting = false;
                            });
                          }
                        },
                  child: isResetting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Enviar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
