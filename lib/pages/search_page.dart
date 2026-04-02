import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../constants/app_constants.dart';
import '../models/video_model.dart';
import '../providers/firebase_profile_provider.dart';
import '../providers/firebase_video_list_provider.dart';
import '../providers/firebase_video_provider.dart';
import '../utils/confirmation_modal.dart';
import '../widgets/video_card.dart';
import '../widgets/empty_state_widget.dart';

class SearchPage extends StatefulWidget {
  final String listId;

  const SearchPage({Key? key, required this.listId}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<VideoModel> _searchResults = [];
  Set<String> _selectedVideos = {}; // IDs dos vídeos selecionados
  Set<String> _autoSelectedVideos =
      {}; // IDs dos vídeos selecionados automaticamente
  bool _isLoading = false;
  bool _hasSearched = false;
  bool _hasValidated = false; // Nova variável para controlar validação
  bool _isSaving = false; // Novo estado para loading dos botões
  YoutubePlayerController? _previewController;
  String? _previewVideoTitle;
  String? _previewVideoId;

  @override
  void initState() {
    super.initState();
    _loadPreviousSearches();
  }

  Future<void> _loadPreviousSearches() async {
    final firebaseVideoProvider = context.read<FirebaseVideoProvider>();
    final firebaseProfileProvider = context.read<FirebaseProfileProvider>();

    if (firebaseProfileProvider.currentProfile != null) {
      await firebaseVideoProvider.loadPreviousSearches(
        firebaseProfileProvider.currentProfile!.id,
        widget.listId,
      );
    }
  }

  Future<void> _searchVideos(String query) async {
    if (query.trim().isEmpty) return;

    // Validação matemática apenas uma vez
    if (!_hasValidated) {
      final firebaseProfileProvider = context.read<FirebaseProfileProvider>();

      final canAccess = await showMathConfirmationModal(
          context, "Acesso a modal: buscar vídeos!", "confirmar",
          userCategory: firebaseProfileProvider.currentProfile?.category);
      if (!canAccess) return;
      _hasValidated = true;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _selectedVideos.clear(); // Limpar seleções ao fazer nova busca
      _autoSelectedVideos.clear(); // Limpar seleções automáticas
    });

    try {
      final firebaseVideoProvider = context.read<FirebaseVideoProvider>();
      final firebaseProfileProvider = context.read<FirebaseProfileProvider>();
      final firebaseVideoListProvider =
          context.read<FirebaseVideoListProvider>();

      final results = await firebaseVideoProvider.search(query);

      if (firebaseProfileProvider.currentProfile != null) {
        await firebaseVideoProvider.addSearchTerm(
          query,
          firebaseProfileProvider.currentProfile!.id,
          widget.listId,
        );
      }

      // Verificar quais vídeos já estão na lista e selecioná-los automaticamente
      final videoList =
          firebaseVideoListProvider.getVideoListById(widget.listId);
      final existingVideoIds = videoList?.videos.map((v) => v.id).toSet() ?? {};

      setState(() {
        _searchResults = results;
        _isLoading = false;
        // Selecionar automaticamente vídeos que já estão na lista
        _autoSelectedVideos = results
            .where((video) => existingVideoIds.contains(video.id))
            .map((video) => video.id)
            .toSet();
        _selectedVideos = Set.from(
            _autoSelectedVideos); // Inicializar com seleções automáticas
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
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

  // Verificar se há vídeos selecionados
  bool get _hasSelectedVideos {
    return _selectedVideos.isNotEmpty;
  }

  // Verificar se todos os vídeos foram desmarcados (lista vazia)
  bool get _hasEmptyList {
    return _autoSelectedVideos.isNotEmpty && _selectedVideos.isEmpty;
  }

  Future<void> _addSelectedVideos() async {
    if (_selectedVideos.isEmpty) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final firebaseVideoListProvider =
          context.read<FirebaseVideoListProvider>();
      final selectedVideos =
          _searchResults.where((v) => _selectedVideos.contains(v.id)).toList();

      final success = await firebaseVideoListProvider.addVideosToList(
          widget.listId, selectedVideos);

      setState(() {
        if (success) {
          // Manter seleções e atualizar auto-seleções com os vídeos adicionados
          _autoSelectedVideos.addAll(_selectedVideos);
        }
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(success
                ? '${selectedVideos.length} vídeo(s) adicionado(s) à lista!'
                : 'Erro ao adicionar vídeos.')),
      );
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao adicionar vídeos: $e')),
      );
    }
  }

  Future<void> _saveEmptyList() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final firebaseVideoListProvider =
          context.read<FirebaseVideoListProvider>();

      // Remover todos os vídeos da lista
      for (final videoId in _autoSelectedVideos) {
        await firebaseVideoListProvider.removeVideoFromList(
            widget.listId, videoId);
      }

      setState(() {
        // Manter seleções desmarcadas (lista vazia)
        _selectedVideos.clear(); // Manter desmarcados
        _autoSelectedVideos.clear(); // Limpar auto-seleções
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lista salva vazia!')),
      );
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar lista vazia: $e')),
      );
    }
  }

