// Génère les sources d'icône d'app à partir de la mascotte Léo.
//
// Sorties (1024×1024) :
//  - assets/icon/leo_adaptive_fg.png : foreground transparent, Léo centré et
//    réduit pour tenir dans la zone de sécurité des icônes adaptatives Android.
//  - assets/icon/leo_icon.png        : icône opaque (fond crème de marque) pour
//    iOS / l'icône legacy Android.
//
// Lancer : dart run tools/make_app_icon.dart
import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final src = img.decodePng(File('assets/images/leo.png').readAsBytesSync());
  if (src == null) {
    stderr.writeln('leo.png introuvable/illisible');
    exit(1);
  }
  Directory('assets/icon').createSync(recursive: true);

  // ── Foreground adaptatif (transparent). flutter_launcher_icons ré-applique
  // un inset de 16 % : on dimensionne Léo à ~86 % ici → ≈ 58 % visibles dans le
  // masque adaptatif (dans la zone de sécurité, jamais rogné). ──
  const canvas = 1024;
  final fgScaled = img.copyResize(src,
      width: (canvas * 0.86).round(), interpolation: img.Interpolation.cubic);
  final fg = img.Image(width: canvas, height: canvas, numChannels: 4);
  img.compositeImage(fg, fgScaled,
      dstX: (canvas - fgScaled.width) ~/ 2, dstY: (canvas - fgScaled.height) ~/ 2);
  File('assets/icon/leo_adaptive_fg.png').writeAsBytesSync(img.encodePng(fg));

  // ── Icône opaque (fond crème #FFF6E8, Léo à ~72 %) pour iOS / legacy ──
  final iconScaled = img.copyResize(src,
      width: (canvas * 0.72).round(), interpolation: img.Interpolation.cubic);
  final icon = img.Image(width: canvas, height: canvas, numChannels: 4);
  img.fill(icon, color: img.ColorRgba8(0xFF, 0xF6, 0xE8, 0xFF));
  img.compositeImage(icon, iconScaled,
      dstX: (canvas - iconScaled.width) ~/ 2, dstY: (canvas - iconScaled.height) ~/ 2);
  File('assets/icon/leo_icon.png').writeAsBytesSync(img.encodePng(icon));

  stdout.writeln('OK : assets/icon/leo_adaptive_fg.png + leo_icon.png');
}
