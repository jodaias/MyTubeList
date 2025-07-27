import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/firebase_video_list_provider.dart';
import '../utils/confirmation_modal.dart';
import '../widgets/video_card.dart';

class VideosPage extends StatefulWidget {
  final String listId;

  const VideosPage({Key? key, required this.listId}) : super(key: key);

  @override
  State<VideosPage> createState() => _VideosPageState();
}

class _VideosPageState extends State<VideosPage> {
  bool _isSelectionMode = false;
  Set<String> _selectedVideos = {};

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
    final confirmed = await showMathConfirmationModal(
        context, "Excluir ${_selectedVideos.length} vídeo(s)?", "Confirmar");
    if (confirmed) {
      final firebaseVideoListProvider =
          context.read<FirebaseVideoListProvider>();
      for (final videoId in _selectedVideos) {
        await firebaseVideoListProvider.removeVideoFromList(
            widget.listId, videoId);
      }
      setState(() {
        _selectedVideos.clear();
        _isSelectionMode = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseVideoListProvider =
        context.watch<FirebaseVideoListProvider>();
    final videoList = firebaseVideoListProvider.getVideoListById(widget.listId);

    if (videoList == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green[700],
          title: const Text('Lista não encontrada'),
        ),
        body: const Center(
          child: Text('Lista não encontrada'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        title: Text(
          videoList.name,
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Botão de seleção
          IconButton(
            icon: Icon(
              _isSelectionMode ? Icons.close : Icons.select_all,
              color: Colors.white,
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
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.video_library,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum vídeo adicionado',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Adicione vídeos à sua lista!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.1,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: videoList.videos.length,
              itemBuilder: (context, index) {
                final video = videoList.videos[index];
                final isSelected = _selectedVideos.contains(video.id);

                return VideoCard(
                  video: video,
                  showPlayButton: !_isSelectionMode,
                  isSelected: _isSelectionMode ? isSelected : null,
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
                          final confirmed = await showMathConfirmationModal(
                              context, "Excluir vídeo?", "Confirmar");
                          if (confirmed) {
                            await firebaseVideoListProvider.removeVideoFromList(
                                widget.listId, video.id);
                            videoList.videos
                                .removeWhere((v) => v.id == video.id);
                          }
                        },
                );
              },
            ),
    );
  }
}
