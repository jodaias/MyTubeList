import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/firebase_profile_provider.dart';
import '../providers/local_profiles_provider.dart';
import '../models/profile_model.dart';

class ProfilesPage extends StatefulWidget {
  const ProfilesPage({Key? key}) : super(key: key);

  @override
  State<ProfilesPage> createState() => _ProfilesPageState();
}

class _ProfilesPageState extends State<ProfilesPage>
    with WidgetsBindingObserver {
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

  void _addNewProfile(BuildContext context) async {
    // Função para adicionar um novo perfil manualmente
    final nameController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    bool isPasswordVisible = false;
    bool isLoading = false;

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Adicionar Novo Perfil'),
          content: Form(
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
                  onChanged: (value) => setState(() {}), // Reagir às mudanças
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
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome de usuário',
                    hintText: 'Ex: joao123',
                  ),
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
                      usernameController.value = TextEditingValue(
                        text: cleanValue,
                        selection:
                            TextSelection.collapsed(offset: cleanValue.length),
                      );
                    }
                    setState(() {}); // Reagir às mudanças
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
                    return null;
                  },
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
                    // Remover espaços e acentos da senha
                    String cleanValue = value
                        .replaceAll(RegExp(r'\s'), '') // Remove espaços
                        .replaceAll(RegExp(r'[áàâãä]'), 'a')
                        .replaceAll(RegExp(r'[éèêë]'), 'e')
                        .replaceAll(RegExp(r'[íìîï]'), 'i')
                        .replaceAll(RegExp(r'[óòôõö]'), 'o')
                        .replaceAll(RegExp(r'[úùûü]'), 'u');

                    if (value != cleanValue) {
                      passwordController.value = TextEditingValue(
                        text: cleanValue,
                        selection:
                            TextSelection.collapsed(offset: cleanValue.length),
                      );
                    }
                    setState(() {}); // Reagir às mudanças
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
                ),
              ],
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

                          // Criar usuário no Firebase Auth
                          final success = await firebaseProfileProvider
                              .createUserWithPassword(
                            usernameController.text.trim(),
                            passwordController.text.trim(),
                            nameController.text.trim(),
                          );

                          if (!success) {
                            throw Exception(
                                'Falha ao criar usuário no Firebase');
                          }

                          // Criar perfil local
                          final profile = ProfileModel(
                            id: usernameController.text.trim(),
                            name: nameController.text.trim(),
                            username: usernameController.text.trim(),
                            password: null,
                          );

                          // Adicionar ao provider local
                          await localProfilesProvider.addProfile(profile);

                          Navigator.pop(context, {'success': true});
                        } catch (e) {
                          setState(() {
                            isLoading = false;
                          });

                          // Mostrar erro no modal
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
      // Recarregar lista de perfis após adicionar
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
                color: Colors.grey.shade200,
                child: localProfilesProvider.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Colors.green,
                        ),
                      )
                    : localProfilesProvider.profiles.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.family_restroom,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Nenhum perfil encontrado',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Clique no botão + para adicionar\num novo perfil',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.9,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: localProfilesProvider.profiles.length,
                            itemBuilder: (context, index) {
                              final profile =
                                  localProfilesProvider.profiles[index];

                              return Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: InkWell(
                                  onTap: () => _selectProfile(context, profile),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.white,
                                          Colors.grey[50]!
                                        ],
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
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
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '@${profile.username}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Clique para acessar',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
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
