import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_tube_list/providers/video_provider.dart';
import 'package:my_tube_list/utils/confirmation_modal.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class FullScreenPlayerPage extends StatefulWidget {
  final int initialIndex;
  final YoutubePlayerController controller;
  final bool repeat;

  const FullScreenPlayerPage({
    Key? key,
    required this.initialIndex,
    required this.controller,
    this.repeat = false,
  }) : super(key: key);

  @override
  State<FullScreenPlayerPage> createState() => _FullScreenPlayerPageState();
}

class _FullScreenPlayerPageState extends State<FullScreenPlayerPage> {
  late YoutubePlayerController _controller;
  late int _currentIndex;
  late VideoProvider _videoProvider;
  bool _showList = false;
  bool _repeat = false;

  @override
  void initState() {
    super.initState();
    _videoProvider = Provider.of<VideoProvider>(context, listen: false);
    _currentIndex = widget.initialIndex;
    _repeat = widget.repeat;
    _controller = YoutubePlayerController(
      initialVideoId: _videoProvider.allowedVideos[_currentIndex].id,
      flags: YoutubePlayerFlags(
        autoPlay: true,
        startAt: widget.controller.value.position.inSeconds + 3,
        mute: false,
        hideControls: false,
        controlsVisibleAtStart: false,
        enableCaption: false,
        disableDragSeek: true,
        showLiveFullscreenButton: false,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setLandscapeMode();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _playVideo(int index, {int startAt = 0}) {
    if (_currentIndex == index && !_repeat) return;
    setState(() {
      _currentIndex = index;
      _controller.load(_videoProvider.allowedVideos[index].id,
          startAt: startAt);
    });
  }

  Future<void> _onPopScope(bool didPop, _) async {
    if (didPop) return;
    final shouldExit = await showExitConfirmationDialog(context);

    if (shouldExit) {
      setPortraitMode();
      Navigator.of(context)
          .pop('${_currentIndex}|${_controller.value.position.inSeconds}');
    } else {
      setLandscapeMode();
    }
  }

  Future<void> setLandscapeMode() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> setPortraitMode() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onPopScope,
      child: Scaffold(
        backgroundColor: Colors.green[900],
        body: SafeArea(
          child: Stack(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: YoutubePlayerBuilder(
                      player: YoutubePlayer(
                        controller: _controller,
                        showVideoProgressIndicator: true,
                        controlsTimeOut: Duration(seconds: 2),
                        bottomActions: [
                          IconButton(
                            icon: Icon(
                              Icons.repeat,
                              color:
                                  _repeat ? Colors.greenAccent : Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                _repeat = !_repeat;
                              });
                            },
                          ),
                          CurrentPosition(),
                          ProgressBar(isExpanded: true),
                          RemainingDuration(),
                          IconButton(
                            icon: const Icon(
                              Icons.fullscreen_exit,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              setPortraitMode();
                              Navigator.of(context).pop(
                                  '${_currentIndex}|${_controller.value.position.inSeconds}');
                            },
                          )
                        ],
                        progressIndicatorColor: Colors.greenAccent,
                        onEnded: (data) {
                          var nextIndex = _currentIndex;

                          if (!_repeat)
                            nextIndex = (_currentIndex + 1) %
                                _videoProvider.allowedVideos.length;

                          _playVideo(nextIndex);
                        },
                      ),
                      builder: (context, player) => player,
                    ),
                  ),
                  AnimatedContainer(
                    duration: Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    width: _showList
                        ? MediaQuery.of(context).size.width * 0.25
                        : 0,
                    child: Container(
                      color: Colors.green[800],
                      child: ListView.builder(
                        itemCount: _videoProvider.allowedVideos.length,
                        itemBuilder: (context, index) {
                          final video = _videoProvider.allowedVideos[index];
                          return InkWell(
                            onTap: () {
                              if (index != _currentIndex) {
                                setState(() {
                                  _repeat = false;
                                });
                              }
                              _playVideo(index);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: index == _currentIndex
                                    ? Colors.green[700]
                                    : Colors.transparent,
                                border: Border(
                                  bottom:
                                      BorderSide(color: Colors.green.shade900),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
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
          ),
        ),
      ),
    );
  }
}
