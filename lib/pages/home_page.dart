import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/confirmation_modal.dart';
import '../providers/profile_provider.dart';
import '../providers/video_provider.dart';
import '../widgets/video_card.dart';
import '../models/video_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  void _logout(BuildContext context, ProfileProvider _profileProvider) async {
    await _profileProvider.clearProfile();
    Navigator.pushNamedAndRemoveUntil(context, '/profile', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final videoProvider = context.watch<VideoProvider>();
    final profileProvider = context.watch<ProfileProvider>();

    final selectedProfile = profileProvider.selectedProfile;

    if (selectedProfile == null) {
      return const Scaffold(
        body: Center(child: Text("Nenhum perfil selecionado.")),
      );
    }

    final allowedVideoIds = selectedProfile.allowedVideoIds;
    final videos = videoProvider.getCachedVideosByIds(allowedVideoIds);
    videoProvider.loadPreviousSearches(selectedProfile.id);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        leading: IconButton(
          onPressed: () => _logout(context, profileProvider),
          icon: const Icon(
            Icons.logout_outlined,
            color: Colors.white,
          ),
        ),
        title: Text(
          'Vídeos de ${selectedProfile.name}',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.settings,
              color: Colors.white,
            ),
            onSelected: (value) async {
              if (value == 'add_video') {
                await _handleAddVideo(context);
              } else if (value == 'delete_profile') {
                await _handleDeleteProfile(
                    context, selectedProfile.id, profileProvider);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'add_video',
                child: Text('Adicionar novo vídeo'),
              ),
              const PopupMenuItem(
                value: 'delete_profile',
                child: Text('Excluir perfil / conta'),
              ),
            ],
          ),
        ],
      ),
      body: videos.isEmpty
          ? const Center(
              child: Text(
                'Nenhum vídeo adicionado.',
                style: TextStyle(fontSize: 18),
              ),
            )
          : SafeArea(
              child: GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  childAspectRatio: 4 / 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: videos.length,
                itemBuilder: (_, index) {
                  VideoModel video = videos[index];
                  return VideoCard(
                    video: video,
                    onTap: () {
                      Navigator.pushNamed(context, '/player', arguments: video);
                    },
                    onDeleteConfirmed: () async {
                      final confirmed = await showMathConfirmationModal(
                          context, "Deseja mesmo remover?", "Remover");
                      if (confirmed) {
                        await profileProvider.removeAllowedVideo(video.id);
                        await videoProvider.removeVideoFromCache(video.id);
                      }
                    },
                  );
                },
              ),
            ),
    );
  }

  Future<void> _handleAddVideo(BuildContext context) async {
    final canEnter = await showMathConfirmationModal(
        context, "Acessar Tela: adicionar novos vídeos!", "confirmar");
    if (canEnter) {
      Navigator.pushNamed(context, '/search');
    }
  }

  Future<void> _handleDeleteProfile(BuildContext context, String profileId,
      ProfileProvider profileProvider) async {
    final canEnter = await showMathConfirmationModal(
        context, "Acesso a modal: excluir perfil!", "cofirmar");
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
}
