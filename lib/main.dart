import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/screen_size.dart';
import 'screens/menu_screen.dart';
import 'services/ads_service.dart';
import 'services/progress_service.dart';
import 'services/sound_service.dart';
import 'services/tts_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  await ProgressService.init();
  await TtsService.init();
  await SoundService.init();
  await AdsService.init();
  runApp(const WordBlasterApp());
}

class WordBlasterApp extends StatelessWidget {
  const WordBlasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Word Blaster',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF070B14),
        fontFamily: 'monospace',
        useMaterial3: true,
      ),
      // Moldura de tamanho de tela (média/mobile): limita a largura do app
      // inteiro e centraliza — as laterais escuras são o espaço reservado
      // para os anúncios no desktop/web. Num celular estreito não muda nada.
      builder: (context, child) => ValueListenableBuilder<ScreenSize>(
        valueListenable: screenSizeNotifier,
        builder: (_, size, __) => ColoredBox(
          color: const Color(0xFF02040A),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: size.maxWidth),
              child: child,
            ),
          ),
        ),
      ),
      home: const MenuScreen(),
    );
  }
}
