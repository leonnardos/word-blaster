import 'dart:js_interop';

@JS('window.open')
external JSAny? _windowOpen(JSString url, JSString target);

/// Versão web: abre as páginas estáticas do site (privacidade, como jogar)
/// em outra aba — o jogo continua aberto.
class WebLinks {
  static const bool available = true;

  static void open(String path) {
    try {
      _windowOpen(path.toJS, '_blank'.toJS);
    } catch (_) {}
  }
}
