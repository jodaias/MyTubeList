import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/firebase_profile_provider.dart';
import '../providers/local_profiles_provider.dart';
import '../utils/confirmation_modal.dart';
import '../models/profile_model.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  // Mensagens customizadas por bloco
  String? _emailMessage;
  Color? _emailMessageColor;
  String? _passwordMessage;
  Color? _passwordMessageColor;
  String? _resetMessage;
  Color? _resetMessageColor;

  @override
  void initState() {
    super.initState();
    _loadCurrentEmail();
    _reloadEmailStatus();
  }

  Future<void> _reloadEmailStatus() async {
    try {
      final firebaseProvider = context.read<FirebaseProfileProvider>();
      await firebaseProvider.reloadUser();
    } catch (e) {
      // Silently handle reload errors
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentEmail() async {
    final firebaseProvider = context.read<FirebaseProfileProvider>();
    final profile = firebaseProvider.currentProfile;

    if (profile != null) {
      // Usar email real do perfil se disponível, ou fallback para formato antigo
      final email = profile.email ?? '${profile.username}@mytubelist.com';
      _emailController.text = email;
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseProvider = context.read<FirebaseProfileProvider>();
    final profile = firebaseProvider.currentProfile;

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Configurações', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informações do perfil
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person,
                              size: 24, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            'Perfil Atual',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (profile != null) ...[
                        _buildInfoRow('Nome', profile.name),
                        _buildInfoRow('Usuário', profile.username ?? ''),
                        _buildInfoRow('Categoria',
                            profile.category?.displayName ?? 'Adulto'),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Seção de Email
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.email, size: 24, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            'Email para Recuperação',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Este email será usado para recuperar sua senha caso você a esqueça.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 16),
                      // Status de verificação do email
                      Consumer<FirebaseProfileProvider>(
                        builder: (context, provider, child) {
                          final isVerified = provider.isEmailVerified();
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isVerified
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    isVerified ? Colors.green : Colors.orange,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isVerified ? Icons.verified : Icons.warning,
                                  color:
                                      isVerified ? Colors.green : Colors.orange,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    isVerified
                                        ? 'Email verificado'
                                        : 'Email não verificado',
                                    style: TextStyle(
                                      color: isVerified
                                          ? Colors.green
                                          : Colors.orange,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (!isVerified) ...[
                                  TextButton(
                                    onPressed: _isLoading
                                        ? null
                                        : () async {
                                            final success = await provider
                                                .sendEmailVerification();
                                            if (success) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                      'Email de verificação enviado! Verifique sua caixa de entrada.'),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                            } else {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                      'Erro ao enviar email de verificação.'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          },
                                    child: const Text('Verificar'),
                                  ),
                                  TextButton(
                                    onPressed: _isLoading
                                        ? null
                                        : () async {
                                            await provider.reloadUser();
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content:
                                                    Text('Status atualizado!'),
                                                backgroundColor: Colors.blue,
                                              ),
                                            );
                                          },
                                    child: const Text('Atualizar'),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
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
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _updateEmail,
                          icon: const Icon(Icons.save),
                          label: const Text('Atualizar Email'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      buildMessageContainer(
                          _emailMessage,
                          _emailMessageColor ?? Colors.green,
                          _emailMessageColor == Colors.red
                              ? Icons.error
                              : Icons.check_circle),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Seção de Senha
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.lock,
                              size: 24, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text(
                            'Alterar Senha',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Altere sua senha atual por uma nova.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 16),

                      // Senha atual
                      TextFormField(
                        controller: _currentPasswordController,
                        obscureText: _obscureCurrentPassword,
                        decoration: InputDecoration(
                          labelText: 'Senha Atual',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscureCurrentPassword =
                                    !_obscureCurrentPassword;
                              });
                            },
                            icon: Icon(
                              _obscureCurrentPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Nova senha
                      TextFormField(
                        controller: _newPasswordController,
                        obscureText: _obscureNewPassword,
                        decoration: InputDecoration(
                          labelText: 'Nova Senha',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscureNewPassword = !_obscureNewPassword;
                              });
                            },
                            icon: Icon(
                              _obscureNewPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Digite a nova senha';
                          }
                          if (value.length < 6) {
                            return 'A senha deve ter pelo menos 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Confirmar nova senha
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Confirmar Nova Senha',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Confirme a nova senha';
                          }
                          if (value != _newPasswordController.text) {
                            return 'As senhas não coincidem';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _changePassword,
                          icon: const Icon(Icons.lock_reset),
                          label: const Text('Alterar Senha'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      buildMessageContainer(
                          _passwordMessage,
                          _passwordMessageColor ?? Colors.green,
                          _passwordMessageColor == Colors.red
                              ? Icons.error
                              : Icons.check_circle),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Seção de Recuperação
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.help, size: 24, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(
                            'Recuperar Senha',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Esqueceu sua senha? Enviaremos um link de recuperação para seu email.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _sendPasswordReset,
                          icon: const Icon(Icons.email_outlined),
                          label: const Text('Enviar Email de Recuperação'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      buildMessageContainer(
                          _resetMessage,
                          _resetMessageColor ?? Colors.green,
                          _resetMessageColor == Colors.red
                              ? Icons.error
                              : Icons.check_circle),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Seção de Deletar Perfil
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.delete_forever,
                              size: 24, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(
                            'Deletar Perfil',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Esta ação é irreversível. Todos os dados do perfil serão perdidos permanentemente.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _handleDeleteProfile,
                          icon: const Icon(Icons.delete_forever),
                          label: const Text('Deletar Perfil'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget buildMessageContainer(String? message, Color color, IconData icon) {
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateEmail() async {
    if (_emailController.text.isEmpty) {
      setState(() {
        _emailMessage = 'Digite um email válido';
        _emailMessageColor = Colors.red;
      });
      Future.delayed(const Duration(seconds: 7), () {
        if (mounted) setState(() => _emailMessage = null);
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _emailMessage = null;
    });

    try {
      final firebaseProvider = context.read<FirebaseProfileProvider>();
      final success =
          await firebaseProvider.updateEmail(_emailController.text.trim());

      if (success) {
        setState(() {
          _emailMessage =
              'Email atualizado! Verifique sua caixa de entrada para confirmar a mudança.';
          _emailMessageColor = Colors.green;
        });
      } else {
        setState(() {
          _emailMessage =
              'Erro ao atualizar email. Verifique se o email é válido.';
          _emailMessageColor = Colors.red;
        });
      }
    } catch (e) {
      setState(() {
        _emailMessage = 'Erro: ${e.toString()}';
        _emailMessageColor = Colors.red;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      if (_emailMessage != null) {
        Future.delayed(const Duration(seconds: 7), () {
          if (mounted) setState(() => _emailMessage = null);
        });
      }
    }
  }

  Future<void> _changePassword() async {
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      setState(() {
        _passwordMessage = 'Preencha todos os campos';
        _passwordMessageColor = Colors.red;
      });
      Future.delayed(const Duration(seconds: 7), () {
        if (mounted) setState(() => _passwordMessage = null);
      });
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _passwordMessage = 'As senhas não coincidem';
        _passwordMessageColor = Colors.red;
      });
      Future.delayed(const Duration(seconds: 7), () {
        if (mounted) setState(() => _passwordMessage = null);
      });
      return;
    }

    if (_newPasswordController.text.length < 6) {
      setState(() {
        _passwordMessage = 'A nova senha deve ter pelo menos 6 caracteres';
        _passwordMessageColor = Colors.red;
      });
      Future.delayed(const Duration(seconds: 7), () {
        if (mounted) setState(() => _passwordMessage = null);
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _passwordMessage = null;
    });

    try {
      final firebaseProvider = context.read<FirebaseProfileProvider>();
      final success = await firebaseProvider.changePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );

      if (success) {
        setState(() {
          _passwordMessage = 'Senha alterada com sucesso!';
          _passwordMessageColor = Colors.green;
        });

        // Limpar campos
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      } else {
        setState(() {
          _passwordMessage =
              'Erro ao alterar senha. Verifique sua senha atual.';
          _passwordMessageColor = Colors.red;
        });
      }
    } catch (e) {
      setState(() {
        _passwordMessage = 'Erro: ${e.toString()}';
        _passwordMessageColor = Colors.red;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      if (_passwordMessage != null) {
        Future.delayed(const Duration(seconds: 7), () {
          if (mounted) setState(() => _passwordMessage = null);
        });
      }
    }
  }

  Future<void> _sendPasswordReset() async {
    if (_emailController.text.isEmpty) {
      setState(() {
        _resetMessage = 'Digite um email válido';
        _resetMessageColor = Colors.red;
      });
      Future.delayed(const Duration(seconds: 7), () {
        if (mounted) setState(() => _resetMessage = null);
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _resetMessage = null;
    });

    try {
      final firebaseProvider = context.read<FirebaseProfileProvider>();
      final success = await firebaseProvider
          .sendPasswordResetEmail(_emailController.text.trim());

      if (success) {
        setState(() {
          _resetMessage =
              'Email de recuperação enviado! Verifique sua caixa de entrada.';
          _resetMessageColor = Colors.green;
        });
      } else {
        setState(() {
          _resetMessage =
              'Erro ao enviar email de recuperação. Verifique o email.';
          _resetMessageColor = Colors.red;
        });
      }
    } catch (e) {
      setState(() {
        _resetMessage = 'Erro: ${e.toString()}';
        _resetMessageColor = Colors.red;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      if (_resetMessage != null) {
        Future.delayed(const Duration(seconds: 7), () {
          if (mounted) setState(() => _resetMessage = null);
        });
      }
    }
  }

  Future<void> _handleDeleteProfile() async {
    final firebaseProvider = context.read<FirebaseProfileProvider>();
    final profile = firebaseProvider.currentProfile;

    if (profile == null) {
      // Mensagem de erro pode ser exibida em um SnackBar ou similar, mas não global
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil não encontrado')),
      );
      return;
    }

    // Sempre exibe confirmação simples antes do desafio
    final confirm = await showConfirmationDialog(
      context,
      title: 'Excluir perfil',
      content:
          'Tem certeza que deseja excluir este perfil? Esta ação não poderá ser desfeita.',
      confirmText: 'Excluir',
      cancelText: 'Cancelar',
    );
    if (!confirm) return;

    // Se for criança, faz o desafio matemático
    final canAccess = await showMathConfirmationModal(
        context, "Confirmação extra", "excluir",
        userCategory: profile.category);
    if (!canAccess) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Salvar o username antes de deletar do Firebase
      final usernameToDelete = firebaseProvider.currentProfile?.username;

      // Deletar do Firebase
      await firebaseProvider.deleteCurrentUser();

      // Deletar do Hive (armazenamento local)
      final localProfilesProvider = context.read<LocalProfilesProvider>();

      if (usernameToDelete != null) {
        final localProfile =
            localProfilesProvider.getProfileByUsername(usernameToDelete);

        if (localProfile != null) {
          await localProfilesProvider.removeProfile(localProfile.id);
        } else {
          // Fallback: tentar deletar pelo username
          await localProfilesProvider.removeProfile(usernameToDelete);
        }
      }

      // Recarregar lista de perfis locais
      await localProfilesProvider.loadProfiles();

      // Redirecionar para página de auth
      Navigator.pushNamedAndRemoveUntil(context, '/profiles', (r) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao deletar perfil: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
