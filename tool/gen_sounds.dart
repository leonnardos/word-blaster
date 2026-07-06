// Gera os efeitos sonoros do jogo sinteticamente (sem depender de arquivos
// externos com licença desconhecida). Rodar com: dart run tool/gen_sounds.dart
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const sampleRate = 44100;

void main() {
  writeWav('assets/audio/explosion.wav', explosion());
  writeWav('assets/audio/error.wav', errorBuzz());
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
