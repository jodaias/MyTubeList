import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../constants/app_constants.dart';
import '../providers/firebase_profile_provider.dart';
import '../providers/firebase_video_list_provider.dart';
import '../utils/confirmation_modal.dart';
import '../models/video_list_model.dart';
import '../models/profile_model.dart';

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
      _reloadVideoLists();
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

  Future<void> _reloadVideoLists() async {
    try {
      final firebaseVideoListProvider =
          context.read<FirebaseVideoListProvider>();

      // Recarregar as listas
      await firebaseVideoListProvider.loadVideoLists();
    } catch (e) {
      // Silently handle reload errors
    }
  }

  void _logout(BuildContext context) async {
    final firebaseProfileProvider = context.read<FirebaseProfileProvider>();
    await firebaseProfileProvider.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/auth', (_) => false);
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldLogout = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Sair do perfil?'),
              content: const Text(
                  'Deseja realmente sair do perfil e voltar para a seleção de perfis?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Sair'),
                ),
              ],
            ),
          );
          if (shouldLogout == true) {
            _logout(context);
          }
        }
      },
      child: Scaffold(
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
                  final canAccess = await showMathConfirmationModal(
                      context, "Acesso a modal: criar lista!", "confirmar",
                      userCategory: selectedProfile.category);
                  if (!canAccess) return;

                  _showCreateListDialog(
                      context, firebaseVideoListProvider, selectedProfile.id);
                } else if (value == 'settings') {
                  final canAccess = await showMathConfirmationModal(
                    context,
                    'Acesso restrito',
                    'Acessar as configurações',
                    userCategory: selectedProfile.category,
                  );
                  if (!canAccess) return;

                  Navigator.pushNamed(context, '/settings');
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'create_list',
                  child: Text('➕ Criar Lista'),
                ),
                const PopupMenuItem(
                  value: 'settings',
                  child: Text('⚙️ Configurações'),
                ),
              ],
            ),
          ],
        ),
        body: firebaseVideoListProvider.isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.green[700]!),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Carregando suas listas...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
            : lists.isEmpty
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
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: AppConstants.gridCrossAxisCount,
                      childAspectRatio: AppConstants.homeGridChildAspectRatio,
                      crossAxisSpacing: AppConstants.gridSpacing,
                      mainAxisSpacing: AppConstants.gridSpacing,
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
                                      size: AppConstants.playlistIconSize,
                                    ),
                                    const SizedBox(height: 12),
                                    Flexible(
                                      child: Text(
                                        list.name,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize:
                                              AppConstants.listNameFontSize,
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
                                      _showRenameListDialog(context,
                                          firebaseVideoListProvider, list);
                                    } else if (value == 'duplicate') {
                                      _showDuplicateListDialog(
                                          context,
                                          firebaseVideoListProvider,
                                          list,
                                          selectedProfile);
                                    } else if (value == 'share') {
                                      _showShareListDialog(context, list);
                                    } else if (value == 'delete') {
                                      _showDeleteListDialog(
                                          context,
                                          firebaseVideoListProvider,
                                          list,
                                          selectedProfile);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'play',
                                      enabled: list.videos.isNotEmpty,
                                      child: Text(
                                        'Tocar lista',
                                        style: TextStyle(
                                          color: list.videos.isNotEmpty
                                              ? null
                                              : Colors.grey,
                                        ),
                                      ),
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
          onPressed: () async {
            final canAccess = await showMathConfirmationModal(
                context, "Acesso a modal: criar lista!", "confirmar",
                userCategory: selectedProfile.category);
            if (!canAccess) return;
            _showCreateListDialog(
                context, firebaseVideoListProvider, selectedProfile.id);
          },
          backgroundColor: Colors.green[700],
          child: const Icon(Icons.add, color: Colors.white),
        ),
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
                        // Mostra loading
                        await showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (dialogContext) {
                            Future.microtask(() async {
                              await videoListProvider.createVideoList(
                                  nameController.text.trim(), profileId);
                              if (Navigator.of(dialogContext,
                                      rootNavigator: true)
                                  .canPop()) {
                                Navigator.of(dialogContext, rootNavigator: true)
                                    .pop();
                              }
                            });
                            return AlertDialog(
                              title: const Text('Criando lista...'),
                              content: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Criando...'),
                                ],
                              ),
                            );
                          },
                        );
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
      barrierDismissible: false,
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

  void _showDeleteListDialog(
      BuildContext context,
      FirebaseVideoListProvider videoListProvider,
      VideoListModel list,
      ProfileModel profile) async {
    // Sempre exibe confirmação simples antes do loading
    final confirm = await showConfirmationDialog(
      context,
      title: 'Excluir lista',
      content:
          'Tem certeza que deseja excluir esta lista? Esta ação não poderá ser desfeita.',
      confirmText: 'Excluir',
      cancelText: 'Cancelar',
    );
    if (confirm) {
      // Se for criança, faz o desafio matemático
      final canDelete = await showMathConfirmationModal(
          context, "Confirmação extra", "excluir",
          userCategory: profile.category);
      if (!canDelete) return;
      // Loading
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          Future.microtask(() async {
            await videoListProvider.deleteVideoList(list.id);
            if (Navigator.of(dialogContext, rootNavigator: true).canPop()) {
              Navigator.of(dialogContext, rootNavigator: true).pop();
            }
          });
          return AlertDialog(
            title: const Text('Excluindo lista...'),
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Excluindo...'),
              ],
            ),
          );
        },
      );
    }
  }

  void _showDuplicateListDialog(
      BuildContext context,
      FirebaseVideoListProvider videoListProvider,
      VideoListModel list,
      ProfileModel profile) async {
    final canAccess = await showMathConfirmationModal(
        context, "Acesso a modal: duplicar lista!", "confirmar",
        userCategory: profile.category);
    if (!canAccess) return;

    final nameController = TextEditingController(text: '${list.name} (cópia)');

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
                        final success = await videoListProvider.createVideoList(
                            nameController.text.trim(), profile.id);

                        if (success) {
                          // Aguardar um pouco para a lista ser criada
                          await Future.delayed(
                              const Duration(milliseconds: 500));

                          // Encontrar a lista recém-criada
                          final newLists =
                              videoListProvider.getListsByProfile(profile.id);
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
              'Você pode compartilhar esta lista com seus amigos!',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          TextButton(
            onPressed: () {
              final videoLinks = list.videos
                  .map((v) =>
                      '${v.title} - https://www.youtube.com/watch?v=${v.id}')
                  .join('\n');
              final shareText =
                  'Confira minha lista "${list.name}":\n$videoLinks';

              final shareParams = ShareParams(
                text: shareText,
                subject: 'Compartilhar Lista de Vídeos',
              );

              SharePlus.instance.share(shareParams);
              Navigator.pop(context);
            },
            child: const Text('Compartilhar'),
          ),
        ],
      ),
    );
  }
}
