import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';

class VideoCorrigeScreen extends StatefulWidget {
  const VideoCorrigeScreen({super.key});

  @override
  State<VideoCorrigeScreen> createState() => _VideoCorrigeScreenState();
}

class _VideoCorrigeScreenState extends State<VideoCorrigeScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.light,
    ));
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.dark,
    ));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.ink,
      body: SafeArea(
        child: Column(children: [
          // Video player
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Stack(alignment: Alignment.center, children: [
                  // placeholder thumbnail
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        colors: [const Color(0xFF1A1020), const Color(0xFF0D0A1A)],
                      ),
                    ),
                    child: const Center(child: Icon(Icons.play_lesson_rounded, size: 64, color: Color(0x33FFFFFF))),
                  ),
                  // gradient overlay
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withValues(alpha:0.55)],
                        ),
                      ),
                    ),
                  ),
                  // Play button
                  Container(
                    width: 58, height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha:0.92),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.4), blurRadius: 18)],
                    ),
                    child: const Icon(Icons.play_arrow_rounded, size: 34, color: OC.ink),
                  ),
                  // Scrubber
                  Positioned(
                    bottom: 12, left: 14, right: 14,
                    child: Row(children: [
                      Text('2:14', style: mono(11, weight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(width: 9),
                      Expanded(child: Stack(clipBehavior: Clip.none, alignment: Alignment.centerLeft, children: [
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha:0.3),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: 0.28,
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(color: OC.o500, borderRadius: BorderRadius.circular(3)),
                          ),
                        ),
                        Positioned(
                          left: MediaQuery.of(context).size.width * 0.28 * 0.7,
                          child: Container(
                            width: 12, height: 12,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          ),
                        ),
                      ])),
                      const SizedBox(width: 9),
                      Text('8:02', style: mono(11, weight: FontWeight.w700, color: Colors.white60)),
                      const SizedBox(width: 8),
                      const Icon(Icons.fullscreen_rounded, size: 16, color: Colors.white),
                    ]),
                  ),
                ]),
              ),
            ),
          ),

          // Meta + content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Tags
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7A5AE0).withValues(alpha:0.25),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text('CORRIGÉ VIDÉO', style: body(10.5, weight: FontWeight.w800, color: const Color(0xFFC3B0FF))),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha:0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text('Maths · Bac D', style: body(10.5, weight: FontWeight.w700, color: Colors.white.withValues(alpha:0.75))),
                  ),
                ]),
                const SizedBox(height: 9),
                Text('Nombres complexes — Exercice 1', style: display(19, weight: FontWeight.w600, color: Colors.white).copyWith(height: 1.15)),
                const SizedBox(height: 6),
                Text('Par M. Kamga · 8:02 · 1,2k vues', style: body(12.5, color: Colors.white.withValues(alpha:0.55))),
                const SizedBox(height: 14),

                // Buttons
                Row(children: [
                  Expanded(child: Container(
                    height: 46,
                    decoration: BoxDecoration(gradient: OC.grad, borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: OC.o500.withValues(alpha:0.30), blurRadius: 14, offset: const Offset(0, 6))]),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 7),
                      Text('Lire le corrigé', style: body(14, weight: FontWeight.w700, color: Colors.white)),
                    ]),
                  )),
                  const SizedBox(width: 10),
                  _DarkVideoBtn(Icons.closed_caption_outlined),
                  const SizedBox(width: 10),
                  _DarkVideoBtn(Icons.download_outlined),
                ]),
                const SizedBox(height: 18),

                // Chapters
                Text('CHAPITRES', style: body(12, weight: FontWeight.w800, color: Colors.white.withValues(alpha:0.5))
                    .copyWith(letterSpacing: 0.04 * 12)),
                const SizedBox(height: 10),
                ...[
                  ('0:00', 'Énoncé & méthode', true),
                  ('2:10', 'Calcul du module', false),
                  ('4:35', 'Forme exponentielle', false),
                ].map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    child: Row(children: [
                      SizedBox(
                        width: 34,
                        child: Text(c.$1, style: mono(11.5, weight: FontWeight.w700, color: c.$3 ? OC.o500 : Colors.white.withValues(alpha:0.5))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(c.$2, style: body(13.5, weight: c.$3 ? FontWeight.w700 : FontWeight.w500,
                          color: c.$3 ? Colors.white : Colors.white.withValues(alpha:0.7)))),
                      if (c.$3) Icon(Icons.play_arrow_rounded, size: 17, color: OC.o500),
                    ]),
                  ),
                )),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _DarkVideoBtn extends StatelessWidget {
  final IconData icon;
  const _DarkVideoBtn(this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50, height: 46,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}
