import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
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

  final profileProvider = ProfileProvider();
  await profileProvider.init();

  final videoProvider = VideoProvider();
  await videoProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => profileProvider),
        ChangeNotifierProvider(create: (_) => videoProvider),
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
        '/search': (_) => const SearchPage(),
        '/player': (context) {
          final video =
              ModalRoute.of(context)!.settings.arguments as VideoModel;

          // providers
          final videoProvider =
              Provider.of<VideoProvider>(context, listen: false);
          final profileProvider =
              Provider.of<ProfileProvider>(context, listen: false);

          final allowedVideos = videoProvider.getAllowedVideos(profileProvider);

          final index = allowedVideos.indexWhere((v) => v.id == video.id);

          return PlayerPage(
            allowedVideos: allowedVideos,
            initialIndex: index >= 0 ? index : 0,
          );
        },
      },
    );
  }
}
