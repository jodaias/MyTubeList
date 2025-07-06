import 'package:flutter/material.dart';
import '../models/video_model.dart';

class VideoCard extends StatelessWidget {
  final VideoModel video;
  final VoidCallback? onTap;

  final Future<void> Function()? onDeleteConfirmed;
  final Future<void> Function()? onAddConfirmed;
  final bool isAdded;

  const VideoCard({
    required this.video,
    this.onTap,
    this.isAdded = false,
    this.onAddConfirmed = null,
    this.onDeleteConfirmed = null,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isAdded ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      video.thumbnailUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // Botão de deletar se existir callback
                if (onDeleteConfirmed != null)
                  Positioned(
                    top: 5,
                    right: 15,
                    child: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await onDeleteConfirmed!();
                      },
                      splashRadius: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),

                if (onAddConfirmed != null)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      icon: Icon(
                        isAdded ? Icons.check_circle : Icons.add_circle_outline,
                        color: isAdded ? Colors.green : Colors.blue,
                        size: 35,
                      ),
                      onPressed: isAdded
                          ? null
                          : () async {
                              await onAddConfirmed!();
                            },
                      splashRadius: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              video.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (isAdded)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Adicionado',
                  style: TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
