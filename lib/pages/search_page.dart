import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/video_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/video_card.dart';
import '../models/video_model.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

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
    final profileProvider = Provider.of<ProfileProvider>(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Pesquisar Vídeos',
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
                        onPressed: () async {
                          FocusScope.of(context).unfocus();
                          setState(() {
                            loading = true;
                          });
                          videos = await videoProvider.search(term);
                          setState(() {
                            loading = false;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ElevatedButton(
            onPressed: () async {
              FocusScope.of(context).unfocus();
              setState(() => loading = true);
              videos = await videoProvider.search(_controller.text);
              videoProvider.addSearchTerm(
                  _controller.text, profileProvider.selectedProfile!.id);
              setState(() => loading = false);
            },
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
                final isAdded = profileProvider.selectedProfile?.allowedVideoIds
                        .contains(video.id) ??
                    false;

                return VideoCard(
                  video: video,
                  isAdded: isAdded,
                  onAddConfirmed: () async {
                    if (!isAdded) {
                      // Adiciona no ProfileProvider
                      await profileProvider.addAllowedVideo(video.id);
                      // Salva no cache do VideoProvider
                      await videoProvider.cacheVideo(video);
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
