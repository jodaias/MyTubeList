import 'package:flutter/material.dart';
import 'package:my_tube_list/utils/confirmation_modal.dart';
import 'package:my_tube_list/widgets/video_card.dart';
import 'package:provider/provider.dart';
import '../providers/video_list_provider.dart';

class VideosPage extends StatefulWidget {
  final String listId;

  const VideosPage({
    Key? key,
    required this.listId,
  }) : super(key: key);

  @override
  State<VideosPage> createState() => _VideosPageState();
}

class _VideosPageState extends State<VideosPage> {
  @override
  Widget build(BuildContext context) {
    final videoListProvider = context.watch<VideoListProvider>();
    final list = videoListProvider.getListById(widget.listId);
    final videos = list.videos;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.menu_open_outlined, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Vídeos de ${list.name}',
            style: TextStyle(
              color: Colors.white,
            )),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.white),
            onPressed: () async {
              final canEnter = await showMathConfirmationModal(
                  context, "Acesso a tela de pesquisa!", "confirmar");
              if (canEnter) {
                Navigator.pushNamed(context, '/search',
                    arguments: widget.listId);
              }
            },
          ),
        ],
        backgroundColor: Colors.green[700],
      ),
      body: SafeArea(
        child: videos.isEmpty
            ? Center(child: Text('Nenhum vídeo nesta lista.'))
            : GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.15,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: videos.length,
                itemBuilder: (context, index) {
                  final video = videos[index];
                  return VideoCard(
                    video: video,
                    showPlayButton: true,
                    onTap: () {
                      Navigator.pushNamed(context, '/player', arguments: {
                        'listId': widget.listId,
                        'videos': videos,
                        'currentIndex': index,
                      });
                    },
                    onDeleteConfirmed: () async {
                      final confirmed = await showMathConfirmationModal(context,
                          "Acesso a modal: excluir video!", "Confirmar");
                      if (confirmed) {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Excluir vídeo'),
                            content: Text(
                                'Tem certeza que deseja excluir este vídeo da lista?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text('Cancelar'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text('Excluir'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await videoListProvider.removeVideoFromList(
                              widget.listId, video.id);
                          videos.removeWhere((v) => v.id == video.id);
                        }
                      }
                    },
                  );
                },
              ),
      ),
    );
  }
}
