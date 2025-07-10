import 'package:flutter/material.dart';
import 'package:my_tube_list/models/video_list_model.dart';
import 'package:my_tube_list/providers/video_provider.dart';
import 'package:my_tube_list/utils/confirmation_modal.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../providers/video_list_provider.dart';

class HomePage extends StatelessWidget {
  void _logout(BuildContext context, ProfileProvider _profileProvider) async {
    await _profileProvider.clearProfile();
    Navigator.pushNamedAndRemoveUntil(context, '/profile', (_) => false);
  }

  Future<void> _handleDeleteProfile(BuildContext context, String profileId,
      ProfileProvider profileProvider) async {
    final canEnter = await showMathConfirmationModal(
        context, "Acesso a modal: excluir perfil!", "confirmar");
    if (canEnter) {
      final confirm = await showConfirmationDialog(
        context,
        title: 'Excluir perfil',
        content:
            'Tem certeza que deseja excluir este perfil? Esta ação não poderá ser desfeita.',
        confirmText: 'Excluir',
        cancelText: 'Cancelar',
      );

      if (confirm) {
        await profileProvider.deleteProfile(profileId);

        Navigator.pushNamedAndRemoveUntil(context, '/profile', (r) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final videoListProvider = context.watch<VideoListProvider>();

    final selectedProfile = profileProvider.selectedProfile;
    final lists = videoListProvider.getListsByProfile(selectedProfile!.id);

    final videoProvider = context.watch<VideoProvider>();
    videoProvider.loadPreviousSearches(selectedProfile.id);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        title: Text(
          'Minhas Listas',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => _logout(context, profileProvider),
          icon: const Icon(
            Icons.logout_outlined,
            color: Colors.white,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.settings,
              color: Colors.white,
            ),
            onSelected: (value) async {
              if (value == 'new_list') {
                final canEnter = await showMathConfirmationModal(
                    context, "Acesso a modal: criar lista!", "confirmar");
                if (canEnter) {
                  _showCreateListDialog(
                      context, videoListProvider, selectedProfile.id);
                }
              } else if (value == 'delete_profile') {
                await _handleDeleteProfile(
                    context, selectedProfile.id, profileProvider);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'new_list',
                child: Text('Criar nova lista'),
              ),
              const PopupMenuItem(
                value: 'delete_profile',
                child: Text('Excluir perfil / conta'),
              ),
            ],
          ),
        ],
      ),
      body: lists.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Nenhuma lista criada.',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      final canEnter = await showMathConfirmationModal(
                          context, "Acesso a modal: criar lista!", "confirmar");
                      if (canEnter) {
                        _showCreateListDialog(
                            context, videoListProvider, selectedProfile.id);
                      }
                    },
                    child: Text('Criar nova lista'),
                  ),
                ],
              ),
            )
          : SafeArea(
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 colunas
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1, // quadrado
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
                        Navigator.pushNamed(context, '/videos', arguments: {
                          'listId': list.id,
                        });
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
                                SizedBox(height: 12),
                                Text(
                                  list.name,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
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
                                } else if (value == 'delete') {
                                  _showDeleteListDialog(
                                      context, videoListProvider, list);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'play',
                                  child: Text('Tocar lista'),
                                ),
                                PopupMenuItem(
                                  value: 'add',
                                  child: Text('Adicionar vídeos'),
                                ),
                                PopupMenuItem(
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
            ),
    );
  }

  void _showDeleteListDialog(BuildContext context,
      VideoListProvider videoListProvider, VideoListModel list) async {
    final canEnter = await showMathConfirmationModal(
        context, "Acesso a modal: excluir lista!", "confirmar");
    if (canEnter) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Excluir lista'),
          content: Text(
              'Tem certeza que deseja excluir esta lista? Esta ação não poderá ser desfeita.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                await videoListProvider.deleteList(list.id);
                Navigator.pop(context);
              },
              child: Text('Excluir'),
            ),
          ],
        ),
      );
    }
  }

  void _showCreateListDialog(
      BuildContext context, VideoListProvider provider, String profileId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Criar nova lista'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: 'Nome da lista'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final listId =
                  await provider.createList(controller.text.trim(), profileId);
              Navigator.pop(context);
              Navigator.pushNamed(context, '/search', arguments: listId);
            },
            child: Text('Criar'),
          ),
        ],
      ),
    );
  }
}
