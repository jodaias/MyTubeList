import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/firebase_video_list_provider.dart';
import '../providers/firebase_profile_provider.dart';
import '../utils/confirmation_modal.dart';
import '../widgets/video_card.dart';
import '../widgets/empty_state_widget.dart';

class VideosPage extends StatefulWidget {
  final String listId;

  const VideosPage({Key? key, required this.listId}) : super(key: key);

  @override
  State<VideosPage> createState() => _VideosPageState();
}

class _VideosPageState extends State<VideosPage> {
  bool _isSelectionMode = false;
  Set<String> _selectedVideos = {};
  Set<String> _deletingVideos = {}; // Para controlar loading de cada vídeo

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedVideos.clear();
      }
    });
  }

  void _toggleVideoSelection(String videoId) {
    setState(() {
      if (_selectedVideos.contains(videoId)) {
        _selectedVideos.remove(videoId);
      } else {
        _selectedVideos.add(videoId);
      }
    });
  }

  Future<void> _deleteSelectedVideos() async {
    final firebaseProfileProvider = context.read<FirebaseProfileProvider>();
    final currentProfile = firebaseProfileProvider.currentProfile;

    // Confirmação simples
    final confirm = await showConfirmationDialog(
      context,
      title: 'Excluir vídeos',
      content:
          'Tem certeza que deseja excluir ${_selectedVideos.length} vídeo(s)? Esta ação não poderá ser desfeita.',
      confirmText: 'Excluir',
      cancelText: 'Cancelar',
    );
    if (!confirm) return;
    // Se for criança, faz o desafio matemático
    final canDelete = await showMathConfirmationModal(
      context,
      "Confirmação extra",
      "excluir",
      userCategory: currentProfile?.category,
    );
    if (!canDelete) return;
    final firebaseVideoListProvider = context.read<FirebaseVideoListProvider>();
    for (final videoId in _selectedVideos) {
      await firebaseVideoListProvider.removeVideoFromList(
          widget.listId, videoId);
    }
    setState(() {
      _selectedVideos.clear();
      _isSelectionMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final firebaseVideoListProvider =
        context.watch<FirebaseVideoListProvider>();
    final videoList = firebaseVideoListProvider.getVideoListById(widget.listId);

    if (videoList == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          title: Text('Lista não encontrada',
              style: TextStyle(
                  color: Theme.of(context).appBarTheme.foregroundColor)),
        ),
        body: Center(
          child: Text('Lista não encontrada',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Text(
          videoList.name,
          style:
              TextStyle(color: Theme.of(context).appBarTheme.foregroundColor),
        ),
        iconTheme:
            IconThemeData(color: Theme.of(context).appBarTheme.foregroundColor),
        actions: [
          // Botão de seleção
          IconButton(
            icon: Icon(
              _isSelectionMode ? Icons.close : Icons.select_all,
              color: Theme.of(context).appBarTheme.foregroundColor,
            ),
            onPressed: _toggleSelectionMode,
            tooltip: _isSelectionMode ? 'Sair da seleção' : 'Modo seleção',
          ),
          // Botão de deletar selecionados
          if (_isSelectionMode && _selectedVideos.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: _deleteSelectedVideos,
              tooltip: 'Deletar selecionados',
            ),
          // Botão de play (só quando não está em modo seleção)
          if (!_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.play_arrow, color: Colors.white),
              tooltip: 'Reproduzir lista',
              onPressed: () {
                if (videoList.videos.isNotEmpty) {
                  Navigator.pushNamed(
                    context,
                    '/player',
                    arguments: {
                      'listId': videoList.id,
                      'videos': videoList.videos,
                      'currentIndex': 0,
                    },
                  );
                }
              },
            ),
          // Botão de adicionar (só quando não está em modo seleção)
          if (!_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              tooltip: 'Adicionar vídeos',
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/search',
                  arguments: videoList.id,
                );
              },
            ),
        ],
      ),
      body: videoList.videos.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.video_library,
              title: 'Nenhum vídeo adicionado',
              subtitle: 'Adicione vídeos à sua lista!',
            )
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: AppConstants.gridCrossAxisCount,
                childAspectRatio: AppConstants.gridChildAspectRatio,
                crossAxisSpacing: AppConstants.gridSpacing,
                mainAxisSpacing: AppConstants.gridSpacing,
              ),
              itemCount: videoList.videos.length,
              itemBuilder: (context, index) {
                final video = videoList.videos[index];
                final isSelected = _selectedVideos.contains(video.id);

                return VideoCard(
                  video: video,
                  showPlayButton: !_isSelectionMode,
                  isSelected: _isSelectionMode ? isSelected : null,
                  isDeleting: _deletingVideos.contains(video.id),
                  onTap: _isSelectionMode
                      ? () => _toggleVideoSelection(video.id)
                      : () {
                          Navigator.pushNamed(
                            context,
                            '/player',
                            arguments: {
                              'listId': videoList.id,
                              'videos': videoList.videos,
                              'currentIndex': index,
                            },
                          );
                        },
                  onDeleteConfirmed: _isSelectionMode
                      ? null
                      : () async {
                          final firebaseProfileProvider =
                              context.read<FirebaseProfileProvider>();
                          final currentProfile =
                              firebaseProfileProvider.currentProfile;

                          // Confirmação simples
                          final confirm = await showConfirmationDialog(
                            context,
                            title: 'Excluir vídeo',
                            content:
                                'Tem certeza que deseja excluir este vídeo? Esta ação não poderá ser desfeita.',
                            confirmText: 'Excluir',
                            cancelText: 'Cancelar',
                          );
                          if (!confirm) return;
                          // Se for criança, faz o desafio matemático
                          final canDelete = await showMathConfirmationModal(
                            context,
                            "Confirmação extra",
                            "excluir",
                            userCategory: currentProfile?.category,
                          );
                          if (!canDelete) return;
                          setState(() {
                            _deletingVideos.add(video.id);
                          });

                          try {
                            await firebaseVideoListProvider.removeVideoFromList(
                                widget.listId, video.id);
                            videoList.videos
                                .removeWhere((v) => v.id == video.id);
                          } finally {
                            setState(() {
                              _deletingVideos.remove(video.id);
                            });
                          }
                        },
                );
              },
            ),
    );
  }
}
