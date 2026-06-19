import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../models/tutor_request.dart';
import '../../services/capture_service.dart';

/// Rognage d'un exercice sur une photo/page avant correction. L'utilisateur
/// ajuste un rectangle (déplacement + coins) ou envoie l'exercice entier. Le
/// recadrage et la réduction se font dans un isolate (RAM maîtrisée).
class CropScreen extends StatefulWidget {
  final Uint8List bytes;
  final String? subject;
  const CropScreen({super.key, required this.bytes, this.subject});

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  double? _aspect; // largeur / hauteur
  Rect? _img; // rectangle d'affichage de l'image (contain)
  Rect? _crop; // rectangle de rognage (coords écran)
  bool _processing = false;
  static const _handle = 30.0;
  static const _minCrop = 56.0;

  @override
  void initState() {
    super.initState();
    CaptureService.imageSize(widget.bytes).then((s) {
      if (mounted) setState(() => _aspect = s.$2 == 0 ? 1 : s.$1 / s.$2);
    });
  }

  Rect _contain(Size box, double aspect) {
    var w = box.width, h = box.width / aspect;
    if (h > box.height) {
      h = box.height;
      w = box.height * aspect;
    }
    final l = (box.width - w) / 2, t = (box.height - h) / 2;
    return Rect.fromLTWH(l, t, w, h);
  }

  void _moveBy(Offset d) {
    final img = _img!, c = _crop!;
    var r = c.shift(d);
    double dx = 0, dy = 0;
    if (r.left < img.left) dx = img.left - r.left;
    if (r.right > img.right) dx = img.right - r.right;
    if (r.top < img.top) dy = img.top - r.top;
    if (r.bottom > img.bottom) dy = img.bottom - r.bottom;
    r = r.shift(Offset(dx, dy));
    setState(() => _crop = r);
  }

  void _dragCorner(int corner, Offset d) {
    final img = _img!, c = _crop!;
    var l = c.left, t = c.top, r = c.right, b = c.bottom;
    switch (corner) {
      case 0: // topLeft
        l = (l + d.dx).clamp(img.left, r - _minCrop);
        t = (t + d.dy).clamp(img.top, b - _minCrop);
        break;
      case 1: // topRight
        r = (r + d.dx).clamp(l + _minCrop, img.right);
        t = (t + d.dy).clamp(img.top, b - _minCrop);
        break;
      case 2: // bottomLeft
        l = (l + d.dx).clamp(img.left, r - _minCrop);
        b = (b + d.dy).clamp(t + _minCrop, img.bottom);
        break;
      case 3: // bottomRight
        r = (r + d.dx).clamp(l + _minCrop, img.right);
        b = (b + d.dy).clamp(t + _minCrop, img.bottom);
        break;
    }
    setState(() => _crop = Rect.fromLTRB(l, t, r, b));
  }

  Future<void> _send({required bool cropped}) async {
    if (_processing || _img == null || _crop == null) return;
    setState(() => _processing = true);
    final img = _img!, c = _crop!;
    Uint8List out;
    if (cropped && img.width > 0 && img.height > 0) {
      out = await CaptureService.cropAndDownscale(
        widget.bytes,
        cl: (c.left - img.left) / img.width,
        ct: (c.top - img.top) / img.height,
        cw: c.width / img.width,
        ch: c.height / img.height,
      );
    } else {
      out = await CaptureService.cropAndDownscale(widget.bytes);
    }
    if (!mounted) return;
    // Remplace l'écran de rognage par la correction.
    context.pushReplacement('/tutor/correction',
        extra: TutorRequest(image: out, subject: widget.subject));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0B09),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => context.canPop() ? context.pop() : context.go('/tutor'),
              ),
              const Spacer(),
              Text('Rogne ton exercice', style: body(14, weight: FontWeight.w700, color: Colors.white)),
              const Spacer(),
              const SizedBox(width: 48),
            ]),
          ),
          Expanded(
            child: _aspect == null
                ? const Center(child: CircularProgressIndicator(color: OC.o500))
                : LayoutBuilder(builder: (context, cons) {
                    final box = Size(cons.maxWidth, cons.maxHeight);
                    _img = _contain(box, _aspect!);
                    _crop ??= _img!.deflate(_img!.shortestSide * 0.08);
                    final img = _img!, crop = _crop!;
                    return Stack(children: [
                      Positioned.fromRect(
                        rect: img,
                        child: Image.memory(widget.bytes, fit: BoxFit.fill, gaplessPlayback: true),
                      ),
                      // Voile sombre hors zone de rognage.
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(painter: _MaskPainter(crop)),
                        ),
                      ),
                      // Déplacement (intérieur du cadre).
                      Positioned.fromRect(
                        rect: crop,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onPanUpdate: (d) => _moveBy(d.delta),
                          child: Container(
                            decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 2)),
                          ),
                        ),
                      ),
                      _cornerHandle(0, crop.topLeft),
                      _cornerHandle(1, crop.topRight),
                      _cornerHandle(2, crop.bottomLeft),
                      _cornerHandle(3, crop.bottomRight),
                    ]);
                  }),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
            child: Row(children: [
              Expanded(child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white38, width: 1.5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _processing ? null : () => _send(cropped: false),
                child: const Text('Tout l\'exercice', style: TextStyle(fontWeight: FontWeight.w700)),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: OC.o500, foregroundColor: Colors.white, elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _processing ? null : () => _send(cropped: true),
                child: _processing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                    : const Text('Rogner & corriger', style: TextStyle(fontWeight: FontWeight.w700)),
              )),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _cornerHandle(int corner, Offset at) {
    return Positioned(
      left: at.dx - _handle / 2,
      top: at.dy - _handle / 2,
      child: GestureDetector(
        onPanUpdate: (d) => _dragCorner(corner, d.delta),
        child: Container(
          width: _handle, height: _handle,
          color: Colors.transparent,
          alignment: Alignment.center,
          child: Container(
            width: 16, height: 16,
            decoration: BoxDecoration(
              color: OC.o500,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ),
    );
  }
}

class _MaskPainter extends CustomPainter {
  final Rect hole;
  _MaskPainter(this.hole);

  @override
  void paint(Canvas canvas, Size size) {
    final full = Path()..addRect(Offset.zero & size);
    final cut = Path()..addRect(hole);
    final path = Path.combine(PathOperation.difference, full, cut);
    canvas.drawPath(path, Paint()..color = Colors.black.withValues(alpha: 0.55));
  }

  @override
  bool shouldRepaint(covariant _MaskPainter old) => old.hole != hole;
}
