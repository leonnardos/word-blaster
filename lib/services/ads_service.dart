import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Anúncios AdMob — SÓ no celular (Android/iOS) e SÓ fora da partida.
/// Banner no menu; nunca durante o jogo (PLANO §5: monetização que não
/// atrapalha; o próximo passo é anúncio recompensado, não mais banners).
///
/// Os IDs abaixo são os de TESTE oficiais do Google: mostram anúncios de
/// demonstração e podem ser usados à vontade. Antes de publicar na loja,
/// crie sua conta em admob.google.com e troque pelos IDs reais — clicar em
/// anúncio real no próprio app dá banimento da conta.
class AdsService {
  static bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static bool _ready = false;

  static bool get isReady => _ready;

  static Future<void> init() async {
    if (!supported) return;
    try {
      await MobileAds.instance.initialize();
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  /// Unidade de banner (TESTE). Troque pela sua unidade real ao publicar.
  static String get bannerUnitId =>
      defaultTargetPlatform == TargetPlatform.android
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2934735716';
}
