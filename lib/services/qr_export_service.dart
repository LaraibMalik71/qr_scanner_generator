import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:gal/gal.dart';

class QRExportService {
  Future<Uint8List> generateImage({
    required String content,
    required Color qrColor,
    required Color backgroundColor,
  }) async {
    const double imageSize = 1024;
    const double quietZone = 64;
    const double qrSize = imageSize - (quietZone * 2);

    final painter = QrPainter(
      data: content,
      version: QrVersions.auto,
      // ignore: deprecated_member_use
      color: qrColor,
      // ignore: deprecated_member_use
      emptyColor: backgroundColor,
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw the background.
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, imageSize, imageSize),
      Paint()..color = backgroundColor,
    );

    // Draw the QR pattern inside the quiet zone.
    canvas.save();
    canvas.translate(quietZone, quietZone);
    painter.paint(canvas, const Size(qrSize, qrSize));
    canvas.restore();

    final picture = recorder.endRecording();
    final image = await picture.toImage(imageSize.toInt(), imageSize.toInt());

    final imageData = await image.toByteData(format: ui.ImageByteFormat.png);

    image.dispose();
    picture.dispose();

    if (imageData == null) {
      throw Exception('Could not generate QR image.');
    }

    return imageData.buffer.asUint8List();
  }

  Future<File> saveImage(Uint8List imageBytes) async {
    final directory = await getApplicationDocumentsDirectory();

    final fileName = 'qr_${DateTime.now().millisecondsSinceEpoch}.png';

    final file = File('${directory.path}/$fileName');

    await file.writeAsBytes(imageBytes);

    return file;
  }

  Future<void> saveToGallery(Uint8List imageBytes) async {
    final hasAccess = await Gal.hasAccess();

    if (!hasAccess) {
      final granted = await Gal.requestAccess();

      if (!granted) {
        throw Exception('Gallery permission denied.');
      }
    }

    await Gal.putImageBytes(
      imageBytes,
      name: 'QR_${DateTime.now().millisecondsSinceEpoch}',
    );
  }
}
