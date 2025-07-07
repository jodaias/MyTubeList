import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:my_tube_list/utils/confirmation_modal.dart';
import '../providers/profile_provider.dart';
import '../models/profile_model.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  void _selectProfile(BuildContext context, ProfileModel profile,
      ProfileProvider provider) async {
    await provider.selectProfile(profile);
    Navigator.pushNamed(context, '/home');
  }

  void _createProfile(BuildContext context, ProfileProvider provider) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => CreateProfileDialog(),
    );

    if (result != null) {
      final name = result['name']!;
      final password = result['password'] ?? '';
      final question = result['question'] ?? '';
      final answer = result['answer'] ?? '';

      await provider.createProfile(name, password, question, answer);
    }
  }

  Future<void> _login(BuildContext context, ProfileModel profile,
      ProfileProvider profileProvider) async {
    if (profile.password != null && profile.password!.isNotEmpty) {
      final passwordController = TextEditingController();

      final entered = await showDialog<String>(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text('Digite a senha para ${profile.name}'),
                content: TextField(
                  controller: passwordController,
                  autofocus: true,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Senha'),
                  onChanged: (_) => setState(() {}),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: passwordController.text.isNotEmpty &&
                            passwordController.text.trim().length >= 4
                        ? () => Navigator.pop(
                            context, passwordController.text.trim())
                        : null,
                    child: const Text('Entrar'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (entered == null) return;

      if (entered.length < 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('A senha deve ter pelo menos 4 dígitos')),
        );
        return;
      }

      if (entered != profile.password) {
        final answerController = TextEditingController();

        final retry = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Senha incorreta'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Senha incorreta. Esqueceu a senha?'),
                const SizedBox(height: 16),
                Text(
                    'Pergunta secreta: ${profile.securityQuestion ?? "Nenhuma cadastrada."}'),
                if (profile.securityQuestion != null)
                  TextField(
                    controller: answerController,
                    autofocus: true,
                    decoration:
                        const InputDecoration(labelText: 'Resposta secreta'),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              if (profile.securityQuestion != null)
                TextButton(
                  onPressed: () {
                    final answer = answerController.text.trim();
                    final correct = answer.toLowerCase() ==
                        profile.securityAnswer?.toLowerCase();
                    Navigator.pop(context, correct);
                  },
                  child: const Text('Recuperar senha'),
                ),
            ],
          ),
        );

        if (retry == true) {
          final newPasswordController = TextEditingController();

          // Redefinir senha
          final newPass = await showDialog<String>(
            context: context,
            builder: (context) => StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: const Text('Nova senha'),
                  content: TextField(
                    controller: newPasswordController,
                    autofocus: true,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'Nova senha (mínimo 4 dígitos)'),
                    onChanged: (_) => setState(() {}),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: newPasswordController.text.trim().length >= 4
                          ? () => Navigator.pop(
                              context, newPasswordController.text.trim())
                          : null,
                      child: const Text('Salvar'),
                    ),
                  ],
                );
              },
            ),
          );

          if (newPass != null && newPass.isNotEmpty && newPass.length >= 4) {
            await profileProvider.setProfilePassword(profile.id, newPass);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Senha redefinida com sucesso')),
            );
          }
        } else if (profile.securityQuestion != null) {
          // Resposta secreta incorreta, mostrar opções de excluir perfil ou tentar novamente
          final choice = await showDialog<String>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Resposta incorreta'),
              content: const Text(
                  'A resposta secreta está incorreta. O que deseja fazer?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, 'retry'),
                  child: const Text('Tentar novamente'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => Navigator.pop(context, 'delete'),
                  child: const Text('Excluir perfil'),
                ),
              ],
            ),
          );

          if (choice == 'delete') {
            final confirmDelete = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Confirmar exclusão'),
                content: const Text(
                    'Tem certeza que deseja excluir este perfil? Esta ação não poderá ser desfeita.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Excluir'),
                  ),
                ],
              ),
            );

            if (confirmDelete == true) {
              await profileProvider.deleteProfile(profile.id);
              Navigator.pushNamedAndRemoveUntil(
                  context, '/profile', (_) => false);
            }
          } else if (choice == 'retry') {
            return await _login(context, profile, profileProvider);
          }
        }

        return;
      }
    }

    _selectProfile(context, profile, profileProvider);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    final profiles = profileProvider.profiles;
    final selectedProfile = profileProvider.selectedProfile;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Escolha um Perfil',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green[800],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                color: Colors.grey.shade200,
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.9,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: profiles.length,
                  itemBuilder: (context, index) {
                    final profile = profiles[index];
                    final isSelected = profile.id == selectedProfile?.id;

                    return Stack(
                      children: [
                        InkWell(
                          onTap: () async {
                            _login(context, profile, profileProvider);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.green[700]
                                  : Colors.green[400],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.white,
                                  child: Text(
                                    profile.name.substring(0, 1).toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  profile.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () async {
                  final shouldAccessCreate = await showMathConfirmationModal(
                      context, "Acessar Tela: Criar Perfil!", "Navegar");
                  if (shouldAccessCreate) {
                    _createProfile(context, profileProvider);
                  }
                },
                icon: const Icon(
                  Icons.add,
                  color: Colors.white,
                ),
                label: const Text(
                  'Criar Novo Perfil',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class CreateProfileDialog extends StatefulWidget {
  const CreateProfileDialog({Key? key}) : super(key: key);

  @override
  State<CreateProfileDialog> createState() => _CreateProfileDialogState();
}

class _CreateProfileDialogState extends State<CreateProfileDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final isPasswordValid = (_passwordController.text.isNotEmpty &&
        _passwordController.text.trim().length >= 4);

    return AlertDialog(
      title: const Text('Novo Perfil'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nome do Perfil'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Senha (opcional)'),
              onChanged: (_) => setState(() {}),
            ),
            if (_passwordController.text.isNotEmpty && !isPasswordValid)
              const Text(
                'A senha deve ter pelo menos 4 dígitos.',
                style: TextStyle(color: Colors.red),
              ),
            if (_passwordController.text.isEmpty)
              const Text(
                'Senha opcional, mas recomendada para segurança.',
                style: TextStyle(color: Colors.green),
              ),
            if (_passwordController.text.isNotEmpty && isPasswordValid) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _questionController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                    labelText: 'Pergunta secreta (ex: sua cor favorita) *'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _answerController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                    labelText: 'Resposta da pergunta secreta *'),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _nameController.text.isNotEmpty &&
                  _nameController.text.trim().length >= 2 &&
                  (_passwordController.text.isEmpty ||
                      (_passwordController.text.isNotEmpty &&
                          _passwordController.text.length >= 4 &&
                          _answerController.text.isNotEmpty &&
                          _questionController.text.isNotEmpty))
              ? () {
                  Navigator.of(context).pop({
                    'name': _nameController.text.trim(),
                    'password': _passwordController.text.trim(),
                    'question': _questionController.text.trim(),
                    'answer': _answerController.text.trim(),
                  });
                }
              : null,
          child: const Text('Criar'),
        ),
      ],
    );
  }
}
