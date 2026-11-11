import 'package:flutter_test/flutter_test.dart';
import 'package:spinclip/models/audio_info.dart';

// Trimmed real `ffprobe -show_format -show_streams -of json` output.
void main() {
  test('16-bit WAV reports PCM, bit depth and lossless', () {
    final info = AudioInfo.fromFfprobeJson({
      'streams': [
        {
          'codec_name': 'pcm_s16le',
          'codec_type': 'audio',
          'sample_fmt': 's16',
          'sample_rate': '44100',
          'channels': 2,
          'bits_per_sample': 16,
          'bit_rate': '1411200',
        },
      ],
      'format': {
        'format_name': 'wav',
        'duration': '30.000000',
        'size': '5292078',
        'bit_rate': '1411220',
      },
    });
    expect(info.durationSeconds, 30);
    expect(info.codecName, 'pcm_s16le');
    expect(info.formatName, 'wav');
    expect(info.sampleRate, 44100);
    expect(info.channels, 2);
    expect(info.bitDepth, 16);
    expect(info.bitRate, 1411200);
    expect(info.sizeBytes, 5292078);
    expect(info.isLossless, isTrue);
  });

  test('24-bit FLAC reads depth from bits_per_raw_sample, and its tags', () {
    final info = AudioInfo.fromFfprobeJson({
      'streams': [
        {
          'codec_name': 'flac',
          'codec_type': 'audio',
          'sample_fmt': 's32',
          'sample_rate': '44100',
          'channels': 2,
          'bits_per_sample': 0,
          'bits_per_raw_sample': '24',
        },
      ],
      'format': {
        'format_name': 'flac',
        'duration': '3.000000',
        'size': '439349',
        'bit_rate': '1171597',
        'tags': {'ARTIST': 'Audio Crawler', 'TITLE': 'Beyond the Surface'},
      },
    });
    expect(info.bitDepth, 24);
    expect(info.bitRate, 1171597); // falls back to the file's bitrate
    expect(info.isLossless, isTrue);
    expect(info.title, 'Beyond the Surface');
    expect(info.artist, 'Audio Crawler');
  });

  test('MP3 is lossy and has no bit depth', () {
    final info = AudioInfo.fromFfprobeJson({
      'streams': [
        {
          'codec_name': 'mp3',
          'codec_type': 'audio',
          'sample_fmt': 'fltp',
          'sample_rate': '44100',
          'channels': 2,
          'bits_per_sample': 0,
          'bit_rate': '320000',
        },
      ],
      'format': {
        'format_name': 'mp3',
        'duration': '3.000000',
        'size': '122297',
        'bit_rate': '326125',
      },
    });
    expect(info.bitDepth, isNull);
    expect(info.bitRate, 320000);
    expect(info.isLossless, isFalse);
    expect(info.title, isNull);
  });
}
