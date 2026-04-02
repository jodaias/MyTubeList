import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../models/video_model.dart';
import '../providers/firebase_video_list_provider.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

enum _VerticalGestureSide { left, right }

class PlayerPage extends StatefulWidget {
  final List<VideoModel> videos;
  final String listId;
  final int currentIndex;

  const PlayerPage({
    Key? key,
    required this.videos,
    required this.listId,
    this.currentIndex = 0,
  }) : super(key: key);

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late YoutubePlayerController _controller;
  final ScrollController _scrollController = ScrollController();
  final VolumeController _volumeController = VolumeController.instance;
  late int _currentIndex;
  bool _showList = false;
  bool _repeat = false;
  bool isFullScreen = false;
  bool _isScreenLocked = false;
  bool _showUnlockButton = false;
  bool _currentStatusPlaying = true;
  late List<GlobalKey> _itemKeys;

  // Feedback de 10s
  bool _showForward = false;
  bool _showBackward = false;

  // Variáveis para controle do gesto
  double _dragStartX = 0.0;
  double _dragUpdateX = 0.0;

  double _currentBrightness = 0.5;
  double _currentVolume = 0.5;
  double _gestureStartY = 0.0;
  double _gestureStartBrightness = 0.5;
  double _gestureStartVolume = 0.5;
  _VerticalGestureSide? _activeVerticalGestureSide;
  _VerticalGestureSide _lastGestureSide = _VerticalGestureSide.left;
  String _gestureLabel = '';
  double _gestureValue = 0.0;
  bool _showGestureFeedback = false;
  int _gestureFeedbackVersion = 0;
  int _unlockUiVersion = 0;

