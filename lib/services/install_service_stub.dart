/// Versão nativa (APK/desktop): app instalado por definição — o card de
/// instalação nunca aparece.
class InstallService {
  static bool get supported => false;
  static bool get isStandalone => true;
  static bool get hasPrompt => false;
  static bool promptInstall() => false;
}
