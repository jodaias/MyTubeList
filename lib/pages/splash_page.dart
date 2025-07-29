import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/firebase_profile_provider.dart';
import '../providers/firebase_video_list_provider.dart'; // Added import for FirebaseVideoListProvider

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();

    // Verificar se usuário está logado após 3 segundos
    Future.delayed(const Duration(seconds: 3), () async {
      final firebaseProvider = context.read<FirebaseProfileProvider>();

      try {
        await firebaseProvider.checkAuthStatus();
        if (firebaseProvider.isAuthenticated) {
          // Carregar listas de vídeos do Firebase
          final firebaseVideoListProvider =
              context.read<FirebaseVideoListProvider>();
          await firebaseVideoListProvider.loadVideoLists();

          // Redirecionar para a página inicial
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          // Redirecionar para a página de perfis
          Navigator.of(context).pushReplacementNamed('/profiles');
        }
      } catch (e) {
        // Continua mesmo com erro do Firebase
        Navigator.of(context).pushReplacementNamed('/profiles');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/mytubelist_logo.png',
                width: 120,
              ),
              const SizedBox(height: 16),
              Text(
                'MyTubeList',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.onPrimary),
              )
            ],
          ),
        ),
      ),
    );
  }
}
