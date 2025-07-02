///////////////////// opção 1 ////////////////////////

// import 'package:flutter/material.dart';
// import 'package:youtube_player_flutter/youtube_player_flutter.dart';
// import '../models/video_model.dart';

// class PlayerPage extends StatefulWidget {
//   final List<VideoModel> allowedVideos;
//   final int initialIndex;

//   const PlayerPage({
//     Key? key,
//     required this.allowedVideos,
//     required this.initialIndex,
//   }) : super(key: key);

//   @override
//   State<PlayerPage> createState() => _PlayerPageState();
// }

// class _PlayerPageState extends State<PlayerPage> {
//   late YoutubePlayerController _controller;
//   late int _currentIndex;
//   bool _isPlayerReady = false;
//   // late PlayerState _playerState;
//   late YoutubeMetaData _videoMetaData;
//   // double _volume = 100;
//   bool _muted = false;

//   @override
//   void initState() {
//     super.initState();
//     _currentIndex = widget.initialIndex;
//     _setupController();
//   }

//   void _setupController() {
//     final videoId = widget.allowedVideos[_currentIndex].id;
//     _controller = YoutubePlayerController(
//       initialVideoId: videoId,
//       flags: const YoutubePlayerFlags(
//         autoPlay: true,
//         mute: false,
//         hideControls: false,
//         controlsVisibleAtStart: false,
//         enableCaption: false,
//         disableDragSeek: true,
//       ),
//     )..addListener(() {
//         if (_isPlayerReady && mounted) {
//           setState(() {
//             // _playerState = _controller.value.playerState;
//             _videoMetaData = _controller.metadata;
//           });
//         }
//       });
//     _videoMetaData = const YoutubeMetaData();
//     // _playerState = PlayerState.unknown;
//   }

