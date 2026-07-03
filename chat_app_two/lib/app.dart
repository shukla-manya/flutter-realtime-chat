import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/chat_provider.dart';
import 'screens/splash_screen.dart';

class NovaChatApp extends StatelessWidget {
  const NovaChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatProvider(),
      child: MaterialApp(
        title: 'NovaChat AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        home: const SplashScreen(),
      ),
    );
  }
}
