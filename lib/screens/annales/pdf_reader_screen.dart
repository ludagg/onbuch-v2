import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

class PdfReaderScreen extends StatefulWidget {
  const PdfReaderScreen({super.key});

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  final _currentPage = 1;
  final _totalPages = 6;

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
      backgroundColor: const Color(0xFF1A1410),
      body: SafeArea(
        child: Column(children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Row(children: [
              _DarkBtn(Icons.arrow_back_ios_new_rounded, () => context.go('/annales/detail')),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Maths · Bac D 2025', style: body(14, weight: FontWeight.w700, color: Colors.white)),
                Text('Sujet officiel · PDF', style: body(11, color: Colors.white.withOpacity(0.55))),
              ])),
              _DarkBtn(Icons.download_outlined, () {}),
              const SizedBox(width: 8),
              _DarkBtn(Icons.share_outlined, () {}),
            ]),
          ),
          // Page content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30, offset: const Offset(0, 10))],
                ),
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Center(child: Column(children: [
                      Text('RÉPUBLIQUE DU CAMEROUN · OBC',
                          style: body(9, weight: FontWeight.w700, color: const Color(0xFF999999))
                              .copyWith(letterSpacing: 0.1 * 9)),
                      const SizedBox(height: 6),
                      Text('Baccalauréat — Série D', style: display(15, weight: FontWeight.w700, color: const Color(0xFF222222))),
                      const SizedBox(height: 2),
                      Text('Épreuve de Mathématiques · 2025', style: body(11, color: const Color(0xFF666666))),
                    ])),
                    const Divider(height: 24, color: Color(0xFFEEEEEE), thickness: 1.5),
                    Text('EXERCICE 1 (5 points)', style: body(11.5, weight: FontWeight.w700, color: const Color(0xFF333333))),
                    const SizedBox(height: 10),
                    ...['100%', '96%', '88%', '93%', '70%'].map((w) => Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: FractionallySizedBox(
                        widthFactor: double.parse(w.replaceAll('%', '')) / 100,
                        child: Container(height: 6, decoration: BoxDecoration(
                            color: const Color(0xFFE8E8E8), borderRadius: BorderRadius.circular(3))),
                      ),
                    )),
                    const SizedBox(height: 12),
                    Text('EXERCICE 2 (4 points)', style: body(11.5, weight: FontWeight.w700, color: const Color(0xFF333333))),
                    const SizedBox(height: 10),
                    ...['100%', '90%', '82%'].map((w) => Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: FractionallySizedBox(
                        widthFactor: double.parse(w.replaceAll('%', '')) / 100,
                        child: Container(height: 6, decoration: BoxDecoration(
                            color: const Color(0xFFE8E8E8), borderRadius: BorderRadius.circular(3))),
                      ),
                    )),
                    const SizedBox(height: 12),
                    Container(
                      height: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFEEEEEE), width: 1.5),
                        color: const Color(0xFFFAFAFA),
                      ),
                      child: Center(child: Text('Figure 1', style: body(10, color: const Color(0xFFBBBBBB), weight: FontWeight.w700))),
                    ),
                  ]),
                ),
              ),
            ),
          ),
          // Bottom controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.chevron_left_rounded, size: 22, color: Color(0x66FFFFFF)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('$_currentPage / $_totalPages',
                    style: mono(13, weight: FontWeight.w700, color: Colors.white)),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, size: 22, color: Colors.white),
              const SizedBox(width: 8),
              Container(width: 1, height: 22, color: Colors.white.withOpacity(0.18)),
              const SizedBox(width: 8),
              _DarkBtn(Icons.fullscreen_rounded, () {}),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _DarkBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _DarkBtn(this.icon, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 19),
      ),
    );
  }
}