//   void _playVideo(int index) {
//     setState(() {
//       _currentIndex = index;
//       _controller.load(widget.allowedVideos[_currentIndex].id);
//     });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return YoutubePlayerBuilder(
//       player: YoutubePlayer(
//         controller: _controller,
//         showVideoProgressIndicator: true,
//         progressIndicatorColor: Colors.blueAccent,
//         onReady: () {
//           _isPlayerReady = true;
//         },
//         onEnded: (data) {
//           _playVideo((_currentIndex + 1) % widget.allowedVideos.length);
//         },
//       ),
//       builder: (context, player) => Scaffold(
//         appBar: AppBar(
//           title: Text(widget.allowedVideos[_currentIndex].title),
//         ),
//         body: Column(
//           children: [
//             player,
//             _buildControls(),
//             const Divider(),
//             Expanded(
//               child: _buildVideoList(),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildControls() {
//     return Column(
//       children: [
//         Text(
//           _videoMetaData.title,
//           style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
//         ),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//           children: [
//             IconButton(
//               icon: const Icon(Icons.skip_previous),
//               onPressed: _currentIndex > 0
//                   ? () => _playVideo(_currentIndex - 1)
//                   : null,
//             ),
//             IconButton(
//               icon: Icon(
//                 _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
//               ),
//               onPressed: _isPlayerReady
//                   ? () {
//                       _controller.value.isPlaying
//                           ? _controller.pause()
//                           : _controller.play();
//                       setState(() {});
//                     }
//                   : null,
//             ),
//             IconButton(
//               icon: Icon(_muted ? Icons.volume_off : Icons.volume_up),
//               onPressed: _isPlayerReady
//                   ? () {
//                       _muted ? _controller.unMute() : _controller.mute();
//                       setState(() {
//                         _muted = !_muted;
//                       });
//                     }
//                   : null,
//             ),
//             IconButton(
//               icon: const Icon(Icons.skip_next),
//               onPressed: _currentIndex < widget.allowedVideos.length - 1
//                   ? () => _playVideo(_currentIndex + 1)
//                   : null,
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildVideoList() {
//     return ListView.builder(
//       scrollDirection: Axis.horizontal,
//       itemCount: widget.allowedVideos.length,
//       itemBuilder: (context, index) {
//         final video = widget.allowedVideos[index];
//         return GestureDetector(
//           onTap: () => _playVideo(index),
//           child: Container(
//             width: 150,
//             margin: const EdgeInsets.all(8),
//             child: Column(
//               children: [
//                 AspectRatio(
//                   aspectRatio: 16 / 9,
//                   child: Image.network(video.thumbnailUrl, fit: BoxFit.cover),
//                 ),
//                 Text(
//                   video.title,
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

/////////// opção 2 ///////////////////////////////////////////

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:my_tube_list/providers/video_provider.dart';
// import 'package:my_tube_list/utils/confirmation_modal.dart';
// import 'package:provider/provider.dart';
// import 'package:youtube_player_flutter/youtube_player_flutter.dart';

// import '../models/video_model.dart';
// import 'full_screen_player_page.dart';

// class PlayerPage extends StatefulWidget {
//   final List<VideoModel> allowedVideos;
//   final int initialIndex;

//   const PlayerPage({
//     Key? key,
//     required this.allowedVideos,
//     required this.initialIndex,
//   }) : super(key: key);

//   @override
//   State<PlayerPage> createState() => _PlayerPageState();
// }

// class _PlayerPageState extends State<PlayerPage> {
//   // late YoutubePlayerController _controller;
//   late VideoProvider _videoProvider;
//   // late int _currentIndex;

//   @override
//   void initState() {
//     super.initState();

//     _videoProvider = Provider.of<VideoProvider>(context, listen: false);
//     _videoProvider.setCurrentIndex(widget.initialIndex);
//     _videoProvider.setAllowedVideos(widget.allowedVideos);
//     _videoProvider.initializeController();
//     _videoProvider.controller!.addListener(_videoListener);

//     // _controller = YoutubePlayerController(
//     //   initialVideoId: widget.allowedVideos[_currentIndex].id,
//     //   flags: YoutubePlayerFlags(
//     //     autoPlay: true,
//     //     mute: false,
//     //     hideControls: false,
//     //     controlsVisibleAtStart: false,
//     //     enableCaption: false,
//     //     disableDragSeek: true,
//     //     showLiveFullscreenButton: false,
//     //   ),
//     // );
//   }

//   void _videoListener() {
//     if (_videoProvider.controller != null) {
//       final isEnded =
//           _videoProvider.controller!.value.playerState == PlayerState.ended;

//       if (isEnded) {
//         _loadNextVideo();
//       }
//     }
//   }

//   void _loadVideo(int index) {
//     if (_videoProvider.currentIndex == index) return;
//     setState(() {
//       _videoProvider.setCurrentIndex(index);
//       _videoProvider.controller!
//           .load(_videoProvider.allowedVideos[_videoProvider.currentIndex].id);
//       _videoProvider.notifyListeners2();
//     });
//   }

//   void _loadNextVideo() {
//     final currentIndex = _videoProvider.allowedVideos
//         .indexWhere((v) => v.id == _videoProvider.controller?.initialVideoId);

//     final nextIndex = (currentIndex + 1) % _videoProvider.allowedVideos.length;
//     _loadVideo(nextIndex);
//   }

//   @override
//   void dispose() {
//     super.dispose();
//   }

//   Future<void> _onPopInvoked(bool didPop, _) async {
//     if (didPop) return;

//     final shouldExit = await showExitConfirmationDialog(context);
//     if (shouldExit) {
//       _videoProvider.disposeController();
//       Navigator.of(context).pop();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isLandscape =
//         MediaQuery.of(context).orientation == Orientation.landscape;

//     return PopScope(
//       onPopInvokedWithResult: _onPopInvoked,
//       child: Scaffold(
//         backgroundColor: Colors.green[900],
//         appBar: AppBar(
//           leading: IconButton(
//             onPressed: () {
//               _videoProvider.disposeController();
//               Navigator.of(context).pop();
//             },
//             icon: Icon(Icons.menu),
//             color: Colors.white,
//           ),
//           backgroundColor: Colors.green[700],
//           centerTitle: true,
//           title: Text(
//             'Player de Video',
//             style: const TextStyle(color: Colors.white),
//           ),
//           systemOverlayStyle: SystemUiOverlayStyle.light,
//         ),
//         body: Column(
//           children: [
//             AspectRatio(
//               aspectRatio: 16 / 9,
//               child: YoutubePlayer(
//                 controller: _videoProvider.controller!,
//                 showVideoProgressIndicator: true,
//                 controlsTimeOut: Duration(seconds: 2),
//                 bottomActions: [
//                   CurrentPosition(),
//                   ProgressBar(isExpanded: true),
//                   RemainingDuration(),
//                   IconButton(
//                     icon: const Icon(
//                       Icons.fullscreen,
//                       color: Colors.white,
//                     ),
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => FullScreenPlayerPage(
//                               // allowedVideos: _videoProvider.allowedVideos,
//                               // initialIndex: _videoProvider.currentIndex,
//                               ),
//                         ),
//                       );

//                       // if (position != null) {
//                       //   _videoProvider.seekTo(Duration(seconds: position));

//                       //   _videoProvider.play();
//                       // }
//                     },
//                   )
//                 ],
//                 progressIndicatorColor: Colors.greenAccent,
//               ),
//             ),
//             if (!isLandscape)
//               Expanded(
//                 child: ListView.builder(
//                   itemCount: widget.allowedVideos.length,
//                   itemBuilder: (context, index) {
//                     final video = widget.allowedVideos[index];
//                     return ListTile(
//                       selected: index == _videoProvider.currentIndex,
//                       selectedTileColor: Colors.green[800],
//                       contentPadding: const EdgeInsets.symmetric(
//                           vertical: 8, horizontal: 16),
//                       leading: SizedBox(
//                         width: 100,
//                         height: 56, // altura típica de thumbnail no YouTube
//                         child: ClipRRect(
//                           borderRadius: BorderRadius.circular(8),
//                           child: Image.network(
//                             video.thumbnailUrl,
//                             fit: BoxFit.cover,
//                           ),
//                         ),
//                       ),
//                       title: Text(
//                         video.title,
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                         style: const TextStyle(color: Colors.white),
//                       ),
//                       onTap: () {
//                         _loadVideo(index);
//                       },
//                     );
//                   },
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// 3 opção
import 'package:flutter/material.dart';
import 'package:my_tube_list/pages/full_screen_player_page.dart';
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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    _setupController();
  }

  void _setupController() {
    _videoProvider = Provider.of<VideoProvider>(context, listen: false);
    _videoProvider.setAllowedVideos(widget.allowedVideos);
    final video = widget.allowedVideos[_currentIndex];

    _controller = _controller = YoutubePlayerController(
      initialVideoId: video.id,
      flags: YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        hideControls: false,
        controlsVisibleAtStart: false,
        enableCaption: false,
        disableDragSeek: true,
        showLiveFullscreenButton: false,
      ),
    );
  }

  void _playVideo(int index, {int startAt = 0}) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
      _controller.load(widget.allowedVideos[_currentIndex].id,
          startAt: startAt);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.blueAccent,
        bottomActions: [
          CurrentPosition(),
          ProgressBar(isExpanded: true),
          RemainingDuration(),
          IconButton(
            icon: const Icon(
              Icons.fullscreen,
              color: Colors.white,
            ),
            onPressed: () async {
              final result = await Navigator.push<String>(
                context,
                MaterialPageRoute(
                  builder: (context) => FullScreenPlayerPage(
                    initialIndex: _currentIndex,
                    controller: _controller,
                  ),
                ),
              );

              if (result != null) {
                final index = int.tryParse(result.split("|")[0]) ?? 0;
                final positionInSeconds =
                    int.tryParse(result.split("|")[1]) ?? 0;

                _playVideo(index, startAt: positionInSeconds);
                _controller.play();
              }
            },
          )
        ],
        onEnded: (data) {
          final nextIndex = (_currentIndex + 1) % widget.allowedVideos.length;
          _playVideo(nextIndex);
        },
      ),
      builder: (context, player) => Scaffold(
        appBar: AppBar(
          title: Text(widget.allowedVideos[_currentIndex].title),
        ),
        body: Column(
          children: [
            player,
            Expanded(
              child: ListView.builder(
                itemCount: widget.allowedVideos.length,
                itemBuilder: (context, index) {
                  final video = widget.allowedVideos[index];
                  return ListTile(
                    selected: index == _currentIndex,
                    selectedTileColor: Colors.green[800],
                    leading: SizedBox(
                      width: 100,
                      height: 56,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          video.thumbnailUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    title: Text(
                      video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: index == _currentIndex
                              ? Colors.white
                              : Colors.black),
                    ),
                    onTap: () => _playVideo(index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
