import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/firebase_profile_provider.dart';
import '../providers/local_profiles_provider.dart';
import '../models/profile_model.dart';
import '../utils/confirmation_modal.dart';

class ProfilesPage extends StatefulWidget {
  const ProfilesPage({Key? key}) : super(key: key);

  @override
  State<ProfilesPage> createState() => _ProfilesPageState();
}

class _ProfilesPageState extends State<ProfilesPage>
    with WidgetsBindingObserver {
  bool _isCheckingFirebaseProfiles = false;
  List<ProfileModel> _firebaseProfiles = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Recarregar lista de perfis quando a página é carregada
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final localProfilesProvider = context.read<LocalProfilesProvider>();
      localProfilesProvider.loadProfiles();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Recarregar lista quando o app volta ao foco
      final localProfilesProvider = context.read<LocalProfilesProvider>();
      localProfilesProvider.loadProfiles();
    }
  }

  void _selectProfile(BuildContext context, ProfileModel profile) async {
    // Redirecionar para login com username preenchido
    Navigator.pushNamed(context, '/auth', arguments: {
      'profile': profile,
      'usernameReadOnly': true, // Indica que username não pode ser editado
    });
  }

  Future<void> _checkFirebaseProfiles() async {
    if (_isCheckingFirebaseProfiles) return;

    setState(() {
      _isCheckingFirebaseProfiles = true;
    });

    try {
      // Em vez de buscar todos os perfis, mostrar modal de login
      _showLoginModal(context);
    } catch (e) {
      // Silently handle errors
      _isCheckingFirebaseProfiles = false;
    } finally {
      setState(() {
        _isCheckingFirebaseProfiles = false;
      });
    }
  }

  void _showLoginModal(BuildContext context) {
    final pageContext = context;
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    bool isPasswordVisible = false;
    bool isLoading = false;

    showDialog(
      context: pageContext,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Adicionar Perfil Existente'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Digite suas credenciais para adicionar seu perfil:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'Nome de usuário',
                  hintText: 'Ex: joao123',
                ),
                enabled: !isLoading, // Desabilitar durante loading
                autofocus: true,
                onChanged: (value) {
                  // Remover espaços, acentos e converter para minúsculo
                  String cleanValue = value
                      .toLowerCase()
                      .replaceAll(RegExp(r'\s'), '')
                      .replaceAll(RegExp(r'[áàâãä]'), 'a')
                      .replaceAll(RegExp(r'[éèêë]'), 'e')
                      .replaceAll(RegExp(r'[íìîï]'), 'i')
                      .replaceAll(RegExp(r'[óòôõö]'), 'o')
                      .replaceAll(RegExp(r'[úùûü]'), 'u')
                      .replaceAll(RegExp(r'[çÇ]'), 'c')
                      .replaceAll(RegExp(r'[^a-z0-9_]'), '');

                  if (value != cleanValue) {
                    usernameController.value = TextEditingValue(
                      text: cleanValue,
                      selection:
                          TextSelection.collapsed(offset: cleanValue.length),
                    );
                  }
                  setState(() {}); // Reagir às mudanças
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  hintText: 'Digite sua senha',
                  suffixIcon: IconButton(
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.grey[600],
                    ),
                    onPressed: isLoading
                        ? null
                        : () {
                            setState(() {
                              isPasswordVisible = !isPasswordVisible;
                            });
                          },
                  ),
                ),
                obscureText: !isPasswordVisible,
                enabled: !isLoading, // Desabilitar durante loading
                onChanged: (value) {
                  setState(() {}); // Reagir às mudanças
                },
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          Navigator.pop(dialogContext);
                          _showPasswordResetDialog();
                        },
                  child: Text(
                    'Esqueci minha senha',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: (usernameController.text.isNotEmpty &&
                      usernameController.text.length >= 3 &&
                      usernameController.text.length <= 20 &&
                      passwordController.text.isNotEmpty &&
                      passwordController.text.length >= 6 &&
                      passwordController.text.length <= 25 &&
                      !isLoading)
                  ? () async {
                      setState(() {
                        isLoading = true;
                      });

                      try {
                        final firebaseProfileProvider =
                            context.read<FirebaseProfileProvider>();
                        final localProfilesProvider =
                            context.read<LocalProfilesProvider>();

                        // Tentar fazer login
                        final success =
                            await firebaseProfileProvider.signInWithUsername(
                          usernameController.text.trim(),
                          passwordController.text.trim(),
                        );

                        if (success) {
                          // Buscar perfil do Firebase
                          final profile = await firebaseProfileProvider
                              .getProfileByUsername(
                            usernameController.text.trim(),
                          );

                          if (profile != null) {
                            // Adicionar ao provider local
                            await localProfilesProvider.addProfile(profile);

                            // Só fechar o modal após tudo estar pronto
                            Navigator.pop(dialogContext);

                            if (!mounted) return;

                            // Redirecionar direto para o dashboard
                            Navigator.pushNamedAndRemoveUntil(
                              pageContext,
                              '/home',
                              (_) => false,
                            );
                          } else {
                            throw Exception('Perfil não encontrado');
                          }
                        } else {
                          throw Exception('Credenciais inválidas');
                        }
                      } catch (e) {
                        setState(() {
                          isLoading = false;
                        });

                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Text('Erro: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  : null,
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
  }

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
                                this.context.read<FirebaseProfileProvider>();
                            final emailText = emailController.text;
                            if (emailText.trim().isEmpty ||
                                !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                    .hasMatch(emailText.trim())) {
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

  void _loginWithExistingProfile(ProfileModel profile) async {
    Navigator.pushNamed(context, '/auth', arguments: {
      'profile': profile,
      'usernameReadOnly': true,
    });
  }

  void _addExistingProfile(ProfileModel profile) async {
    final localProfilesProvider = context.read<LocalProfilesProvider>();
    await localProfilesProvider.addProfile(profile);
    setState(() {});
  }

  void _addNewProfile(BuildContext context) async {
    final nameController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    UserCategory? selectedCategory = UserCategory.adult; // Categoria padrão
    bool isPasswordVisible = false;
    bool isLoading = false;
    bool isCheckingUsername = false;
    String? usernameError;
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Map<String, dynamic>>(
      barrierDismissible: false,
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Adicionar Novo Perfil'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome do perfil',
                      hintText: 'Ex: João',
                    ),
                    autofocus: true,
                    onChanged: (value) {
                      // Permitir apenas letras, espaços e apóstrofos
                      String cleanValue = value
                          .replaceAll(RegExp(r'[0-9]'), '')
                          .replaceAll(RegExp(r"[^\p{L}\s']", unicode: true), '')
                          .replaceAll(RegExp(r'\s+'), ' ')
                          .trim();
                      if (value != cleanValue) {
                        nameController.value = TextEditingValue(
                          text: cleanValue,
                          selection: TextSelection.collapsed(
                              offset: cleanValue.length),
                        );
                      }
                      setState(() {});
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Digite um nome para o perfil';
                      }
                      if (value.length < 2) {
                        return 'O nome deve ter pelo menos 2 caracteres';
                      }
                      if (value.length > 30) {
                        return 'O nome deve ter no máximo 30 caracteres';
                      }
                      return null;
                    },
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: usernameController,
                    decoration: InputDecoration(
                      labelText: 'Nome de usuário',
                      hintText: 'Ex: joao123',
                      suffixIcon: isCheckingUsername
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : null,
                    ),
                    onChanged: (value) async {
                      String cleanValue = value
                          .toLowerCase()
                          .replaceAll(RegExp(r'\s'), '')
                          .replaceAll(RegExp(r'[áàâãä]'), 'a')
                          .replaceAll(RegExp(r'[éèêë]'), 'e')
                          .replaceAll(RegExp(r'[íìîï]'), 'i')
                          .replaceAll(RegExp(r'[óòôõö]'), 'o')
                          .replaceAll(RegExp(r'[úùûü]'), 'u')
                          .replaceAll(RegExp(r'[çÇ]'), 'c')
                          .replaceAll(RegExp(r'[^a-z0-9_]'), '');
                      if (value != cleanValue) {
                        usernameController.value = TextEditingValue(
                          text: cleanValue,
                          selection: TextSelection.collapsed(
                              offset: cleanValue.length),
                        );
                      }
                      if (cleanValue.length >= 4) {
                        setState(() {
                          isCheckingUsername = true;
                          usernameError = null;
                        });
                        try {
                          final firebaseProfileProvider =
                              context.read<FirebaseProfileProvider>();
                          final exists = await firebaseProfileProvider
                              .checkUsernameExists(cleanValue);
                          setState(() {
                            isCheckingUsername = false;
                            if (exists) {
                              usernameError = 'Nome de usuário já está em uso';
                            } else {
                              usernameError = null;
                            }
                          });
                        } catch (e) {
                          setState(() {
                            isCheckingUsername = false;
                          });
                        }
                      } else {
                        setState(() {
                          isCheckingUsername = false;
                          usernameError = null;
                        });
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Digite um nome de usuário';
                      }
                      if (value.length < 3) {
                        return 'O nome de usuário deve ter pelo menos 3 caracteres';
                      }
                      if (value.length > 20) {
                        return 'O nome de usuário deve ter no máximo 20 caracteres';
                      }
                      if (usernameError != null) {
                        return usernameError;
                      }
                      return null;
                    },
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      hintText: 'Ex: 123456',
                      suffixIcon: IconButton(
                        icon: Icon(
                          isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.grey[600],
                        ),
                        onPressed: () {
                          setState(() {
                            isPasswordVisible = !isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    obscureText: !isPasswordVisible,
                    onChanged: (value) {
                      String cleanValue = value
                          .replaceAll(RegExp(r'\s'), '')
                          .replaceAll(RegExp(r'[áàâãä]'), 'a')
                          .replaceAll(RegExp(r'[éèêë]'), 'e')
                          .replaceAll(RegExp(r'[íìîï]'), 'i')
                          .replaceAll(RegExp(r'[óòôõö]'), 'o')
                          .replaceAll(RegExp(r'[úùûü]'), 'u');
                      if (value != cleanValue) {
                        passwordController.value = TextEditingValue(
                          text: cleanValue,
                          selection: TextSelection.collapsed(
                              offset: cleanValue.length),
                        );
                      }
                      setState(() {});
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Digite uma senha';
                      }
                      if (value.length < 6) {
                        return 'A senha deve ter pelo menos 6 caracteres';
                      }
                      if (value.length > 25) {
                        return 'A senha deve ter no máximo 25 caracteres';
                      }
                      return null;
                    },
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<UserCategory>(
                    decoration: const InputDecoration(
                      labelText: 'Categoria',
                      hintText: 'Selecione a categoria do perfil',
                    ),
                    initialValue: selectedCategory,
                    items: UserCategory.values
                        .map((category) => DropdownMenuItem(
                              value: category,
                              child: Text(category.displayName),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedCategory = value;
                        });
                      }
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Selecione uma categoria';
                      }
                      return null;
                    },
                    autovalidateMode: AutovalidateMode.disabled,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: (nameController.text.isNotEmpty &&
                      usernameController.text.isNotEmpty &&
                      passwordController.text.isNotEmpty &&
                      nameController.text.length >= 2 &&
                      nameController.text.length <= 30 &&
                      usernameController.text.length >= 3 &&
                      usernameController.text.length <= 20 &&
                      passwordController.text.length >= 6 &&
                      passwordController.text.length <= 25 &&
                      selectedCategory != null &&
                      usernameError == null &&
                      !isLoading)
                  ? () async {
                      if (formKey.currentState!.validate()) {
                        setState(() {
                          isLoading = true;
                        });
                        try {
                          final firebaseProfileProvider =
                              context.read<FirebaseProfileProvider>();
                          final localProfilesProvider =
                              context.read<LocalProfilesProvider>();
                          final success = await firebaseProfileProvider
                              .createUserWithPassword(
                            usernameController.text.trim(),
                            passwordController.text.trim(),
                            nameController.text.trim(),
                            category: selectedCategory,
                          );
                          if (!success) {
                            throw Exception(
                                'Falha ao criar usuário no Firebase');
                          }
                          final profile = ProfileModel(
                            id: usernameController.text.trim(),
                            name: nameController.text.trim(),
                            username: usernameController.text.trim(),
                            password: null,
                            category: selectedCategory,
                          );
                          await localProfilesProvider.addProfile(profile);
                          Navigator.pop(context, {'success': true});
                        } catch (e) {
                          setState(() {
                            isLoading = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Erro ao adicionar perfil: $e')),
                          );
                        }
                      }
                    }
                  : null,
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );

    if (result != null && result['success'] == true) {
      final localProfilesProvider = context.read<LocalProfilesProvider>();
      await localProfilesProvider.loadProfiles();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil adicionado com sucesso!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localProfilesProvider = context.watch<LocalProfilesProvider>();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Escolha um Perfil',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green[800],
        actions: [
          // Botão para adicionar perfil existente do Firebase
          IconButton(
            onPressed:
                _isCheckingFirebaseProfiles ? null : _checkFirebaseProfiles,
            icon: _isCheckingFirebaseProfiles
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(Icons.person_search, color: Colors.white),
            tooltip: 'Adicionar perfil existente',
          ),
          // Botão para adicionar novo perfil
          IconButton(
            onPressed: () => _addNewProfile(context),
            icon: const Icon(
              Icons.person_add,
              color: Colors.white,
            ),
            tooltip: 'Adicionar novo perfil',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: localProfilesProvider.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Colors.green,
                        ),
                      )
                    : localProfilesProvider.profiles.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.family_restroom,
                                  size: 64,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withAlpha((0.7 * 255).toInt()),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Nenhum perfil local encontrado',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withAlpha((0.7 * 255).toInt()),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Você pode criar um novo perfil ou\nverificar perfis existentes no Firebase',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withAlpha((0.6 * 255).toInt()),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: _isCheckingFirebaseProfiles
                                          ? null
                                          : _checkFirebaseProfiles,
                                      icon: _isCheckingFirebaseProfiles
                                          ? SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                            Color>(
                                                        Theme.of(context)
                                                            .colorScheme
                                                            .onPrimary),
                                              ),
                                            )
                                          : Icon(Icons.search,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary),
                                      label: Text(_isCheckingFirebaseProfiles
                                          ? 'Verificando...'
                                          : 'Verificar Firebase'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        foregroundColor: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () => _addNewProfile(context),
                                      icon: Icon(Icons.person_add,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary),
                                      label: Text('Novo Perfil'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                        foregroundColor: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                if (_firebaseProfiles.isNotEmpty) ...[
                                  SizedBox(height: 24),
                                  Text(
                                    'Perfis encontrados no Firebase:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.8),
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  ...(_firebaseProfiles
                                      .map((profile) => Card(
                                            margin: EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 4),
                                            child: ListTile(
                                              leading: Icon(Icons.person,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary),
                                              title: Text(profile.name),
                                              subtitle:
                                                  Text('@${profile.username}'),
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: Icon(Icons.login,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .primary),
                                                    onPressed: () =>
                                                        _loginWithExistingProfile(
                                                            profile),
                                                    tooltip: 'Fazer login',
                                                  ),
                                                  IconButton(
                                                    icon: Icon(Icons.add,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .secondary),
                                                    onPressed: () =>
                                                        _addExistingProfile(
                                                            profile),
                                                    tooltip:
                                                        'Adicionar localmente',
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ))
                                      .toList()),
                                ],
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              // Seção de perfis locais
                              Expanded(
                                child: GridView.builder(
                                  padding: const EdgeInsets.all(16),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.9,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                                  itemCount:
                                      localProfilesProvider.profiles.length,
                                  itemBuilder: (context, index) {
                                    final profile =
                                        localProfilesProvider.profiles[index];

                                    return Card(
                                      elevation: 4,
                                      color: Theme.of(context).cardColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Stack(
                                        children: [
                                          InkWell(
                                            onTap: () => _selectProfile(
                                                context, profile),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(16),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.person,
                                                      size: 48,
                                                      color: Colors.green[700],
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Text(
                                                      profile.name,
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurface,
                                                      ),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      '@${profile.username}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurface
                                                            .withAlpha(
                                                                (0.7 * 255)
                                                                    .toInt()),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      'Clique para acessar',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurface
                                                            .withAlpha(
                                                                (0.7 * 255)
                                                                    .toInt()),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Botão de menu para cada perfil
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: PopupMenuButton<String>(
                                              icon: Icon(
                                                Icons.more_vert,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withAlpha(
                                                        (0.7 * 255).toInt()),
                                                size: 20,
                                              ),
                                              onSelected: (value) async {
                                                if (value == 'remove_local') {
                                                  final confirm =
                                                      await showConfirmationDialog(
                                                    context,
                                                    title:
                                                        'Remover perfil local',
                                                    content:
                                                        'Tem certeza que deseja remover este perfil apenas deste dispositivo?',
                                                    confirmText: 'Remover',
                                                    cancelText: 'Cancelar',
                                                  );
                                                  if (!confirm) return;

                                                  final canRemove =
                                                      await showMathConfirmationModal(
                                                    context,
                                                    'Confirmação extra',
                                                    'Remover',
                                                    userCategory:
                                                        profile.category,
                                                  );
                                                  if (canRemove) {
                                                    await localProfilesProvider
                                                        .removeProfile(
                                                            profile.id);
                                                    setState(() {});
                                                  }
                                                }
                                              },
                                              itemBuilder: (context) => [
                                                const PopupMenuItem(
                                                  value: 'remove_local',
                                                  child:
                                                      Text('🗑️ Remover local'),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addNewProfile(context),
        backgroundColor: Colors.green[700],
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }
}
