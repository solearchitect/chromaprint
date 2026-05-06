import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:chromaprint/chromaprint.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _version = '';
  String _fingerprint = '';
  String _error = '';

  @override
  void initState() {
    super.initState();
    _runChromaprint();
  }

  void _runChromaprint() {
    try {
      // Get library version.
      _version = getVersion();

      // Generate a fingerprint from synthetic audio data.
      // In a real application, you would read audio from a file or microphone.
      final cp = Chromaprint();
      cp.start(44100, 1);

      // Generate 5 seconds of a simple 440Hz sine wave as test audio.
      const sampleRate = 44100;
      const durationSeconds = 5;
      const numSamples = sampleRate * durationSeconds;
      final samples = Int16List(numSamples);
      for (var i = 0; i < numSamples; i++) {
        // 440 Hz sine wave at ~25% amplitude.
        samples[i] = (16384.0 * (2 * 3.14159265 * 440 * i / sampleRate).sin())
            .toInt();
      }

      cp.feed(samples);
      cp.finish();
      _fingerprint = cp.getFingerprint();

      final hash = cp.getFingerprintHash();
      final rawSize = cp.getRawFingerprintSize();

      cp.dispose();

      setState(() {
        _fingerprint =
            '$_fingerprint\n\nHash: $hash\nRaw fingerprint size: $rawSize items';
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 18);
    const spacerSmall = SizedBox(height: 10);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Chromaprint FFI Plugin')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Library version: $_version', style: textStyle),
              spacerSmall,
              if (_error.isNotEmpty)
                Text('Error: $_error',
                    style:
                        textStyle.copyWith(color: const Color(0xFFCC0000)))
              else ...[
                Text('Fingerprint (5s 440Hz sine wave):',
                    style: textStyle.copyWith(fontWeight: FontWeight.bold)),
                spacerSmall,
                SelectableText(_fingerprint, style: textStyle),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Extension to add sin() on double since we're not importing dart:math.
extension on double {
  double sin() => _sin(this);
}

// Simple Taylor series approximation of sin(x) for demo purposes.
// In production code, use dart:math's sin().
double _sin(double x) {
  // Normalize to [-pi, pi].
  x = x % (2 * 3.141592653589793);
  if (x > 3.141592653589793) x -= 2 * 3.141592653589793;
  if (x < -3.141592653589793) x += 2 * 3.141592653589793;
  double result = x;
  double term = x;
  for (var i = 1; i <= 10; i++) {
    term *= -x * x / ((2 * i) * (2 * i + 1));
    result += term;
  }
  return result;
}
