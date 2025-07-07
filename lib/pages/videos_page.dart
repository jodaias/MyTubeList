import 'package:flutter/material.dart';
import 'package:my_tube_list/utils/confirmation_modal.dart';
import 'package:my_tube_list/widgets/video_card.dart';
import 'package:provider/provider.dart';
import '../models/video_model.dart';
import '../providers/video_list_provider.dart';

class VideosPage extends StatefulWidget {
  final String listId;
  final String listName;
  final List<VideoModel> videos;

  const VideosPage({
    Key? key,
    required this.listId,
    required this.listName,
    required this.videos,
  }) : super(key: key);

  @override
  State<VideosPage> createState() => _VideosPageState();
}

class _VideosPageState extends State<VideosPage> {
  @override
  Widget build(BuildContext context) {
    final videoListProvider = context.watch<VideoListProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Vídeos de ${widget.listName}',
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
      body: widget.videos.isEmpty
          ? Center(child: Text('Nenhum vídeo nesta lista.'))
          : ListView.builder(
              itemCount: widget.videos.length,
              itemBuilder: (context, index) {
                final video = widget.videos[index];
                return VideoCard(
                  video: video,
                  onTap: () {
                    Navigator.pushNamed(context, '/player', arguments: {
                      'listId': widget.listId,
                      'videos': widget.videos,
                      'currentIndex': index,
                    });
                  },
                  onDeleteConfirmed: () async {
                    final confirmed = await showMathConfirmationModal(
                        context, "Acesso a modal: excluir video!", "Confirmar");
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
                        widget.videos.removeWhere((v) => v.id == video.id);
                      }
                    }
                  },
                );
              },
            ),
    );
  }
}
