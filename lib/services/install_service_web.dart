import 'dart:js_interop';

@JS('_wbIsStandalone')
external bool _isStandalone();

@JS('_wbHasPrompt')
external bool _hasPrompt();

@JS('_wbPromptInstall')
external bool _promptInstall();

/// Versão web: consulta os helpers de instalação PWA definidos em
/// web/flutter_bootstrap.js. Toda falha responde "não" — o card só
/// aparece quando dá para confiar no sinal.
class InstallService {
  static bool get supported => true;

  /// Já está rodando como app instalado (tela cheia standalone)?
  static bool get isStandalone {
    try {
      return _isStandalone();
    } catch (_) {
      return false;
    }
  }

  /// O navegador ofereceu o prompt nativo de instalação (Android/Chrome)?
  static bool get hasPrompt {
    try {
      return _hasPrompt();
    } catch (_) {
      return false;
    }
  }

  /// Dispara o prompt nativo. true = prompt aberto.
  static bool promptInstall() {
    try {
      return _promptInstall();
    } catch (_) {
      return false;
    }
  }
}
