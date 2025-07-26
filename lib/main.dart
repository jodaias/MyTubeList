import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:my_tube_list/models/video_list_model.dart';
import 'package:my_tube_list/pages/videos_page.dart';
import 'package:my_tube_list/providers/video_list_provider.dart';
import 'package:provider/provider.dart';
import 'package:my_tube_list/models/profile_model.dart';
import 'package:my_tube_list/pages/splash_page.dart';

import 'models/video_model.dart';
import 'providers/profile_provider.dart';
import 'providers/video_provider.dart';

import 'pages/home_page.dart';
import 'pages/player_page.dart';
import 'pages/profile_page.dart';
import 'pages/search_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carregar variáveis de ambiente
  await dotenv.load(fileName: ".env");

  // Inicializar Hive
  await Hive.initFlutter();
  Hive.registerAdapter(VideoModelAdapter());
  Hive.registerAdapter(ProfileModelAdapter());
  Hive.registerAdapter(VideoListModelAdapter());

  final profileProvider = ProfileProvider();
  await profileProvider.init();

  final videoProvider = VideoProvider();
  await videoProvider.init();

  final videoListProvider = VideoListProvider();
  await videoListProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => profileProvider),
        ChangeNotifierProvider(create: (_) => videoProvider),
        ChangeNotifierProvider(create: (_) => videoListProvider),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Tube List',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashPage(),
        '/profile': (_) => const ProfilePage(),
        '/home': (_) => const HomePage(),
        '/search': (context) {
          final listId = ModalRoute.of(context)!.settings.arguments as String;
          return SearchPage(listId: listId);
        },
        '/player': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;

          final String listId = args['listId'];
          final int currentIndex = args['currentIndex'] ?? 0;
          final List<VideoModel> videos = args['videos'];

          return PlayerPage(
            listId: listId,
            videos: videos,
            currentIndex: currentIndex,
          );
        },
        '/videos': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;

          final String listId = args['listId'];

          return VideosPage(
            listId: listId,
          );
        },
      },
    );
  }
}
