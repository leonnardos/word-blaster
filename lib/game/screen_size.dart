import 'package:flutter/foundation.dart';

/// Largura da área de jogo no desktop/web. Sempre limitada (MÉDIA ou
/// MOBILE): as faixas laterais que sobram são o espaço dos anúncios,
/// como no ZType — e o jogo nunca fica esparramado num monitor largo.
enum ScreenSize {
  medium(label: 'MÉDIA', maxWidth: 720),
  mobile(label: 'MOBILE', maxWidth: 430);

  const ScreenSize({required this.label, required this.maxWidth});

  final String label;
  final double maxWidth;
}

/// Ouvido pelo builder do MaterialApp: trocar o valor redimensiona o app
/// inteiro (menu e jogo) imediatamente.
final screenSizeNotifier = ValueNotifier<ScreenSize>(ScreenSize.medium);

/// Num celular a moldura não muda nada (a tela já é estreita) — o seletor
/// só existe onde faz diferença: web e desktop.
bool get isScreenSizeSelectorAvailable =>
    kIsWeb ||
    defaultTargetPlatform == TargetPlatform.windows ||
    defaultTargetPlatform == TargetPlatform.linux ||
    defaultTargetPlatform == TargetPlatform.macOS;
