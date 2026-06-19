import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/capture_service.dart';

/// Caméra intégrée OnBuch pour scanner un exercice. Résolution maîtrisée
/// (720p) et capture d'une seule photo → faible empreinte mémoire, adaptée aux
/// téléphones bas de gamme. Prend aussi en charge l'import d'images et de PDF.
class CameraCaptureScreen extends StatefulWidget {
  final String? subject;
  const CameraCaptureScreen({super.key, this.subject});

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  bool _ready = false;
  bool _busy = false;
  bool _torch = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarIconBrightness: Brightness.light));
    _setup();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarIconBrightness: Brightness.dark));
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      c.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _setup();
    }
  }

  Future<void> _setup() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _error = 'Aucune caméra détectée.');
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      // 720p = bon compromis lisibilité / mémoire pour le bas de gamme.
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _ready = true;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Caméra indisponible. Vérifie l\'autorisation.');
    }
  }

  Future<void> _toggleTorch() async {
    final c = _controller;
    if (c == null) return;
    try {
      _torch = !_torch;
      await c.setFlashMode(_torch ? FlashMode.torch : FlashMode.off);
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _capture() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized || _busy) return;
    setState(() => _busy = true);
    try {
      final file = await c.takePicture();
      final bytes = await file.readAsBytes();
      _goCrop(bytes);
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        _snack('Capture impossible. Réessaie.');
      }
    }
  }

  Future<void> _import() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
        withData: true,
      );
      if (res == null || res.files.isEmpty) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      final f = res.files.first;
      var bytes = f.bytes;
      if (bytes == null) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      if ((f.extension ?? '').toLowerCase() == 'pdf') {
        final png = await CaptureService.pdfFirstPageToImage(bytes);
        if (png == null) {
          if (mounted) {
            setState(() => _busy = false);
            _snack('PDF illisible. Essaie une photo.');
          }
          return;
        }
        bytes = png;
      }
      _goCrop(bytes);
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        _snack('Import impossible.');
      }
    }
  }

  void _goCrop(Uint8List bytes) {
    if (!mounted) return;
    setState(() => _busy = false);
    context.push('/tutor/crop', extra: {'bytes': bytes, 'subject': widget.subject});
  }

  void _snack(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m, style: body(13, weight: FontWeight.w600, color: Colors.white)),
      backgroundColor: OC.bad,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0B09),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Row(children: [
              _iconBtn(Icons.close_rounded, () => context.canPop() ? context.pop() : context.go('/tutor')),
              const Spacer(),
              Text('Cadre ton exercice', style: body(13.5, weight: FontWeight.w700, color: Colors.white)),
              const Spacer(),
              _iconBtn(_torch ? Icons.flash_on_rounded : Icons.flash_off_rounded, _toggleTorch),
            ]),
          ),
          Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: _viewfinder(),
            ),
          )),
          Padding(
            padding: const EdgeInsets.fromLTRB(30, 18, 30, 12),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              GestureDetector(
                onTap: _import,
                child: Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 23),
                ),
              ),
              GestureDetector(
                onTap: _capture,
                child: Container(
                  width: 74, height: 74,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Center(
                    child: _busy
                        ? const SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 3, color: OC.o500))
                        : Container(width: 60, height: 60, decoration: const BoxDecoration(gradient: OC.grad, shape: BoxShape.circle)),
                  ),
                ),
              ),
              GestureDetector(
                onTap: _import,
                child: Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.picture_as_pdf_outlined, color: Colors.white, size: 22),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text('Photo · galerie · PDF — léger, même sur petit téléphone',
                style: body(10.5, color: Colors.white.withValues(alpha: 0.55), weight: FontWeight.w500)),
          ),
        ]),
      ),
    );
  }

  Widget _viewfinder() {
    if (_error != null) {
      return Container(
        color: const Color(0xFF1A1310),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.no_photography_outlined, color: Colors.white54, size: 40),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center, style: body(13.5, color: Colors.white70, weight: FontWeight.w600)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: OC.o500, foregroundColor: Colors.white, elevation: 0),
            icon: const Icon(Icons.photo_library_outlined, size: 18),
            label: const Text('Importer une image / PDF'),
            onPressed: _import,
          ),
        ]),
      );
    }
    if (!_ready || _controller == null) {
      return Container(color: const Color(0xFF1A1310), child: const Center(child: CircularProgressIndicator(color: OC.o500)));
    }
    return Stack(fit: StackFit.expand, children: [
      FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller!.value.previewSize?.height ?? 720,
          height: _controller!.value.previewSize?.width ?? 1280,
          child: CameraPreview(_controller!),
        ),
      ),
      IgnorePointer(
        child: Align(
          alignment: const Alignment(0, 0.86),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(999)),
            child: Text('Tiens le téléphone bien à plat', style: body(11.5, weight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.9))),
          ),
        ),
      ),
    ]);
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      );
}