  @override
  void initState() {
    super.initState();
    _setPlayerOrientations();
    _currentIndex = widget.currentIndex;
    _setupController();

    _itemKeys = List.generate(widget.videos.length, (_) => GlobalKey());

    _controller.addListener(() {
      if (mounted && _currentStatusPlaying != _controller.value.isPlaying) {
        _currentStatusPlaying = _controller.value.isPlaying;
        setState(() {});
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToIndex(_currentIndex);
    });

    _initializeSystemControls();
  }

  Future<void> _setPlayerOrientations() {
    return SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _setPortraitOnlyOrientation() {
    return SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  Future<void> _initializeSystemControls() async {
    try {
      _volumeController.showSystemUI = false;

      final brightness = await ScreenBrightness().application;
      final volume = await _volumeController.getVolume();

      if (!mounted) return;
      setState(() {
        _currentBrightness = brightness.clamp(0.0, 1.0);
        _currentVolume = volume.clamp(0.0, 1.0);
      });
    } catch (_) {
      // Mantem valores padrao caso o dispositivo nao permita leitura.
    }
  }

  void _onVerticalDragStart(
      DragStartDetails details, _VerticalGestureSide side) {
    if (isFullScreen && _isScreenLocked) return;

    // Brilho e volume por gesto vertical funcionam apenas em tela cheia.
    if (!isFullScreen) return;

    _activeVerticalGestureSide = side;
    _lastGestureSide = side;
    _gestureStartY = details.globalPosition.dy;
    _gestureStartBrightness = _currentBrightness;
    _gestureStartVolume = _currentVolume;
  }

  Future<void> _onVerticalDragUpdate(DragUpdateDetails details) async {
    if (isFullScreen && _isScreenLocked) return;
    if (_activeVerticalGestureSide == null) return;

    if (!isFullScreen) return;

    final screenHeight = MediaQuery.of(context).size.height;
    final normalizedDelta =
        (_gestureStartY - details.globalPosition.dy) / screenHeight;
    final scaledDelta = normalizedDelta * 1.5;

    if (_activeVerticalGestureSide == _VerticalGestureSide.left) {
      final newBrightness =
          (_gestureStartBrightness + scaledDelta).clamp(0.0, 1.0);
      _currentBrightness = newBrightness;
      try {
        await ScreenBrightness().setApplicationScreenBrightness(newBrightness);
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _gestureLabel = 'Brilho';
        _gestureValue = newBrightness;
        _showGestureFeedback = true;
      });
      return;
    }

    final newVolume = (_gestureStartVolume + scaledDelta).clamp(0.0, 1.0);
    _currentVolume = newVolume;
    await _volumeController.setVolume(newVolume);

    if (!mounted) return;
    setState(() {
      _gestureLabel = 'Volume';
      _gestureValue = newVolume;
      _showGestureFeedback = true;
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (isFullScreen && _isScreenLocked) return;
    _activeVerticalGestureSide = null;
    final localVersion = ++_gestureFeedbackVersion;

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted || localVersion != _gestureFeedbackVersion) return;
      setState(() {
        _showGestureFeedback = false;
      });
    });
  }

  Widget _buildPlayerGestureLayer({double rightInset = 0}) {
    return Positioned(
      left: 0,
      top: 0,
      bottom: 0,
      right: rightInset,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onDoubleTap: _skipBackward,
              onVerticalDragStart: (details) =>
                  _onVerticalDragStart(details, _VerticalGestureSide.left),
              onVerticalDragUpdate: _onVerticalDragUpdate,
              onVerticalDragEnd: _onVerticalDragEnd,
              child: Container(),
            ),
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onDoubleTap: _skipForward,
              onVerticalDragStart: (details) =>
                  _onVerticalDragStart(details, _VerticalGestureSide.right),
              onVerticalDragUpdate: _onVerticalDragUpdate,
              onVerticalDragEnd: _onVerticalDragEnd,
              child: Container(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGestureFeedback() {
    final percent = (_gestureValue * 100).round();
    final icon =
        _gestureLabel == 'Volume' ? Icons.volume_up : Icons.brightness_6;
    const barHeight = AppConstants.gestureFeedbackBarHeight;
    final filledHeight =
        (_gestureValue * barHeight).clamp(0.0, barHeight).toDouble();

    return Container(
      width: 56,
      height: 172,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(height: 8),
          Container(
            width: 8,
            height: barHeight,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.24),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedContainer(
                duration: AppConstants.gestureFeedbackAnimation,
                curve: Curves.easeOut,
                width: 8,
                height: filledHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            width: AppConstants.percentTextWidth,
            height: AppConstants.percentTextHeight,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('$percent%',
                    textScaler: TextScaler.noScaling,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFeatures: [FontFeature.tabularFigures()],
                    )),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGestureFeedbackOverlay() {
    final side = _activeVerticalGestureSide ?? _lastGestureSide;
    final alignment = side == _VerticalGestureSide.left
        ? Alignment.centerLeft
        : Alignment.centerRight;
    final edgeInset = MediaQuery.of(context).padding.horizontal / 2 + 100;

    return Positioned.fill(
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: edgeInset),
          child: _buildGestureFeedback(),
        ),
      ),
    );
  }

  Widget _buildFullscreenLockButton({required bool locked}) {
    return Container(
      width: AppConstants.lockButtonSize,
      height: AppConstants.lockButtonSize,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.48),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: AnimatedSwitcher(
          duration: AppConstants.lockButtonAnimation,
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: Icon(
            locked ? Icons.lock : Icons.lock_open,
            key: ValueKey<bool>(locked),
          ),
        ),
        color: Colors.white,
        iconSize: 20,
        padding: EdgeInsets.zero,
        tooltip: locked ? 'Desbloquear tela' : 'Bloquear tela',
        onPressed: () {
          setState(() {
            _isScreenLocked = !locked;
            _showUnlockButton = true;
            if (_isScreenLocked) {
              _showList = false;
              _showForward = false;
              _showBackward = false;
              _showGestureFeedback = false;
            }
          });

          _showUnlockButtonTemporarily();
        },
      ),
    );
  }

