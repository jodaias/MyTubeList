import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/video_model.dart';

class VideoCard extends StatelessWidget {
  final VideoModel video;
  final VoidCallback? onTap;

  final Future<void> Function()? onDeleteConfirmed;
  final Future<void> Function()? onAddConfirmed;
  final Future<void> Function()? onRemoveConfirmed;
  final VoidCallback? onPreview;
  final bool isAdded;
  final bool showPlayButton;
  final bool? isSelected; // Nova propriedade para seleção
  final bool isDeleting; // Nova propriedade para loading do delete

  const VideoCard({
    required this.video,
    this.onTap,
    this.isAdded = false,
    this.showPlayButton = false,
    this.isSelected, // Nova propriedade
    this.isDeleting = false, // Nova propriedade para loading do delete
    this.onAddConfirmed = null,
    this.onDeleteConfirmed = null,
    this.onRemoveConfirmed = null,
    this.onPreview,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isAdded ? 0.7 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 160, // Tamanho fixo menor
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

                  // Botão de play grande no centro
                  if (showPlayButton)
                    Positioned.fill(
                      child: Center(
                        child: Container(
                          width: AppConstants.playButtonContainerSize,
                          height: AppConstants.playButtonContainerSize,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: AppConstants.playButtonIconSize,
                            ),
                            tooltip: 'Reproduzir vídeo',
                            onPressed: onTap,
                            splashRadius: 25,
                          ),
                        ),
                      ),
                    ),

                  // Botão de preview (play) no canto inferior esquerdo
                  if (onPreview != null)
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 22,
                          ),
                          tooltip: 'Pré-visualizar',
                          onPressed: onPreview,
                          splashRadius: 15,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ),
                    ),

                  // Checkbox para seleção (mostrar quando isSelected é usado)
                  if (isSelected != null)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSelected == true
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color:
                              isSelected == true ? Colors.green : Colors.white,
                          size: AppConstants.selectionIconSize,
                        ),
                      ),
                    )
                  // Botão de adicionar/remover (prioridade sobre deletar)
                  else if (onAddConfirmed != null || onRemoveConfirmed != null)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            isAdded
                                ? Icons.remove_circle_outline
                                : Icons.add_circle_outline,
                            color: isAdded ? Colors.red : Colors.green,
                            size: AppConstants.selectionIconSize,
                          ),
                          tooltip: isAdded
                              ? 'Remover da lista'
                              : 'Adicionar à lista',
                          onPressed: () async {
                            if (isAdded && onRemoveConfirmed != null) {
                              await onRemoveConfirmed!();
                            } else if (!isAdded && onAddConfirmed != null) {
                              await onAddConfirmed!();
                            }
                          },
                          splashRadius: 15,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    )
                  // Botão de deletar (só se não tiver add/remove nem seleção)
                  else if (onDeleteConfirmed != null)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: isDeleting
                            ? const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.delete_outline),
                                color: Colors.white,
                                iconSize: 20,
                                tooltip: 'Excluir vídeo',
                                onPressed: () async {
                                  await onDeleteConfirmed!();
                                },
                                splashRadius: 15,
                              ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                video.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: AppConstants.videoTitleFontSize),
              ),
              if (isAdded)
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Text(
                    'Adicionado',
                    style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: AppConstants.addedTextFontSize),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
