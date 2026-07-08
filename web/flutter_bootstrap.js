{{flutter_js}}
{{flutter_build_config}}

// Alguns navegadores (forks do Chromium como o Comet, ou aceleração de
// hardware desligada) ficam SEM WebGL — o CanvasKit então mostra tela
// preta mesmo com o app rodando (a música toca, nada aparece).
// Detecta antes de iniciar: sem WebGL, força renderização por CPU
// (mais lenta, mas visível) e avisa o jogador.
var _wbGl = null;
try {
  var _wbCanvas = document.createElement('canvas');
  _wbGl = _wbCanvas.getContext('webgl2') || _wbCanvas.getContext('webgl');
} catch (e) {}

if (!_wbGl) {
  var _wbBanner = document.createElement('div');
  _wbBanner.style.cssText =
    'position:fixed;top:0;left:0;right:0;z-index:9999;' +
    'background:#7A1B2E;color:#fff;font:13px/1.4 sans-serif;' +
    'padding:8px 12px;text-align:center';
  _wbBanner.textContent =
    'Seu navegador está sem aceleração gráfica (WebGL) — o jogo vai ' +
    'rodar em modo lento. Para a melhor experiência, abra no Chrome.';
  document.body.appendChild(_wbBanner);
  setTimeout(function () { _wbBanner.remove(); }, 12000);
}

// ---- Instalação PWA (o app Flutter consulta via js_interop) ----
// Android/Chrome: captura o beforeinstallprompt para o card INSTALAR
// dentro do jogo disparar o prompt nativo. iOS não tem prompt (o card
// vira instrução de "Adicionar à Tela de Início").
window._wbInstallEvt = null;
window.addEventListener('beforeinstallprompt', function (e) {
  e.preventDefault();
  window._wbInstallEvt = e;
});
window._wbHasPrompt = function () { return !!window._wbInstallEvt; };
window._wbPromptInstall = function () {
  var e = window._wbInstallEvt;
  if (!e) return false;
  window._wbInstallEvt = null;
  e.prompt();
  return true;
};
window._wbIsStandalone = function () {
  return (window.matchMedia &&
    window.matchMedia('(display-mode: standalone)').matches) ||
    window.navigator.standalone === true;
};

_flutter.loader.load({
  // Service worker: cacheia o jogo (funciona offline depois da 1ª visita)
  // e é o que permite INSTALAR como app pela engrenagem do Chrome (PWA).
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}},
  },
  config: {
    canvasKitForceCpuOnly: !_wbGl,
  },
});
