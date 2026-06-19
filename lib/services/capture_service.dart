import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:printing/printing.dart';

/// Traitement d'image léger pour le Tuteur (rognage + réduction), pensé pour les
/// téléphones bas de gamme : décodage/réduction dans un **isolate** (`compute`),
/// et sortie bornée en taille pour limiter la RAM et le poids réseau.
class CaptureService {
  /// Rend la **première page** d'un PDF en image PNG (densité modérée = peu de
  /// RAM), prête à être corrigée comme une photo. `null` si échec.
  static Future<Uint8List?> pdfFirstPageToImage(Uint8List pdfBytes, {double dpi = 140}) async {
    try {
      await for (final page in Printing.raster(pdfBytes, pages: [0], dpi: dpi)) {
        return await page.toPng();
      }
    } catch (_) {}
    return null;
  }

  /// Dimensions (largeur, hauteur) en px d'une image encodée, via le décodeur
  /// natif (léger, pas de chargement complet en Dart).
  static Future<(double, double)> imageSize(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final w = frame.image.width.toDouble();
    final h = frame.image.height.toDouble();
    frame.image.dispose();
    return (w, h);
  }

  /// Rogne [src] selon un rectangle en fractions 0..1 ([cl],[ct],[cw],[ch])
  /// puis réduit à [maxDim] px. Exécuté dans un isolate. Fractions nulles =
  /// pas de rognage (juste réduction).
  static Future<Uint8List> cropAndDownscale(
    Uint8List src, {
    double? cl,
    double? ct,
    double? cw,
    double? ch,
    int maxDim = 1400,
  }) {
    return compute(_process, _Args(src, cl, ct, cw, ch, maxDim));
  }
}

class _Args {
  final Uint8List bytes;
  final double? cl, ct, cw, ch;
  final int maxDim;
  _Args(this.bytes, this.cl, this.ct, this.cw, this.ch, this.maxDim);
}

Uint8List _process(_Args a) {
  img.Image? im = img.decodeImage(a.bytes);
  if (im == null) return a.bytes;

  if (a.cl != null && a.ct != null && a.cw != null && a.ch != null) {
    final x = (a.cl! * im.width).round().clamp(0, im.width - 1);
    final y = (a.ct! * im.height).round().clamp(0, im.height - 1);
    final w = (a.cw! * im.width).round().clamp(1, im.width - x);
    final h = (a.ch! * im.height).round().clamp(1, im.height - y);
    im = img.copyCrop(im, x: x, y: y, width: w, height: h);
  }

  final maxSide = im.width >= im.height ? im.width : im.height;
  if (maxSide > a.maxDim) {
    if (im.width >= im.height) {
      im = img.copyResize(im, width: a.maxDim);
    } else {
      im = img.copyResize(im, height: a.maxDim);
    }
  }
  return Uint8List.fromList(img.encodeJpg(im, quality: 85));
}
