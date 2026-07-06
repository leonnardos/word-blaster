// Gera os efeitos sonoros do jogo sinteticamente (sem depender de arquivos
// externos com licença desconhecida). Rodar com: dart run tool/gen_sounds.dart
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const sampleRate = 44100;

void main() {
  writeWav('assets/audio/explosion.wav', explosion());
  writeWav('assets/audio/error.wav', errorBuzz());
  writeWav('assets/audio/war_theme.wav', warTheme());
}

/// Trilha de guerra em loop (~10,7s): tambores taiko + drone menor grave.
/// Os graves escrevem com wrap (módulo n) e o drone usa frequências com
/// ciclos inteiros na duração — o loop fecha sem estalo.
Float64List warTheme() {
  const bpm = 90.0;
  const beat = 60 / bpm;
  const bars = 4;
  final dur = beat * 4 * bars;
  final n = (sampleRate * dur).round();
  final samples = Float64List(n);

  void addBoom(double t0, {double amp = 1}) {
    final start = (t0 * sampleRate).round();
    final len = (0.55 * sampleRate).round();
    final rnd = Random(start);
    for (var i = 0; i < len; i++) {
      final t = i / sampleRate;
      final freq = 60 * exp(-3 * t) + 38;
      final body = sin(2 * pi * freq * t) * exp(-6 * t);
      final thump = (rnd.nextDouble() * 2 - 1) * exp(-70 * t) * 0.4;
      samples[(start + i) % n] += (body + thump) * 0.85 * amp;
    }
  }

  void addTom(double t0, {double amp = 1}) {
    final start = (t0 * sampleRate).round();
    final len = (0.28 * sampleRate).round();
    for (var i = 0; i < len; i++) {
      final t = i / sampleRate;
      final freq = 135 * exp(-4 * t) + 72;
      samples[(start + i) % n] += sin(2 * pi * freq * t) * exp(-13 * t) * 0.5 * amp;
    }
  }

  // Padrão de marcha: BOOM ... tom tom BOOM . tom (varia por compasso).
  for (var bar = 0; bar < bars; bar++) {
    final b0 = bar * 4 * beat;
    addBoom(b0);
    addTom(b0 + 1.5 * beat, amp: 0.8);
    addTom(b0 + 2 * beat, amp: 0.6);
    addBoom(b0 + 2.5 * beat, amp: 0.9);
    addTom(b0 + 3.5 * beat, amp: 0.7);
    if (bar.isOdd) addTom(b0 + 3.75 * beat, amp: 0.55);
  }

  // Drone em lá menor (A1, E2, C3) com tremolo lento.
  double loopFreq(double f) => (f * dur).roundToDouble() / dur;
  final freqs = [loopFreq(55), loopFreq(82.41), loopFreq(130.81)];
  final tremFreq = loopFreq(0.25);
  for (var i = 0; i < n; i++) {
    final t = i / sampleRate;
    var drone = 0.0;
    for (final f in freqs) {
      drone += sin(2 * pi * f * t) +
          0.35 * sin(2 * pi * f * 2 * t) +
          0.15 * sin(2 * pi * f * 3 * t);
    }
    samples[i] +=
        drone / 3 * 0.11 * (0.72 + 0.28 * sin(2 * pi * tremFreq * t));
  }

  var peak = 0.0;
  for (final v in samples) {
    peak = max(peak, v.abs());
  }
  final scale = 0.8 / peak;
  for (var i = 0; i < n; i++) {
    samples[i] *= scale;
  }
  return samples;
}

/// Erro de digitação: buzz curto, grave e descendente — inconfundível de
/// "errado", mas discreto o bastante para tocar a cada tecla errada.
Float64List errorBuzz() {
  const dur = 0.16;
  final n = (sampleRate * dur).round();
  final samples = Float64List(n);
  for (var i = 0; i < n; i++) {
    final t = i / sampleRate;
    final freq = 220 - 80 * (t / dur); // desce 220 → 140 Hz
    final phase = 2 * pi * freq * t;
    final square = sin(phase) > 0 ? 1.0 : -1.0; // timbre "errado"
    final smooth = sin(phase);
    samples[i] = (square * 0.35 + smooth * 0.3) * exp(-10 * t);
  }
  final fade = (sampleRate * 0.005).round();
  for (var i = 0; i < fade; i++) {
    samples[i] *= i / fade;
    samples[n - 1 - i] *= i / fade;
  }
  return samples;
}

/// Estouro de perder vida: estalo de ruído + ronco grave decaindo.
Float64List explosion() {
  const dur = 0.7;
  final n = (sampleRate * dur).round();
  final rnd = Random(42);
  final samples = Float64List(n);
  var lowpass = 0.0;
  for (var i = 0; i < n; i++) {
    final t = i / sampleRate;
    final noise = rnd.nextDouble() * 2 - 1;
    lowpass += 0.22 * (noise - lowpass);
    final crack = lowpass * exp(-9 * t) * 1.6;
    final rumble = sin(2 * pi * (70 - 30 * t) * t) * exp(-5 * t) * 0.8;
    final punch = sin(2 * pi * 160 * t) * exp(-25 * t) * 0.6;
    samples[i] = (crack + rumble + punch).clamp(-1.0, 1.0);
  }
  // Fade nas pontas para não estalar no play/stop.
  final fade = (sampleRate * 0.01).round();
  for (var i = 0; i < fade; i++) {
    samples[i] *= i / fade;
    samples[n - 1 - i] *= i / fade;
  }
  return samples;
}

void writeWav(String path, Float64List samples) {
  final n = samples.length;
  final dataSize = n * 2; // PCM 16-bit mono
  final bytes = BytesBuilder();

  void str(String s) => bytes.add(s.codeUnits);
  void u32(int v) =>
      bytes.add((ByteData(4)..setUint32(0, v, Endian.little)).buffer.asUint8List());
  void u16(int v) =>
      bytes.add((ByteData(2)..setUint16(0, v, Endian.little)).buffer.asUint8List());

  str('RIFF');
  u32(36 + dataSize);
  str('WAVE');
  str('fmt ');
  u32(16);
  u16(1); // PCM
  u16(1); // mono
  u32(sampleRate);
  u32(sampleRate * 2); // byte rate
  u16(2); // block align
  u16(16); // bits
  str('data');
  u32(dataSize);
  final pcm = ByteData(dataSize);
  for (var i = 0; i < n; i++) {
    pcm.setInt16(i * 2, (samples[i] * 32767 * 0.9).round(), Endian.little);
  }
  bytes.add(pcm.buffer.asUint8List());

  final file = File(path)..createSync(recursive: true);
  file.writeAsBytesSync(bytes.toBytes());
  stdout.writeln('$path: ${(dataSize / 1024).toStringAsFixed(1)} KB');
}
