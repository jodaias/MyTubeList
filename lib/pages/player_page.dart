import 'package:flutter/material.dart';
import 'package:my_tube_list/providers/video_provider.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/video_model.dart';

class PlayerPage extends StatefulWidget {
  final List<VideoModel> allowedVideos;
  final int initialIndex;

  const PlayerPage({
    Key? key,
    required this.allowedVideos,
    required this.initialIndex,
  }) : super(key: key);

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late YoutubePlayerController _controller;
  late int _currentIndex;
  late VideoProvider _videoProvider;
  final ScrollController _scrollController = ScrollController();

  bool _showList = false;
  bool _repeat = false;
  bool _currentStatusPlaying = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _setupController();
    _controller.addListener(() {
      if (mounted && _currentStatusPlaying != _controller.value.isPlaying) {
        _currentStatusPlaying = _controller.value.isPlaying;
        setState(() {});
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToCurrentIndex();
    });
  }

  void _setupController() {
    _videoProvider = Provider.of<VideoProvider>(context, listen: false);
    _videoProvider.setAllowedVideos(widget.allowedVideos);
    final video = widget.allowedVideos[_currentIndex];

    _controller = YoutubePlayerController(
      initialVideoId: video.id,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        hideControls: false,
        controlsVisibleAtStart: false,
        enableCaption: false,
        disableDragSeek: true,
        showLiveFullscreenButton: true,
      ),
    );
  }

  void scrollToCurrentIndex() {
    final itemHeight = 50.0;
    _scrollController.animateTo(
      _currentIndex * itemHeight,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  void _playVideo(int index, {int startAt = 0}) {
    setState(() {
      if (_currentIndex != index) _repeat = false;
      _currentIndex = index;
      _controller.load(widget.allowedVideos[_currentIndex].id,
          startAt: startAt);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Stack(
      children: [
        YoutubePlayerBuilder(
          onExitFullScreen: () {
            setState(() {
              _showList = false;
            });
          },
          player: YoutubePlayer(
            controller: _controller,
            showVideoProgressIndicator: true,
            controlsTimeOut: Duration(seconds: 5),
            progressIndicatorColor: Colors.blueAccent,
            topActions: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    if (isLandscape)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(40, 40),
                          padding: EdgeInsets.zero,
                          shape: CircleBorder(),
                        ),
                        onPressed: () {
                          setState(() {
                            _showList = !_showList;
                          });
                        },
                        child: Icon(
                          _showList
                              ? Icons.playlist_remove
                              : Icons.playlist_play,
                          color: Colors.grey.shade700,
                          size: 24,
                        ),
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.allowedVideos[_currentIndex].title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            bottomActions: [
              IconButton(
                icon: Icon(
                  Icons.repeat_one,
                  color: _repeat ? Colors.greenAccent : Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _repeat = !_repeat;
                  });
                },
              ),
              const SizedBox(width: 8),
              CurrentPosition(),
              ProgressBar(isExpanded: true),
              RemainingDuration(),
              const FullScreenButton(),
            ],
            onEnded: (data) {
              var nextIndex = _currentIndex;
              if (!_repeat) {
                nextIndex = (_currentIndex + 1) % widget.allowedVideos.length;
              }
              _playVideo(nextIndex);
            },
          ),
          builder: (context, player) => Scaffold(
            appBar: AppBar(
              leading: IconButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.menu),
                color: Colors.white,
              ),
              backgroundColor: Colors.green[700],
              centerTitle: true,
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.allowedVideos[_currentIndex].title,
                      style: const TextStyle(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              actions: [
                if (isLandscape)
                  IconButton(
                    icon: Icon(
                      _showList ? Icons.close : Icons.playlist_play,
                      color: Colors.white,
                    ),
                    onPressed: () => setState(() => _showList = !_showList),
                  ),
              ],
            ),
            body: Column(
              children: [
                player,
                Expanded(child: _buildVideoList()),
              ],
            ),
          ),
        ),
        if (isLandscape)
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              width: _showList ? MediaQuery.of(context).size.width * 0.25 : 0,
              child: Material(
                color: Colors.white,
                child: Container(
                    color: Colors.green[800],
                    child: _buildVideoListToFullscren()),
              ),
            ),
          ),

        // Overlay para capturar o tap
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onDoubleTap: () {
              setState(() {
                _showList = !_showList;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVideoListToFullscren() {
    return ReorderableListView.builder(
      scrollController: _scrollController,
      buildDefaultDragHandles: false,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex -= 1;
          final video = widget.allowedVideos.removeAt(oldIndex);
          widget.allowedVideos.insert(newIndex, video);
          _videoProvider.setAllowedVideos(widget.allowedVideos);

          if (_currentIndex == oldIndex) {
            _currentIndex = newIndex;
          } else if (oldIndex < _currentIndex && newIndex >= _currentIndex) {
            _currentIndex -= 1;
          } else if (oldIndex > _currentIndex && newIndex <= _currentIndex) {
            _currentIndex += 1;
          }
        });
      },
      itemCount: widget.allowedVideos.length,
      itemBuilder: (context, index) {
        final video = widget.allowedVideos[index];
        final isPlaying = index == _currentIndex;

        return KeyedSubtree(
          key: ValueKey(video.id),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              final offsetAnimation = Tween<Offset>(
                begin: const Offset(0.1, 0),
                end: Offset.zero,
              ).animate(animation);
              return SlideTransition(
                position: offsetAnimation,
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: InkWell(
              onTap: () {
                if (!isPlaying) {
                  _playVideo(index);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isPlaying ? Colors.green[300] : Colors.transparent,
                  border: Border(
                    bottom: BorderSide(color: Colors.green.shade900),
                  ),
                ),
                child: Row(
                  children: [
                    // Drag handle para reorder
                    ReorderableDragStartListener(
                      index: index,
                      child: Icon(
                        Icons.drag_handle,
                        color: Colors.white,
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          Image.network(
                            video.thumbnailUrl,
                            width: double.infinity,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            video.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white),
                          ),
                          if (_currentIndex == index)
                            Positioned(
                              bottom: 42,
                              right: 4,
                              child: _controller.value.isPlaying
                                  ? Image.asset(
                                      'assets/gifs/playing.gif',
                                      width: 30,
                                      height: 30,
                                    )
                                  : Image.asset(
                                      'assets/images/paused.png',
                                      width: 30,
                                      height: 30,
                                    ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoList() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.only(bottom: 60),
      scrollController: _scrollController,
      buildDefaultDragHandles: false,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex -= 1;
          final video = widget.allowedVideos.removeAt(oldIndex);
          widget.allowedVideos.insert(newIndex, video);
          _videoProvider.setAllowedVideos(widget.allowedVideos);

          if (_currentIndex == oldIndex) {
            _currentIndex = newIndex;
          } else if (oldIndex < _currentIndex && newIndex >= _currentIndex) {
            _currentIndex -= 1;
          } else if (oldIndex > _currentIndex && newIndex <= _currentIndex) {
            _currentIndex += 1;
          }
        });
      },
      itemCount: widget.allowedVideos.length,
      itemBuilder: (context, index) {
        final video = widget.allowedVideos[index];
        return KeyedSubtree(
          key: ValueKey(video.id),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              final offsetAnimation = Tween<Offset>(
                begin: const Offset(0.1, 0),
                end: Offset.zero,
              ).animate(animation);
              return SlideTransition(
                position: offsetAnimation,
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: ListTile(
              key: ValueKey(video.id),
              selected: index == _currentIndex,
              selectedTileColor: Colors.green[800],
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ReorderableDragStartListener(
                    key: ValueKey(video.id),
                    index: index,
                    child: Container(
                      child: Stack(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.drag_handle,
                                color: index == _currentIndex
                                    ? Colors.white
                                    : Colors.grey.shade700,
                              ),
                              const SizedBox(width: 5),
                              SizedBox(
                                height: 60,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(
                                    video.thumbnailUrl,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_currentIndex == index)
                            Positioned(
                              bottom: 0,
                              right: 4,
                              child: _controller.value.isPlaying
                                  ? Image.asset(
                                      'assets/gifs/playing.gif',
                                      width: 30,
                                      height: 30,
                                    )
                                  : Image.asset(
                                      'assets/images/paused.png',
                                      width: 30,
                                      height: 30,
                                    ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              trailing: _currentIndex == index && _repeat
                  ? const Icon(Icons.repeat_one, color: Colors.white)
                  : null,
              title: Text(
                video.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: index == _currentIndex
                      ? Colors.white
                      : Colors.grey.shade700,
                ),
              ),
              onTap: () {
                if (_currentIndex != index) {
                  _playVideo(index);
                }
              },
            ),
          ),
        );
      },
    );
  }
}
