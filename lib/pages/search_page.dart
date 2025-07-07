import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/video_provider.dart';
import '../providers/video_list_provider.dart';
import '../models/video_model.dart';
import '../widgets/video_card.dart';

class SearchPage extends StatefulWidget {
  final String listId;

  const SearchPage({Key? key, required this.listId}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  List<VideoModel> videos = [];
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    final videoProvider = Provider.of<VideoProvider>(context);
    final videoListProvider = Provider.of<VideoListProvider>(context);

    final list =
        videoListProvider.lists.firstWhere((l) => l.id == widget.listId);

    Future<void> _search(String query) async {
      FocusScope.of(context).unfocus();
      setState(() => loading = true);
      videos = await videoProvider.search(query);
      videoProvider.addSearchTerm(query, list.profileId);
      setState(() => loading = false);
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Adicionar vídeos a ${list.name}',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green[700],
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(labelText: 'Pesquisar'),
              textInputAction: TextInputAction.search,
              onSubmitted: _search,
            ),
          ),
          if (videos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pesquisas anteriores:'),
                  Wrap(
                    spacing: 8,
                    children: videoProvider.previousSearches.map((term) {
                      return ActionChip(
                        label: Text(term),
                        onPressed: () => _search(term),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ElevatedButton(
            onPressed: () => _search(_controller.text),
            child: const Text('Buscar'),
          ),
          if (loading) const CircularProgressIndicator(),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: videos.length,
              itemBuilder: (_, i) {
                final video = videos[i];
                final isAdded = list.videos.any((v) => v.id == video.id);

                return VideoCard(
                  video: video,
                  isAdded: isAdded,
                  onAddConfirmed: () async {
                    if (!isAdded) {
                      await videoListProvider.addVideoToList(
                          widget.listId, video);
                      await videoProvider.cacheVideo(video);
                      setState(() {});
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
