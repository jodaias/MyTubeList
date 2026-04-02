import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityBanner extends StatefulWidget {
  final Widget child;

  const ConnectivityBanner({Key? key, required this.child}) : super(key: key);

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  late StreamSubscription<List<ConnectivityResult>> _subscription;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      final offline = results.every((r) => r == ConnectivityResult.none);
      if (offline != _isOffline) {
        setState(() => _isOffline = offline);
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_isOffline)
          MaterialBanner(
            content: const Text(
              'Sem conexão com a internet',
              style: TextStyle(color: Colors.white),
            ),
            leading: const Icon(Icons.wifi_off, color: Colors.white),
            backgroundColor: Colors.red.shade700,
            actions: [
              TextButton(
                onPressed: () async {
                  final results = await Connectivity().checkConnectivity();
                  final offline =
                      results.every((r) => r == ConnectivityResult.none);
                  setState(() => _isOffline = offline);
                },
                child: const Text('Tentar novamente',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}
