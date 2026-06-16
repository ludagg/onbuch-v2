import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';

class TutorCameraScreen extends StatefulWidget {
  const TutorCameraScreen({super.key});

  @override
  State<TutorCameraScreen> createState() => _TutorCameraScreenState();
}

class _TutorCameraScreenState extends State<TutorCameraScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.light,
    ));
  }

  final _picker = ImagePicker();
  bool _busy = false;

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.dark,
    ));
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 90,
      );
      if (file == null) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() => _busy = false);
      // Envoie les octets à l'écran de correction (analyse côté Tuteur IA).
      context.push('/tutor/correction', extra: bytes);
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible d\'ouvrir la caméra/galerie.',
              style: body(13, weight: FontWeight.w600, color: Colors.white)),
          backgroundColor: OC.bad,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0B09),
      body: SafeArea(
        child: Column(children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(children: [
              _CameraBtn(Icons.close_rounded, () => context.go('/tutor')),
              const Spacer(),
              Text('Cadre ton exercice', style: body(13.5, weight: FontWeight.w700, color: Colors.white)),
              const Spacer(),
              _CameraBtn(Icons.flash_off_rounded, () {}),
            ]),
          ),
          // Viewfinder
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  color: const Color(0xFF1A1310),
                  child: Stack(alignment: Alignment.center, children: [
                    // Dark overlay
                    Container(color: Colors.black.withValues(alpha:0.28)),
                    // Corner guides
                    ...[
                      const Alignment(-0.85, -0.82),
                      const Alignment(0.85, -0.82),
                      const Alignment(-0.85, 0.82),
                      const Alignment(0.85, 0.82),
                    ].asMap().entries.map((e) {
                      final i = e.key;
                      final al = e.value;
                      final borders = [
                        const Border(top: BorderSide(color: Colors.white, width: 3), left: BorderSide(color: Colors.white, width: 3)),
                        const Border(top: BorderSide(color: Colors.white, width: 3), right: BorderSide(color: Colors.white, width: 3)),
                        const Border(bottom: BorderSide(color: Colors.white, width: 3), left: BorderSide(color: Colors.white, width: 3)),
                        const Border(bottom: BorderSide(color: Colors.white, width: 3), right: BorderSide(color: Colors.white, width: 3)),
                      ][i];
                      return Align(
                        alignment: al,
                        child: Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(
                            border: borders,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    }),
                    // Hint
                    const Align(
                      alignment: Alignment(0, 0.82),
                      child: _HintPill('Tiens le téléphone bien à plat'),
                    ),
                  ]),
                ),
              ),
            ),
          ),
          // Controls
          Padding(
            padding: const EdgeInsets.fromLTRB(30, 20, 30, 14),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              // Galerie
              GestureDetector(
                onTap: () => _pick(ImageSource.gallery),
                child: Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.image_outlined, color: Colors.white, size: 23),
                ),
              ),
              // Déclencheur (ouvre la caméra)
              GestureDetector(
                onTap: () => _pick(ImageSource.camera),
                child: Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.white.withValues(alpha:0.25), blurRadius: 0, spreadRadius: 4)],
                  ),
                  child: Center(
                    child: _busy
                        ? const SizedBox(
                            width: 26, height: 26,
                            child: CircularProgressIndicator(strokeWidth: 3, color: OC.o500),
                          )
                        : Container(
                            width: 58, height: 58,
                            decoration: BoxDecoration(gradient: OC.grad, shape: BoxShape.circle),
                          ),
                  ),
                ),
              ),
              // Reprise caméra (raccourci)
              GestureDetector(
                onTap: () => _pick(ImageSource.camera),
                child: Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.flip_camera_ios_outlined, color: Colors.white, size: 22),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _CameraBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CameraBtn(this.icon, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha:0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 19),
      ),
    );
  }
}

class _HintPill extends StatelessWidget {
  final String text;
  const _HintPill(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha:0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: body(11.5, weight: FontWeight.w600, color: Colors.white.withValues(alpha:0.9))),
    );
  }
}