  void _showUnlockButtonTemporarily() {
    if (!isFullScreen) return;
    final localVersion = ++_unlockUiVersion;

    setState(() {
      _showUnlockButton = true;
    });

    Future.delayed(AppConstants.unlockButtonTimeout, () {
      if (!mounted || localVersion != _unlockUiVersion || !isFullScreen) {
        return;
      }

      setState(() {
        _showUnlockButton = false;
      });
    });
  }

  void _toggleUnlockButtonVisibility() {
    if (!isFullScreen) return;

    if (_showUnlockButton) {
      _unlockUiVersion++;
      setState(() {
        _showUnlockButton = false;
      });
      return;
    }

    _showUnlockButtonTemporarily();
  }

  void _setupController() {
    final video = widget.videos[_currentIndex];

    _controller = YoutubePlayerController(
      initialVideoId: video.id,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        hideControls: false,
        controlsVisibleAtStart: false,
        enableCaption: false,
        disableDragSeek: true,
        hideThumbnail: true,
        showLiveFullscreenButton: true,
      ),
    );
  }

  Future<void> scrollToIndex(int index,
      {double itemHeight = AppConstants.portraitListItemHeight}) async {
    final offset = index * itemHeight;

    await _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    Future.delayed(AppConstants.scrollPostFrameDelay, () {
      if (_itemKeys[index].currentContext != null) {
        Scrollable.ensureVisible(
          _itemKeys[index].currentContext!,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _playVideo(int index, {int startAt = 0}) {
    setState(() {
      if (_currentIndex != index) _repeat = false;
      _currentIndex = index;
      _controller.load(widget.videos[_currentIndex].id, startAt: startAt);
    });
  }

  void _skipForward() {
    final current = _controller.value.position.inSeconds;
    _controller.seekTo(Duration(seconds: current + 10));
    _showFeedback(isForward: true);
  }

  void _skipBackward() {
    final current = _controller.value.position.inSeconds;
    _controller.seekTo(Duration(seconds: (current - 10).clamp(0, current)));
    _showFeedback(isForward: false);
  }

  void _showFeedback({required bool isForward}) {
    setState(() {
      if (isForward) {
        _showForward = true;
      } else {
        _showBackward = true;
      }
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _showForward = false;
          _showBackward = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _setPortraitOnlyOrientation();
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
              isFullScreen = false;
              _isScreenLocked = false;
              _showUnlockButton = false;
            });

            WidgetsBinding.instance.addPostFrameCallback((_) {
              scrollToIndex(_currentIndex);
            });
          },
          onEnterFullScreen: () {
            setState(() {
              isFullScreen = true;
              _isScreenLocked = false;
              _showUnlockButton = true;
            });

            _showUnlockButtonTemporarily();
          },
          player: YoutubePlayer(
            controller: _controller,
            showVideoProgressIndicator: true,
            controlsTimeOut: AppConstants.playerControlsTimeout,
            progressIndicatorColor: Colors.blueAccent,
            topActions: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    if (isLandscape)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(40, 40),
                          padding: EdgeInsets.zero,
                          shape: const CircleBorder(),
                        ),
                        onPressed: () {
                          if (_isScreenLocked) return;
                          setState(() => _showList = !_showList);
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            scrollToIndex(_currentIndex,
                                itemHeight:
                                    AppConstants.fullscreenListItemHeight);
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
                        widget.videos[_currentIndex].title,
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
                tooltip: _repeat ? 'Desativar repetição' : 'Repetir vídeo',
                onPressed: () {
                  setState(() => _repeat = !_repeat);
                },
              ),
              const SizedBox(width: 8),
              CurrentPosition(),
              ProgressBar(isExpanded: true),
              RemainingDuration(),
              FullScreenButton(),
            ],
            onEnded: (data) {
              var nextIndex = _currentIndex;
              if (!_repeat) {
                nextIndex = (_currentIndex + 1) % widget.videos.length;
              }
              _playVideo(nextIndex);
            },
          ),
          builder: (context, player) => Scaffold(
            appBar: AppBar(
              iconTheme: const IconThemeData(color: Colors.white),
              leading: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_ios),
                color: Colors.white,
                tooltip: 'Voltar',
              ),
              backgroundColor: Colors.green[700],
              centerTitle: true,
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.videos[_currentIndex].title,
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
                    tooltip: _showList ? 'Fechar lista' : 'Mostrar lista',
                    onPressed: () {
                      if (_isScreenLocked) return;
                      setState(() => _showList = !_showList);
                    },
                  ),
              ],
            ),
            body: Column(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      player,
                      if (!isFullScreen) _buildPlayerGestureLayer(),
                      if (!isFullScreen && _showBackward)
                        const Positioned(
                          left: 50,
                          child: Icon(
                            Icons.replay_10,
                            size: AppConstants.skipIconSize,
                            color: Colors.white,
                          ),
                        ),
                      if (!isFullScreen && _showForward)
                        const Positioned(
                          right: 50,
                          child: Icon(
                            Icons.forward_10,
                            size: AppConstants.skipIconSize,
                            color: Colors.white,
                          ),
                        ),
                      if (!isFullScreen && _showGestureFeedback)
                        _buildGestureFeedbackOverlay(),
                    ],
                  ),
                ),
                Expanded(child: _buildVideoList()),
              ],
            ),
          ),
        ),
        if (isLandscape) ...[
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            child: AnimatedContainer(
              duration: AppConstants.landscapeListAnimation,
              curve: Curves.easeInOut,
              width: (_showList && !_isScreenLocked)
                  ? MediaQuery.of(context).size.width *
                      AppConstants.landscapeListWidthFraction
                  : 0,
              height: MediaQuery.of(context).size.height,
              child: Material(
                color: Colors.white,
                child: Container(
                  color: Colors.green[800],
                  child: _buildVideoListToFullscren(),
                ),
              ),
            ),
          ),
          // Overlay para capturar o Drag
          Positioned.fill(
            child: GestureDetector(
              onHorizontalDragStart: (details) {
                if (isFullScreen && _isScreenLocked) return;
                // Guarda a posição inicial do toque
                _dragStartX = details.globalPosition.dx;
              },
              onHorizontalDragUpdate: (details) {
                if (isFullScreen && _isScreenLocked) return;
                // Atualiza a posição final
                _dragUpdateX = details.globalPosition.dx;
              },
              onHorizontalDragEnd: (details) {
                if (isFullScreen && _isScreenLocked) return;
                final screenWidth = MediaQuery.of(context).size.width;

                // Se arrastou da direita (últimos 20% da tela) para o centro → abre
                if (_dragStartX >
                        screenWidth * AppConstants.dragThresholdFraction &&
                    _dragUpdateX < _dragStartX) {
                  setState(() {
                    _showList = true;
                  });
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    scrollToIndex(_currentIndex,
                        itemHeight: AppConstants.fullscreenListItemHeight);
                  });
                }

                // Se arrastou do centro para a direita → fecha
                else if (_dragStartX <
                        screenWidth * AppConstants.dragThresholdFraction &&
                    _dragUpdateX > _dragStartX) {
                  setState(() {
                    _showList = false;
                  });
                }
              },
            ),
          ),
        ],
        if (isFullScreen) ...[
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) => _toggleUnlockButtonVisibility(),
              child: const SizedBox.expand(),
            ),
          ),
          if (!_isScreenLocked)
            _buildPlayerGestureLayer(
              rightInset:
                  _showList ? MediaQuery.of(context).size.width * 0.25 : 0,
            ),
          if (!_isScreenLocked && _showBackward)
            Positioned.fill(
              left: 120,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Icon(
                  Icons.replay_10,
                  size: 80,
                  color: Colors.white,
                ),
              ),
            ),
          if (!_isScreenLocked && _showForward)
            Positioned.fill(
              right: 120,
              child: Align(
                alignment: Alignment.centerRight,
                child: Icon(
                  Icons.forward_10,
                  size: 80,
                  color: Colors.white,
                ),
              ),
            ),
          if (!_isScreenLocked && _showGestureFeedback)
            _buildGestureFeedbackOverlay(),
          if (_isScreenLocked)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggleUnlockButtonVisibility,
                child: Container(color: Colors.transparent),
              ),
            ),
          if (isFullScreen)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !_showUnlockButton,
                child: AnimatedOpacity(
                  opacity: _showUnlockButton ? 1 : 0,
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOut,
                  child: AnimatedSlide(
                    offset: _showUnlockButton
                        ? Offset.zero
                        : (_isScreenLocked
                            ? const Offset(0, 0.08)
                            : const Offset(-0.1, 0)),
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOut,
                    child: Align(
                      alignment: _isScreenLocked
                          ? const Alignment(0, 0.5)
                          : Alignment.topLeft,
                      child: Padding(
                        padding: _isScreenLocked
                            ? EdgeInsets.zero
                            : EdgeInsets.only(
                                left: 12,
                                top: MediaQuery.of(context).padding.top + 62,
                              ),
                        child:
                            _buildFullscreenLockButton(locked: _isScreenLocked),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ]
      ],
    );
  }

  // ======== Video Listas ========
  Widget _buildVideoListToFullscren() {
    final firebaseVideoListProvider =
        Provider.of<FirebaseVideoListProvider>(context, listen: false);

    return ReorderableListView.builder(
      scrollController: _scrollController,
      buildDefaultDragHandles: false,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex -= 1;
          final video = widget.videos.removeAt(oldIndex);
          widget.videos.insert(newIndex, video);

          if (_currentIndex == oldIndex) {
            _currentIndex = newIndex;
          } else if (oldIndex < _currentIndex && newIndex >= _currentIndex) {
            _currentIndex -= 1;
          } else if (oldIndex > _currentIndex && newIndex <= _currentIndex) {
            _currentIndex += 1;
          }

          final key = _itemKeys.removeAt(oldIndex);
          _itemKeys.insert(newIndex, key);

          firebaseVideoListProvider.updateVideoOrder(
            listId: widget.listId,
            newOrder: widget.videos,
          );
        });
      },
      itemCount: widget.videos.length,
      itemBuilder: (context, index) {
        final video = widget.videos[index];
        final isPlaying = index == _currentIndex;

        return KeyedSubtree(
          key: _itemKeys[index],
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              final offsetAnimation =
                  Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero)
                      .animate(animation);
              return SlideTransition(
                position: offsetAnimation,
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: InkWell(
              onTap: () {
                if (!isPlaying) _playVideo(index);
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
                              bottom: 4,
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
          final video = widget.videos.removeAt(oldIndex);
          widget.videos.insert(newIndex, video);

          if (_currentIndex == oldIndex) {
            _currentIndex = newIndex;
          } else if (oldIndex < _currentIndex && newIndex >= _currentIndex) {
            _currentIndex -= 1;
          } else if (oldIndex > _currentIndex && newIndex <= _currentIndex) {
            _currentIndex += 1;
          }

          final key = _itemKeys.removeAt(oldIndex);
          _itemKeys.insert(newIndex, key);
        });
      },
      itemCount: widget.videos.length,
      itemBuilder: (context, index) {
        final video = widget.videos[index];

        return KeyedSubtree(
          key: _itemKeys[index],
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade400, width: 0.5),
              ),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              selected: index == _currentIndex,
              selectedTileColor: Colors.green[800],
              leading: ReorderableDragStartListener(
                index: index,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
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
                      width: 100,
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              video.thumbnailUrl,
                              height: 60,
                              width: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          if (_currentIndex == index)
                            Positioned(
                              bottom: 4,
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
                if (_currentIndex != index) _playVideo(index);
              },
            ),
          ),
        );
      },
    );
  }
}
