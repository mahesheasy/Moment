import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:moment/core/deep_links/moment_qr_link.dart';
import 'package:moment/features/friends/presentation/friends_invite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

/// Shares a Moment friend QR image plus the profile deep link.
abstract final class FriendQrShare {
  static Future<void> share({
    required String userId,
    required String username,
  }) async {
    final qrData = MomentQrLink.qrPayload(userId);
    final message = FriendInvite.message(username, userId);
    final imageFile = await _writeQrPngFile(data: qrData, username: username);

    await SharePlus.instance.share(
      ShareParams(
        text: message,
        subject: 'Add me on Moment',
        files: [XFile(imageFile.path, mimeType: 'image/png')],
      ),
    );
  }

  static Future<File> _writeQrPngFile({
    required String data,
    required String username,
  }) async {
    final bytes = await _renderQrPng(data);
    final dir = await getTemporaryDirectory();
    final safeName = username.replaceAll(RegExp(r'[^a-z0-9_]'), '_');
    final file = File('${dir.path}/moment_qr_$safeName.png');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static Future<Uint8List> _renderQrPng(String data) async {
    const canvasSize = 640.0;
    const quietZone = 48.0;
    final qrSize = canvasSize - (quietZone * 2);

    final painter = QrPainter(
      data: data,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.H,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Color(0xFF000000),
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Color(0xFF000000),
      ),
      gapless: false,
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawRect(
      const Rect.fromLTWH(0, 0, canvasSize, canvasSize),
      Paint()..color = const Color(0xFFFFFFFF),
    );

    canvas.save();
    canvas.translate(quietZone, quietZone);
    painter.paint(canvas, Size(qrSize, qrSize));
    canvas.restore();

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      canvasSize.toInt(),
      canvasSize.toInt(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('Could not render QR code image.');
    }
    return byteData.buffer.asUint8List();
  }
}
