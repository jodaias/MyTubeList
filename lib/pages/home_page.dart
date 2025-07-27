import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/firebase_profile_provider.dart';
import '../providers/firebase_video_list_provider.dart';
import '../providers/local_profiles_provider.dart';
import '../utils/confirmation_modal.dart';
import '../services/firebase_service.dart';
import '../models/video_list_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Sincronizar automaticamente quando a página for carregada
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncOnLoad();
    });
  }

  Future<void> _syncOnLoad() async {
    try {
      final firebaseVideoListProvider =
          context.read<FirebaseVideoListProvider>();
      await firebaseVideoListProvider
          .syncVideoListsWithFirebase(firebaseVideoListProvider.videoLists);
    } catch (e) {
      // Silently handle sync errors
    }
  }

  void _logout(BuildContext context) async {
    final firebaseProfileProvider = context.read<FirebaseProfileProvider>();
    await firebaseProfileProvider.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/auth', (_) => false);
  }

  Future<void> _handleDeleteProfile(BuildContext context, String profileId,
      FirebaseProfileProvider firebaseProfileProvider) async {
    final canEnter = await showMathConfirmationModal(
        context, "Excluir perfil?", "confirmar");
    if (canEnter) {
      try {
        // Salvar o username antes de deletar do Firebase
        final usernameToDelete =
            firebaseProfileProvider.currentProfile?.username;

        // Deletar do Firebase
        await firebaseProfileProvider.deleteCurrentUser();

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
        Navigator.pushNamedAndRemoveUntil(context, '/auth', (r) => false);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao deletar perfil: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseProfileProvider = context.watch<FirebaseProfileProvider>();
    final firebaseVideoListProvider =
        context.watch<FirebaseVideoListProvider>();

    final selectedProfile = firebaseProfileProvider.currentProfile;

    // Se ainda não tiver perfil selecionado, redirecionar para página de perfis
    if (selectedProfile == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/profiles');
      });
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green[700],
          title: Text(
            'Redirecionando...',
            style: const TextStyle(color: Colors.white),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final lists =
        firebaseVideoListProvider.getListsByProfile(selectedProfile.id);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          onPressed: () => _logout(context),
          icon: const Icon(Icons.logout, color: Colors.white),
        ),
        title: Column(
          children: [
            Text(
              'Minhas Listas',
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              'Perfil: ${selectedProfile.name}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            iconColor: Colors.white,
            onSelected: (value) async {
              if (value == 'create_list') {
                final canEnter = await showMathConfirmationModal(
                    context, "Acesso a modal: criar lista!", "confirmar");
                if (canEnter) {
                  _showCreateListDialog(
                      context, firebaseVideoListProvider, selectedProfile.id);
                }
              } else if (value == 'delete_profile') {
                await _handleDeleteProfile(
                    context, selectedProfile.id, firebaseProfileProvider);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'create_list',
                child: Text('➕ Criar Lista'),
              ),
              const PopupMenuItem(
                value: 'delete_profile',
                child: Text('🗑️ Deletar Perfil'),
              ),
            ],
          ),
        ],
      ),
      body: lists.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.playlist_add,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma lista criada ainda',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crie sua primeira lista de vídeos!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: lists.length,
              itemBuilder: (context, index) {
                final list = lists[index];
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/videos',
                        arguments: {'listId': list.id},
                      );
                    },
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.playlist_play,
                                color: Colors.green[700],
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              Flexible(
                                child: Text(
                                  list.name,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${list.videos.length} vídeos',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: PopupMenuButton(
                            onSelected: (value) {
                              if (value == 'play') {
                                Navigator.pushNamed(context, '/player',
                                    arguments: {
                                      'listId': list.id,
                                      'videos': list.videos,
                                    });
                              } else if (value == 'add') {
                                Navigator.pushNamed(context, '/search',
                                    arguments: list.id);
                              } else if (value == 'rename') {
                                _showRenameListDialog(
                                    context, firebaseVideoListProvider, list);
                              } else if (value == 'duplicate') {
                                _showDuplicateListDialog(
                                    context,
                                    firebaseVideoListProvider,
                                    list,
                                    selectedProfile.id);
                              } else if (value == 'share') {
                                _showShareListDialog(context, list);
                              } else if (value == 'delete') {
                                _showDeleteListDialog(
                                    context, firebaseVideoListProvider, list);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'play',
                                child: Text('Tocar lista'),
                              ),
                              const PopupMenuItem(
                                value: 'add',
                                child: Text('Adicionar vídeos'),
                              ),
                              const PopupMenuItem(
                                value: 'rename',
                                child: Text('Renomear lista'),
                              ),
                              const PopupMenuItem(
                                value: 'duplicate',
                                child: Text('Duplicar lista'),
                              ),
                              const PopupMenuItem(
                                value: 'share',
                                child: Text('Compartilhar'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Excluir lista'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showCreateListDialog(
              context, firebaseVideoListProvider, selectedProfile.id);
        },
        backgroundColor: Colors.green[700],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showCreateListDialog(BuildContext context,
      FirebaseVideoListProvider videoListProvider, String profileId) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Criar Nova Lista'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Nome da lista',
              hintText: 'Ex: Músicas Favoritas',
            ),
            autofocus: true,
            onChanged: (value) => setState(() {}),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: nameController.text.trim().isNotEmpty
                  ? () async {
                      if (nameController.text.trim().isNotEmpty) {
                        await videoListProvider.createVideoList(
                            nameController.text.trim(), profileId);
                        Navigator.pop(context);
                      }
                    }
                  : null,
              child: const Text('Criar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameListDialog(BuildContext context,
      FirebaseVideoListProvider videoListProvider, VideoListModel list) {
    final nameController = TextEditingController(text: list.name);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Renomear Lista'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Novo nome da lista',
              hintText: 'Ex: Músicas Favoritas',
            ),
            autofocus: true,
            onChanged: (value) => setState(() {}),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: nameController.text.trim().isNotEmpty
                  ? () async {
                      if (nameController.text.trim().isNotEmpty) {
                        await videoListProvider.renameVideoList(
                            list.id, nameController.text.trim());
                        Navigator.pop(context);
                      }
                    }
                  : null,
              child: const Text('Renomear'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteListDialog(BuildContext context,
      FirebaseVideoListProvider videoListProvider, VideoListModel list) async {
    final canEnter = await showMathConfirmationModal(context,
        "Excluir esta lista? Ação não poderá ser desfeita.", "excluir");
    if (canEnter) {
      await videoListProvider.deleteVideoList(list.id);
    }
  }

  void _showDuplicateListDialog(
      BuildContext context,
      FirebaseVideoListProvider videoListProvider,
      VideoListModel list,
      String profileId) async {
    final canEnter = await showMathConfirmationModal(
        context, "Acesso a modal: duplicar lista!", "confirmar");
    if (canEnter) {
      final nameController =
          TextEditingController(text: '${list.name} (cópia)');

      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Duplicar Lista'),
            content: TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nome da nova lista',
                hintText: 'Ex: Músicas Favoritas (cópia)',
              ),
              autofocus: true,
              onChanged: (value) => setState(() {}),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: nameController.text.trim().isNotEmpty
                    ? () async {
                        if (nameController.text.trim().isNotEmpty) {
                          // Criar nova lista
                          final success =
                              await videoListProvider.createVideoList(
                                  nameController.text.trim(), profileId);

                          if (success) {
                            // Aguardar um pouco para a lista ser criada
                            await Future.delayed(
                                const Duration(milliseconds: 500));

                            // Encontrar a lista recém-criada
                            final newLists =
                                videoListProvider.getListsByProfile(profileId);
                            final newList = newLists.lastWhere(
                              (list) => list.name == nameController.text.trim(),
                              orElse: () => newLists.last,
                            );

                            // Adicionar todos os vídeos da lista original
                            for (final video in list.videos) {
                              await videoListProvider.addVideoToList(
                                  newList.id, video);
                            }
                          }

                          Navigator.pop(context);
                        }
                      }
                    : null,
                child: const Text('Duplicar'),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _showShareListDialog(BuildContext context, VideoListModel list) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Compartilhar Lista'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lista: ${list.name}'),
            const SizedBox(height: 8),
            Text('Vídeos: ${list.videos.length}'),
            const SizedBox(height: 16),
            const Text(
              'Funcionalidade de compartilhamento será implementada em breve!',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}
