import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../widgets/leo_mascot.dart';
import '../../models/tutor_request.dart';
import '../../services/capture_service.dart';

/// « Résumer un cours » : l'élève charge plusieurs photos ou un PDF, et le
/// Tuteur en produit une **fiche de révision** (mode `summary`, gratuit).
class CourseSummaryScreen extends StatefulWidget {
  final String? subject;
  const CourseSummaryScreen({super.key, this.subject});

  @override
  State<CourseSummaryScreen> createState() => _CourseSummaryScreenState();
}

class _CourseSummaryScreenState extends State<CourseSummaryScreen> {
  static const _maxPages = 8;
  static const _subjects = ['Maths', 'Physique', 'SVT', 'Philo', 'Français', 'Histoire-Géo'];

  final _picker = ImagePicker();
  final List<Uint8List> _pages = [];
  String? _subject;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _subject = widget.subject;
  }

  int get _room => _maxPages - _pages.length;

  Future<void> _addDownscaled(Iterable<Uint8List> raws) async {
    setState(() => _busy = true);
    try {
      for (final raw in raws) {
        if (_pages.length >= _maxPages) break;
        // Réduit chaque page pour limiter la RAM (le service recompressera ensuite).
        final small = await CaptureService.cropAndDownscale(raw, maxDim: 1600);
        _pages.add(small);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addPhotos() async {
    if (_room <= 0) return _full();
    try {
      final picked = await _picker.pickMultiImage();
      if (picked.isEmpty) return;
      final raws = <Uint8List>[];
      for (final x in picked.take(_room)) {
        raws.add(await x.readAsBytes());
      }
      await _addDownscaled(raws);
      if (picked.length > _room) _full();
    } catch (_) {
      _toast('Impossible d\'ouvrir la galerie.');
    }
  }

  Future<void> _shoot() async {
    if (_room <= 0) return _full();
    try {
      final x = await _picker.pickImage(source: ImageSource.camera, imageQuality: 92);
      if (x == null) return;
      await _addDownscaled([await x.readAsBytes()]);
    } catch (_) {
      _toast('Appareil photo indisponible.');
    }
  }

  Future<void> _addPdf() async {
    if (_room <= 0) return _full();
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['pdf'], withData: true,
      );
      final bytes = res?.files.single.bytes;
      if (bytes == null) return;
      setState(() => _busy = true);
      final pages = await CaptureService.pdfAllPagesToImages(bytes, maxPages: _room);
      if (mounted) setState(() => _busy = false);
      if (pages.isEmpty) {
        _toast('PDF illisible ou vide.');
        return;
      }
      await _addDownscaled(pages);
    } catch (_) {
      if (mounted) setState(() => _busy = false);
      _toast('Impossible de lire le PDF.');
    }
  }

  void _full() => _toast('Maximum $_maxPages pages par fiche.');

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m, style: body(13, weight: FontWeight.w600, color: Colors.white)),
      backgroundColor: OC.ink,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _generate() {
    if (_pages.isEmpty) {
      _toast('Ajoute au moins une page de cours.');
      return;
    }
    context.pushReplacement('/tutor/fiche',
        extra: TutorRequest(summaryImages: List.of(_pages), subject: _subject, mode: 'summary'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: obBackAppBar(context, 'Résumer un cours'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          // Intro Léo
          Row(children: [
            const LeoMascot(size: 52, mood: LeoMood.encourage),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Charge tes pages de cours (photos ou PDF) et je t\'en fais une fiche de révision claire. C\'est gratuit 🎉',
                style: body(13, color: OC.ink2, weight: FontWeight.w600).copyWith(height: 1.35),
              ),
            ),
          ]),
          const SizedBox(height: 18),

          // Matière (optionnel)
          Text('Matière (optionnel)', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
          const SizedBox(height: 10),
          Wrap(spacing: 9, runSpacing: 9, children: _subjects.map((s) {
            final on = _subject == s;
            return GestureDetector(
              onTap: () => setState(() => _subject = on ? null : s),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
                decoration: BoxDecoration(
                  color: on ? OC.o50 : OC.paper,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: on ? OC.o500 : OC.line2, width: 1.5),
                ),
                child: Text(s, style: body(13, weight: FontWeight.w700, color: on ? OC.o700 : OC.ink2)),
              ),
            );
          }).toList()),
          const SizedBox(height: 20),

          // Sources
          Row(children: [
            _src(Icons.photo_library_outlined, 'Photos', _addPhotos),
            const SizedBox(width: 10),
            _src(Icons.camera_alt_outlined, 'Caméra', _shoot),
            const SizedBox(width: 10),
            _src(Icons.picture_as_pdf_outlined, 'PDF', _addPdf),
          ]),
          const SizedBox(height: 20),

          // Pages
          Row(children: [
            Text('Pages', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
            const SizedBox(width: 8),
            Text('${_pages.length}/$_maxPages', style: body(12, weight: FontWeight.w700, color: OC.muted)),
            const Spacer(),
            if (_busy)
              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: OC.o500)),
          ]),
          const SizedBox(height: 10),
          if (_pages.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 26),
              decoration: BoxDecoration(
                color: OC.paper,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: OC.line, width: 1.5),
              ),
              child: Column(children: [
                Icon(Icons.collections_bookmark_outlined, size: 30, color: OC.muted),
                const SizedBox(height: 8),
                Text('Ajoute des pages à résumer', style: body(13, color: OC.muted, weight: FontWeight.w600)),
              ]),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.74,
              ),
              itemCount: _pages.length,
              itemBuilder: (_, i) => _thumb(i),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: GestureDetector(
            onTap: _busy ? null : _generate,
            child: Opacity(
              opacity: _pages.isEmpty ? 0.55 : 1,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: OC.grad,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: OC.o500.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 6))],
                ),
                child: Center(
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 19),
                    const SizedBox(width: 8),
                    Text('Générer la fiche', style: body(14.5, weight: FontWeight.w700, color: Colors.white)),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _src(IconData icon, String label, VoidCallback onTap) => Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _busy ? null : onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: OC.paper,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: OC.line2, width: 1.5),
            ),
            child: Column(children: [
              Icon(icon, size: 23, color: OC.o600),
              const SizedBox(height: 7),
              Text(label, style: body(12.5, weight: FontWeight.w700, color: OC.ink2)),
            ]),
          ),
        ),
      );

  Widget _thumb(int i) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(fit: StackFit.expand, children: [
          Image.memory(_pages[i], fit: BoxFit.cover),
          Positioned(
            top: 4, right: 4,
            child: GestureDetector(
              onTap: () => setState(() => _pages.removeAt(i)),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, size: 15, color: Colors.white),
              ),
            ),
          ),
          Positioned(
            bottom: 4, left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(999)),
              child: Text('${i + 1}', style: body(10.5, weight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ]),
      );
}
