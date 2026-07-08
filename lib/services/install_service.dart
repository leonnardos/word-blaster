// Detecção/disparo de instalação do PWA, com implementação por
// plataforma: web consulta o navegador; nativo (APK) responde
// "já instalado" e o card nunca aparece.
export 'install_service_stub.dart'
    if (dart.library.js_interop) 'install_service_web.dart';
