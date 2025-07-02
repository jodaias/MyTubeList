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
  void _logout(BuildContext context, ProfileProvider profileProvider) async {
    await profileProvider.clearProfile();
    Navigator.pushNamedAndRemoveUntil(context, '/profile', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final videoProvider = Provider.of<VideoProvider>(context);

    final selectedProfile = profileProvider.selectedProfile;

    if (selectedProfile == null) {
      return const Scaffold(
        body: Center(
          child: Text("Nenhum perfil selecionado."),
        ),
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
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline_outlined,
              color: Colors.white,
            ),
            onPressed: () async {
              final canEnter = await showMathConfirmationModal(
                  context, "Tela de adicionar novos vídeos", "Navegar");
              if (canEnter) {
                Navigator.pushNamed(context, '/search');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Desafio incorreto. Acesso negado!')),
                );
              }
            },
          )
        ],
      ),
      body: videos.isEmpty
          ? const Center(
              child: Text(
                'Nenhum vídeo adicionado.',
                style: TextStyle(fontSize: 18),
              ),
            )
          : GridView.builder(
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
                        context, "Confirmar remoção", "Remover");
                    if (confirmed) {
                      await profileProvider.removeAllowedVideo(video.id);
                      videoProvider.removeVideoFromCache(video.id);
                    }
                  },
                );
              },
            ),
    );
  }
}
