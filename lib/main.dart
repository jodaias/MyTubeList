import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:my_tube_list/models/video_list_model.dart';
import 'package:my_tube_list/pages/videos_page.dart';
// import 'package:my_tube_list/providers/video_list_provider.dart';
import 'package:provider/provider.dart';
import 'package:my_tube_list/models/profile_model.dart';
import 'package:my_tube_list/pages/splash_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'models/video_model.dart';
// import 'providers/profile_provider.dart';
// import 'providers/video_provider.dart';
import 'providers/firebase_profile_provider.dart';
import 'providers/firebase_video_list_provider.dart';
import 'providers/firebase_video_provider.dart';
import 'providers/local_profiles_provider.dart';
// import 'providers/profile_provider.dart';
// import 'providers/video_list_provider.dart';
// import 'providers/video_provider.dart';

import 'pages/home_page.dart';
import 'pages/player_page.dart';
import 'pages/profiles_page.dart';
import 'pages/search_page.dart';
import 'pages/auth_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carregar variáveis de ambiente
  await dotenv.load(fileName: ".env");

  // Inicializar Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Se já foi inicializado, não faz nada
  }

  // Inicializar Hive
  await Hive.initFlutter();
  Hive.registerAdapter(VideoModelAdapter());
  Hive.registerAdapter(ProfileModelAdapter());
  Hive.registerAdapter(VideoListModelAdapter());

  final firebaseProfileProvider = FirebaseProfileProvider();
  final firebaseVideoListProvider = FirebaseVideoListProvider();
  final firebaseVideoProvider = FirebaseVideoProvider();
  final localProfilesProvider = LocalProfilesProvider();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => firebaseProfileProvider),
        ChangeNotifierProvider(create: (_) => firebaseVideoListProvider),
        ChangeNotifierProvider(create: (_) => firebaseVideoProvider),
        ChangeNotifierProvider(create: (_) => localProfilesProvider),
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
        '/auth': (_) => const AuthPage(),
        '/profiles': (_) => const ProfilesPage(),
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