  Future<void> _addVideoToList(VideoModel video) async {
    try {
      final firebaseVideoListProvider =
          context.read<FirebaseVideoListProvider>();
      await firebaseVideoListProvider.addVideoToList(widget.listId, video);
      // Atualizar o estado para refletir a mudança
      setState(() {});
    } catch (e) {
      // Removido SnackBar de erro
    }
  }

  void _previewVideo(VideoModel video) {
    _previewController?.pause();
    _previewController?.dispose();

    final controller = YoutubePlayerController(
      initialVideoId: video.id,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
      ),
    );

    setState(() {
      _previewController = controller;
      _previewVideoTitle = video.title;
      _previewVideoId = video.id;
    });
  }

  void _closePreview() {
    _previewController?.dispose();
    setState(() {
      _previewController = null;
      _previewVideoTitle = null;
      _previewVideoId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final firebaseVideoProvider = context.watch<FirebaseVideoProvider>();
    final previousSearches = firebaseVideoProvider.previousSearches;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Buscar Vídeos',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Buscar vídeos',
                      hintText: 'Digite sua busca...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _searchVideos,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: 'Buscar',
                  onPressed: () => _searchVideos(_searchController.text),
                ),
              ],
            ),
          ),
          if (previousSearches.isNotEmpty && !_hasSearched)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Buscas recentes:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: previousSearches.map((search) {
                      return ActionChip(
                        label: Text(search),
                        onPressed: () {
                          _searchController.text = search;
                          _searchVideos(search);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          // Botão para processar vídeos selecionados
          if (_hasSelectedVideos)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _addSelectedVideos,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.check),
                      label: Text(_isSaving
                          ? 'Salvando...'
                          : 'Adicionar ${_selectedVideos.length} vídeo(s) à Lista'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _isSaving
                        ? null
                        : () => setState(() => _selectedVideos.clear()),
                    child: const Text('Limpar'),
                  ),
                ],
              ),
            ),
          // Botão para salvar lista vazia
          if (_hasEmptyList)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveEmptyList,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                          _isSaving ? 'Salvando...' : 'Salvar Lista Vazia'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[700],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _isSaving
                        ? null
                        : () => setState(() {
                              _selectedVideos.addAll(_autoSelectedVideos);
                            }),
                    child: const Text('Restaurar'),
                  ),
                ],
              ),
            ),
          if (_previewController != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _previewVideoTitle ?? 'Pré-visualização',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _closePreview,
                        tooltip: 'Fechar pré-visualização',
                      ),
                    ],
                  ),
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: YoutubePlayer(
                        key: ValueKey(_previewVideoId),
                        controller: _previewController!,
                        showVideoProgressIndicator: true,
                        progressIndicatorColor: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty && _hasSearched
                    ? const EmptyStateWidget(
                        icon: Icons.search_off,
                        title: 'Nenhum resultado encontrado',
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: AppConstants.gridCrossAxisCount,
                          childAspectRatio: AppConstants.gridChildAspectRatio,
                          crossAxisSpacing: AppConstants.gridSpacing,
                          mainAxisSpacing: AppConstants.gridSpacing,
                        ),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final video = _searchResults[index];
                          final isSelected = _selectedVideos.contains(video.id);

                          return VideoCard(
                            video: video,
                            isSelected: isSelected,
                            onTap: () => _toggleVideoSelection(video.id),
                            onPreview: () => _previewVideo(video),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _previewController?.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
