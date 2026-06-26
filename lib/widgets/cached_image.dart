import 'dart:typed_data';
import 'package:flutter/material.dart';
// Imports conditionnels : dart:io sur mobile/desktop, repli vide sur le Web.
import '../services/image_store_io.dart'
    if (dart.library.html) '../services/image_store_stub.dart';

/// Remplaçant de `Image.network` avec **cache disque** (hors-ligne).
///
/// Mêmes paramètres que `Image.network` (`fit`, `width`, `height`,
/// `errorBuilder`, `loadingBuilder`) → substitution directe.
///
/// Stratégie : disque (octets en cache → affichage immédiat même hors-ligne)
/// → sinon réseau (`Image.network`, qui réussit en ligne et déclenche
/// `errorBuilder` hors-ligne). Sur le Web, on passe directement par le réseau
/// (cache géré par le navigateur).
class CachedImage extends StatefulWidget {
  final String url;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final ImageErrorWidgetBuilder? errorBuilder;
  final ImageLoadingBuilder? loadingBuilder;
  final bool gaplessPlayback;

  const CachedImage(
    this.url, {
    super.key,
    this.fit,
    this.width,
    this.height,
    this.errorBuilder,
    this.loadingBuilder,
    this.gaplessPlayback = true,
  });

  @override
  State<CachedImage> createState() => _CachedImageState();
}

class _CachedImageState extends State<CachedImage> {
  Uint8List? _bytes;
  bool _resolved = false; // résolution disque terminée

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(CachedImage old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) {
      _bytes = null;
      _resolved = false;
      _resolve();
    }
  }

  Future<void> _resolve() async {
    final b = await loadCachedImageBytes(widget.url);
    if (!mounted) return;
    setState(() {
      _bytes = b;
      _resolved = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1) Octets en cache disque → affichage immédiat (fonctionne hors-ligne).
    if (_bytes != null) {
      return Image.memory(
        _bytes!,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        gaplessPlayback: widget.gaplessPlayback,
        errorBuilder: widget.errorBuilder,
      );
    }
    // 2) Pas de cache disque (Web, premier chargement, ou échec) → réseau.
    if (_resolved) {
      return Image.network(
        widget.url,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        gaplessPlayback: widget.gaplessPlayback,
        errorBuilder: widget.errorBuilder,
        loadingBuilder: widget.loadingBuilder,
      );
    }
    // 3) Résolution disque en cours → placeholder via loadingBuilder s'il existe.
    if (widget.loadingBuilder != null) {
      return widget.loadingBuilder!(
        context,
        const SizedBox.shrink(),
        const ImageChunkEvent(cumulativeBytesLoaded: 0, expectedTotalBytes: null),
      );
    }
    return SizedBox(width: widget.width, height: widget.height);
  }
}
