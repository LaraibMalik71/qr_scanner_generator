import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../utils/app_theme.dart';
import '../../utils/qr_content_detector.dart';

import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/qr_history_model.dart';
import '../../services/qr_history_service.dart';

import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';

import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';

import 'dart:async';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  late final MobileScannerController _scannerController;
  late ThemeProvider _themeProvider;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isProcessing = false;
  bool _isFlashOn = false;
  String? _scannedValue;

  @override
  void initState() {
    super.initState();
    _themeProvider = context.read<ThemeProvider>();

    _isFlashOn = context.read<ThemeProvider>().isFlashlightOn;

    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: [BarcodeFormat.qrCode],
      torchEnabled: _isFlashOn,
    );
  }

  @override
  void dispose() {
    _themeProvider.resetFlashlight();
    _scannerController.dispose();
    unawaited(_audioPlayer.dispose());
    super.dispose();
  }

  Future<void> _saveScannedHistory(String content) async {
    try {
      final type = QRContentDetector.detect(content);

      final history = QRHistoryModel(
        content: content,
        qrType: QRContentDetector.getTypeLabel(type),
        actionType: 'Scanned',
        createdAt: DateTime.now(),
      );

      await QRHistoryService.instance.addHistory(history);
    } catch (e) {
      debugPrint('Could not save scanned QR history: $e');
    }
  }

  // Future<void> _onDetect(BarcodeCapture capture) async {
  //   if (_isProcessing) return;

  //   final barcode = capture.barcodes.firstOrNull;
  //   final value = barcode?.rawValue;

  //   if (value == null || value.isEmpty) return;

  //   setState(() {
  //     _isProcessing = true;
  //     _scannedValue = value;
  //   });
  //   if (_themeProvider.isVibrationEnabled) {
  //     await Vibration.vibrate(pattern: [0, 300, 100, 300]);
  //   }
  //   if (_themeProvider.isScanSoundEnabled) {
  //     SystemSound.play(SystemSoundType.click);
  //   }

  //   _scannerController.stop();

  //   _saveScannedHistory(value);
  // }
  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final value = capture.barcodes.firstOrNull?.rawValue;
    if (value == null || value.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _scannedValue = value;
    });

    // do the instant things first
    if (_themeProvider.isScanSoundEnabled) {
      await _audioPlayer.play(AssetSource('audio/scan_beep.wav'));
    }
    _saveScannedHistory(value);

    await _scannerController.stop();

    // vibrate last, once the camera is fully released
    if (_themeProvider.isVibrationEnabled) {
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      try {
        await Vibration.vibrate(duration: 300);
      } catch (e) {
        debugPrint('Vibration error: $e');
      }
    }
  }

  Future<void> _toggleFlash() async {
    final newValue = !_isFlashOn;

    await _scannerController.toggleTorch();

    if (!mounted) return;

    setState(() {
      _isFlashOn = newValue;
    });

    context.read<ThemeProvider>().setFlashlight(newValue);
  }

  Future<void> _scanFromGallery() async {
    try {
      await _scannerController.stop();

      final XFile? image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );

      if (!mounted) return;

      if (image == null) {
        if (_scannedValue == null) {
          await _scannerController.start();
        }
        return;
      }

      final BarcodeCapture? capture = await _scannerController.analyzeImage(
        image.path,
      );

      if (!mounted) return;

      final hasQRCode =
          capture != null &&
          capture.barcodes.any(
            (barcode) =>
                barcode.rawValue != null && barcode.rawValue!.isNotEmpty,
          );

      if (hasQRCode) {
        setState(() {
          _isProcessing = false;
          _scannedValue = null;
        });

        _onDetect(capture);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No QR code found in this image.')),
        );

        if (_scannedValue == null) {
          await _scannerController.start();
        }
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not scan this image. Please try again.'),
        ),
      );

      if (_scannedValue == null) {
        await _scannerController.start();
      }
    }
  }

  Future<void> _openScannedLink() async {
    final value = _scannedValue;

    if (value == null) return;

    final uri = Uri.tryParse(value);

    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      return;
    }

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open this link.')),
        );
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this link.')),
      );
    }
  }

  Future<void> _copyScannedContent() async {
    final value = _scannedValue;

    if (value == null) return;

    await Clipboard.setData(ClipboardData(text: value));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Content copied to clipboard!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _scanFromGallery,
            icon: const Icon(Icons.photo_library_outlined),
            tooltip: 'Scan from Gallery',
          ),
          IconButton(
            onPressed: _toggleFlash,
            icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off),
            tooltip: 'Toggle flashlight',
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 24),

          const Text(
            'Scan a QR Code',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Text(
            'Position the QR code inside the frame',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),

          const SizedBox(height: 32),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MobileScanner(
                      controller: _scannerController,
                      onDetect: _onDetect,
                    ),

                    IgnorePointer(
                      child: Center(
                        child: Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppTheme.primaryColor,
                              width: 4,
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          if (_scannedValue != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'QR Code Scanned Successfully',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            QRContentDetector.getTypeLabel(
                              QRContentDetector.detect(_scannedValue!),
                            ),
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SelectableText(_scannedValue!),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (QRContentDetector.detect(_scannedValue!) ==
                        QRContentType.website) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _openScannedLink,
                          icon: const Icon(Icons.open_in_browser),
                          label: const Text('Open Link'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _copyScannedContent,
                        icon: const Icon(Icons.copy_rounded),
                        label: const Text('Copy Content'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          side: const BorderSide(color: AppTheme.primaryColor),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          setState(() {
                            _isProcessing = false;
                            _scannedValue = null;
                          });

                          await _scannerController.start();
                        },
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Scan Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Keep your camera steady and make sure the QR code is clearly visible.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
