// Links para as páginas estáticas do site, com implementação por
// plataforma (mesmo padrão do install_service): web abre em nova aba;
// nativo esconde os links.
export 'web_links_stub.dart'
    if (dart.library.js_interop) 'web_links_web.dart';
