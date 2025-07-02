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
    final newProfileName = await showDialog<String>(
      context: context,
      builder: (context) => const CreateProfileDialog(),
    );

    if (newProfileName != null && newProfileName.isNotEmpty) {
      await provider.addProfile(newProfileName);
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    final profileProvider = Provider.of<ProfileProvider>(context);
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
                          onTap: () =>
                              _selectProfile(context, profile, profileProvider),
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
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.white, size: 20),
                              onPressed: () async {
                                final shouldDelete =
                                    await showMathConfirmationModal(
                                        context, "Apagar Perfil", "Apagar");
                                if (shouldDelete) {
                                  await profileProvider
                                      .deleteProfile(profile.id);
                                }
                              },
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
                      context, "Acessar Criar Perfil", "Navegar");
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
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo Perfil'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(hintText: 'Nome do perfil'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(_controller.text.trim());
          },
          child: const Text('Criar'),
        ),
      ],
    );
  }
}
