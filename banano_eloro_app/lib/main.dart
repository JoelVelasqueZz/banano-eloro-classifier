import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'disease_info.dart';
import 'probability_bars.dart';
import 'sample_gallery_screen.dart';
import 'theme.dart';

const String _modelAsset = 'assets/mobilenet_v2_banano.tflite';
const int _inputSize = 224;
const List<double> _mean = [0.485, 0.456, 0.406];
const List<double> _std = [0.229, 0.224, 0.225];
const List<String> _classes = [
  'Sigatoka',
  'Cordana',
  'Pestalotiopsis',
  'Healthy',
  'Moko',
  'Panama_Disease',
  'Insect_Pest',
];

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clasificador Banano El Oro',
      theme: buildAppTheme(),
      home: const ClassifierPage(),
    );
  }
}

class ClassifierPage extends StatefulWidget {
  const ClassifierPage({super.key});

  @override
  State<ClassifierPage> createState() => _ClassifierPageState();
}

class _ClassifierPageState extends State<ClassifierPage> {
  Interpreter? _interpreter;
  Uint8List? _imageBytes;
  String? _predictedClass;
  double? _confidence;
  List<double>? _probabilities;
  bool _isModelLoading = true;
  bool _isPredicting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      final interpreter = await Interpreter.fromAsset(_modelAsset);
      setState(() {
        _interpreter = interpreter;
        _isModelLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'No se pudo cargar el modelo: $e';
        _isModelLoading = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isPredicting) return;

    try {
      final picked = await ImagePicker().pickImage(source: source);
      if (picked == null) return;

      final bytes = await File(picked.path).readAsBytes();
      await _runClassification(bytes);
    } catch (e) {
      setState(() {
        _errorMessage = 'No se pudo abrir la imagen: $e';
      });
    }
  }

  Future<void> _pickSample() async {
    if (_isPredicting) return;

    try {
      final selected = await Navigator.of(context).push<SampleImage>(
        MaterialPageRoute(builder: (_) => const SampleGalleryScreen()),
      );
      if (selected == null) return;

      final data = await rootBundle.load(selected.asset);
      await _runClassification(data.buffer.asUint8List());
    } catch (e) {
      setState(() {
        _errorMessage = 'No se pudo cargar la imagen de muestra: $e';
      });
    }
  }

  Future<void> _runClassification(Uint8List bytes) async {
    setState(() {
      _imageBytes = bytes;
      _predictedClass = null;
      _confidence = null;
      _probabilities = null;
      _errorMessage = null;
      _isPredicting = true;
    });

    try {
      await _classifyImage(bytes);
    } catch (e) {
      setState(() {
        _errorMessage =
            'No se pudo clasificar la imagen. Probá con otra foto.\n($e)';
      });
    } finally {
      setState(() {
        _isPredicting = false;
      });
    }
  }

  Future<void> _classifyImage(Uint8List bytes) async {
    final interpreter = _interpreter;
    if (interpreter == null) return;

    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('No se pudo decodificar la imagen');
    }

    final resized = img.copyResize(
      decoded,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.linear,
    );

    // Model expects NCHW (channels-first), the layout PyTorch exports with,
    // not Flutter/TFLite's usual NHWC (channels-last).
    final input = List.generate(
      1,
      (_) => List.generate(
        3,
        (c) => List.generate(
          _inputSize,
          (y) => List.generate(_inputSize, (x) {
            final pixel = resized.getPixel(x, y);
            final channelValue = switch (c) {
              0 => pixel.r,
              1 => pixel.g,
              _ => pixel.b,
            };
            return (channelValue / 255.0 - _mean[c]) / _std[c];
          }),
        ),
      ),
    );

    final output = List.generate(1, (_) => List.filled(_classes.length, 0.0));
    interpreter.run(input, output);

    // Model outputs raw logits, not probabilities: apply softmax to get a
    // meaningful confidence percentage.
    final probabilities = _softmax(output[0]);
    var bestIndex = 0;
    for (var i = 1; i < probabilities.length; i++) {
      if (probabilities[i] > probabilities[bestIndex]) bestIndex = i;
    }

    setState(() {
      _predictedClass = _classes[bestIndex];
      _confidence = probabilities[bestIndex];
      _probabilities = probabilities;
      _errorMessage = null;
    });
  }

  List<double> _softmax(List<double> logits) {
    final maxLogit = logits.reduce(math.max);
    final exps = logits.map((l) => math.exp(l - maxLogit)).toList();
    final sumExps = exps.reduce((a, b) => a + b);
    return exps.map((e) => e / sumExps).toList();
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clasificador de Banano El Oro'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isModelLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      Text(
                        'Cargando modelo…',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              if (!_isModelLoading && _errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: colorScheme.onErrorContainer),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 240,
                  width: double.infinity,
                  color: colorScheme.surfaceContainerHighest,
                  child: _imageBytes == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.eco_outlined,
                              size: 56,
                              color: colorScheme.primary.withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Selecciona una imagen para clasificar',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        )
                      : Image.memory(
                          _imageBytes!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                ),
              ),
              if (_isPredicting)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      Text(
                        'Clasificando imagen…',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              if (!_isPredicting && _predictedClass != null) ...[
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.eco, color: colorScheme.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _predictedClass!,
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Confianza: ${(_confidence! * 100).toStringAsFixed(1)}%',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 20),
                        ProbabilityBars(
                          classes: _classes,
                          probabilities: _probabilities!,
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Borrador — pendiente de revisión',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(fontStyle: FontStyle.italic),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                diseaseDescriptions[_predictedClass!] ?? '',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isModelLoading || _isPredicting
                        ? null
                        : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Cámara'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isModelLoading || _isPredicting
                        ? null
                        : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galería'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isModelLoading || _isPredicting
                        ? null
                        : _pickSample,
                    icon: const Icon(Icons.collections_bookmark),
                    label: const Text('Muestras'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
