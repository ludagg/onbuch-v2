import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../services/appwrite_client.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: OC.bg,
            surfaceTintColor: Colors.transparent,
            titleSpacing: 18,
            title: const OBWordmark(size: 23),
            actions: [
              Stack(alignment: Alignment.center, children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, size: 23),
                  color: OC.ink,
                  onPressed: () {},
                ),
                Positioned(
                  top: 10, right: 10,
                  child: Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: OC.o500,
                      shape: BoxShape.circle,
                      border: Border.all(color: OC.bg, width: 1.5),
                    ),
                  ),
                ),
              ]),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => context.go('/profile'),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: OC.line2, width: 1.5),
                    ),
                    child: const Icon(Icons.person_outline_rounded, size: 22, color: OC.ink),
                  ),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(children: [
              // Greeting
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Center(child: Text('Bonjour, Aïcha 👋', style: display(24, weight: FontWeight.w600))),
              ),
              const SizedBox(height: 16),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: OC.paper,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(color: OC.ink.withValues(alpha:0.05), blurRadius: 5, offset: const Offset(0, 2)),
                      BoxShadow(color: OC.ink.withValues(alpha:0.06), blurRadius: 24, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: Row(children: [
                    const SizedBox(width: 20),
                    const Icon(Icons.search_rounded, size: 21, color: OC.muted),
                    const SizedBox(width: 13),
                    Expanded(child: Text('Rechercher…', style: body(15, color: OC.muted, weight: FontWeight.w500))),
                    Container(
                      width: 42, height: 42, margin: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: OC.grad,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: OC.o500.withValues(alpha:0.34), blurRadius: 14, offset: const Offset(0, 6))],
                      ),
                      child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 20),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 22),

              // Hero dark — résultats countdown
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _HeroCard(),
              ),
              const SizedBox(height: 18),

              // Tuteur CTA
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _TuteurCard(),
              ),
              const SizedBox(height: 22),

              // Raccourcis
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _Shortcuts(),
              ),
              const SizedBox(height: 26),

              // Épreuves sauvegardées
              const _SavedSection(),
              const SizedBox(height: 26),

              // Actualités
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _NewsSection(),
              ),
              const SizedBox(height: 26),

              // À l'affiche
              _AfficheSection(),
              const SizedBox(height: 26),

              // Communautés
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _CommunitySection(),
              ),
              const SizedBox(height: 24),

              // Appwrite ping
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: GestureDetector(
                  onTap: () async {
                    try {
                      await client.ping();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Appwrite connecté ✓', style: body(13, weight: FontWeight.w600, color: Colors.white)),
                            backgroundColor: OC.good,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erreur: $e', style: body(13, weight: FontWeight.w600, color: Colors.white)),
                            backgroundColor: OC.bad,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: OC.paper,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: OC.line2, width: 1.5),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.wifi_tethering_rounded, size: 18, color: OC.o500),
                      const SizedBox(width: 8),
                      Text('Send a ping', style: body(14, weight: FontWeight.w700, color: OC.ink)),
                    ]),
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

// ─── Hero card (dark editorial) ───────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0, 1],
          colors: [OC.darkHero, OC.darkHero2],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Stack(children: [
        // glow blob
        Positioned(
          top: -90, right: -70,
          child: Container(
            width: 200, height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [OC.o500.withValues(alpha:0.55), OC.o500.withValues(alpha:0)],
              ),
            ),
          ),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 7, height: 7, decoration: BoxDecoration(
              color: OC.o500,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: OC.o500.withValues(alpha:0.22), blurRadius: 6, spreadRadius: 3)],
            )),
            const SizedBox(width: 7),
            Text(
              'BACCALAURÉAT 2026',
              style: body(11, weight: FontWeight.w800, color: const Color(0xFFFFB489))
                  .copyWith(letterSpacing: 0.14 * 11),
            ),
          ]),
          const SizedBox(height: 16),
          Text('Résultats bientôt\ndisponibles', style: display(26, weight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 20),
          // Countdown
          Row(children: [
            _CountUnit('02', 'jours'),
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(':', style: display(26, weight: FontWeight.w600, color: Colors.white.withValues(alpha:0.22))),
            ),
            _CountUnit('14', 'heures'),
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(':', style: display(26, weight: FontWeight.w600, color: Colors.white.withValues(alpha:0.22))),
            ),
            _CountUnit('38', 'min'),
          ]),
          Container(height: 1, color: Colors.white.withValues(alpha:0.10), margin: const EdgeInsets.symmetric(vertical: 18)),
          Row(children: [
            const Icon(Icons.notifications_outlined, size: 17, color: Color(0xFFFFB489)),
            const SizedBox(width: 8),
            Text('Alerte activée', style: body(12.5, weight: FontWeight.w600, color: Colors.white.withValues(alpha:0.86))),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Text('Vérifier', style: body(13, weight: FontWeight.w700, color: OC.ink)),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_rounded, size: 16, color: OC.ink),
              ]),
            ),
          ]),
        ]),
      ]),
    );
  }
}

class _CountUnit extends StatelessWidget {
  final String value, unit;
  const _CountUnit(this.value, this.unit);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: Column(children: [
        Text(value, style: mono(34, weight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 6),
        Text(unit, style: body(10.5, color: Colors.white.withValues(alpha:0.5), weight: FontWeight.w600)
            .copyWith(letterSpacing: 0.04 * 10.5)),
      ]),
    );
  }
}

// ─── Tuteur CTA card ──────────────────────────────────────────────────────────
class _TuteurCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OC.o50,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: OC.o100, width: 1.5),
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              gradient: OC.grad,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: OC.o500.withValues(alpha:0.30), blurRadius: 14, offset: const Offset(0, 6))],
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Tuteur IA', style: display(17, weight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Photographie un exercice, reçois la correction', style: body(12.5, color: OC.o700, weight: FontWeight.w500)),
          ])),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: 0.66,
                minHeight: 7,
                backgroundColor: OC.o100,
                valueColor: const AlwaysStoppedAnimation(OC.o500),
              ),
            ),
            const SizedBox(height: 6),
            Text('2 / 3 corrections gratuites aujourd\'hui', style: body(11, color: OC.o700, weight: FontWeight.w600)),
          ])),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => context.go('/tutor/camera'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: OC.o500,
                borderRadius: BorderRadius.circular(13),
                boxShadow: [BoxShadow(color: OC.o500.withValues(alpha:0.28), blurRadius: 14, offset: const Offset(0, 6))],
              ),
              child: Row(children: [
                const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 18),
                const SizedBox(width: 7),
                Text('Scanner', style: body(13.5, weight: FontWeight.w700, color: Colors.white)),
              ]),
            ),
          ),
        ]),
      ]),
    );
  }
}

// ─── Raccourcis ───────────────────────────────────────────────────────────────
class _Shortcuts extends StatelessWidget {
  static const _items = [
    [Icons.description_outlined, 'Résultats', OC.o600, OC.bg],
    [Icons.menu_book_rounded, 'Annales', OC.waInk, OC.goodBg],
    [Icons.track_changes_rounded, 'Concours', OC.blue, OC.blueBg],
    [Icons.paid_outlined, 'Crédits', OC.warn, OC.warnBg],
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(_items.length, (i) {
        final it = _items[i];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: i > 0 ? 10 : 0),
            child: Column(children: [
              Container(
                height: 60,
                decoration: BoxDecoration(
                  color: OC.paper,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: OC.line, width: 1.5),
                ),
                child: Icon(it[0] as IconData, size: 22, color: it[2] as Color),
              ),
              const SizedBox(height: 8),
              Text(it[1] as String, style: body(11.5, weight: FontWeight.w600, color: OC.ink2)),
            ]),
          ),
        );
      }),
    );
  }
}

// ─── Saved papers ─────────────────────────────────────────────────────────────
class _SavedSection extends StatelessWidget {
  const _SavedSection();

  static const _papers = [
    ['Mathématiques', 'Bac D · 2023'],
    ['Philosophie', 'Probatoire A · 2024'],
    ['Physique-Chimie', 'Bac D · 2022'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SecHead(eyebrow: 'Hors-ligne', title: 'Tes épreuves', action: 'Gérer'),
      ),
      const SizedBox(height: 14),
      SizedBox(
        height: 170,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _papers.length,
          separatorBuilder: (_, __) => const SizedBox(width: 13),
          itemBuilder: (_, i) {
            final p = _papers[i];
            return Container(
              width: 156,
              decoration: BoxDecoration(
                color: OC.paper,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: OC.line, width: 1.5),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Stack(children: [
                  Container(
                    height: 92,
                    decoration: BoxDecoration(
                      color: OC.panel,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                    ),
                    child: const Center(child: Icon(Icons.description_outlined, color: OC.faint, size: 36)),
                  ),
                  Positioned(top: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha:0.72), borderRadius: BorderRadius.circular(8)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text('Hors-ligne', style: body(10, weight: FontWeight.w700, color: Colors.white)),
                      ]),
                    ),
                  ),
                ]),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 11, 12, 13),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p[0], style: body(13.5, weight: FontWeight.w700).copyWith(height: 1.15)),
                    const SizedBox(height: 4),
                    Text(p[1], style: body(11.5, weight: FontWeight.w600, color: OC.muted)),
                  ]),
                ),
              ]),
            );
          },
        ),
      ),
    ]);
  }
}

// ─── Actualités ───────────────────────────────────────────────────────────────
class _NewsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SecHead(eyebrow: 'Le fil OnBuch', title: 'Actualités'),
      const SizedBox(height: 14),
      // Featured
      Container(
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: OC.line, width: 1.5),
          color: OC.panel,
        ),
        child: Stack(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(19),
            child: Container(
              color: OC.panel,
              child: const Center(child: Icon(Icons.image_outlined, color: OC.faint, size: 48)),
            ),
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(19)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.transparent, const Color(0xFF0F0A07).withValues(alpha:0.86)],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 40, 16, 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(color: OC.o500, borderRadius: BorderRadius.circular(8)),
                  child: Text('EXAMENS', style: body(10, weight: FontWeight.w800, color: Colors.white)
                      .copyWith(letterSpacing: 0.04 * 10)),
                ),
                const SizedBox(height: 9),
                Text('Calendrier officiel du Bac 2026 publié par l\'OBC',
                    style: display(18, weight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 6),
                Text('OnBuch · il y a 2 h', style: body(11.5, color: Colors.white.withValues(alpha:0.7), weight: FontWeight.w500)),
              ]),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 16),
      // List
      ...[
        ['Bourses', const Color(0xFFE3ECFB), OC.blue, 'Bourses d\'excellence MINESUP : candidatures ouvertes', 'hier'],
        ['Conseil', OC.goodBg, OC.waInk, '5 réflexes pour réviser le jour J avec le Tuteur IA', 'il y a 3 j'],
      ].map((n) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 66, height: 66,
            decoration: BoxDecoration(color: n[1] as Color, borderRadius: BorderRadius.circular(14)),
            child: Center(child: Icon(Icons.article_outlined, color: n[2] as Color, size: 28)),
          ),
          const SizedBox(width: 13),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: n[1] as Color, borderRadius: BorderRadius.circular(7)),
              child: Text((n[0] as String).toUpperCase(), style: body(9.5, weight: FontWeight.w800, color: n[2] as Color)),
            ),
            const SizedBox(height: 6),
            Text(n[3] as String, style: body(13.5, weight: FontWeight.w700).copyWith(height: 1.25)),
            const SizedBox(height: 4),
            Text('OnBuch · ${n[4]}', style: body(11, color: OC.muted, weight: FontWeight.w500)),
          ])),
        ]),
      )),
    ]);
  }
}

// ─── À l'affiche (events + ads) ───────────────────────────────────────────────
class _AfficheSection extends StatelessWidget {
  const _AfficheSection();

  @override
  Widget build(BuildContext context) {
    const items = [
      ['ÉVÉNEMENT', OC.o500, 'Concours blanc national', 'Sam. 28 juin · en ligne'],
      ['SPONSORISÉ', Color(0xFF3A3346), 'Prépa ENS Yaoundé', 'Stages intensifs · –20 %'],
    ];
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SecHead(eyebrow: 'Événements & partenaires', title: 'À l\'affiche', action: null),
      ),
      const SizedBox(height: 14),
      SizedBox(
        height: 185,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 13),
          itemBuilder: (_, i) {
            final it = items[i];
            return Container(
              width: 270,
              decoration: BoxDecoration(
                color: OC.panel,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: OC.line, width: 1.5),
              ),
              child: Stack(children: [
                ClipRRect(borderRadius: BorderRadius.circular(19), child: Container(
                  color: OC.panel,
                  child: const Center(child: Icon(Icons.image_outlined, color: OC.faint, size: 48)),
                )),
                Positioned(top: 0, left: 0, right: 0, bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(19),
                      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withValues(alpha:0.84)]),
                    ),
                  ),
                ),
                Positioned(top: 12, left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(color: it[1] as Color, borderRadius: BorderRadius.circular(999)),
                    child: Text(it[0] as String, style: body(9.5, weight: FontWeight.w800, color: Colors.white)
                        .copyWith(letterSpacing: 0.06 * 9.5)),
                  ),
                ),
                Positioned(bottom: 13, left: 14, right: 14,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(it[2] as String, style: display(16.5, weight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(it[3] as String, style: body(11.5, color: Colors.white.withValues(alpha:0.8), weight: FontWeight.w500)),
                  ]),
                ),
              ]),
            );
          },
        ),
      ),
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (i) =>
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: i == 0 ? 18 : 6, height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: i == 0 ? OC.o500 : OC.o100,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      )),
    ]);
  }
}

// ─── Community ────────────────────────────────────────────────────────────────
class _CommunitySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const socials = [
      [Icons.chat_bubble_rounded, 'WhatsApp', '12k', Color(0xFF25D366)],
      [Icons.send_rounded, 'Telegram', '8k', Color(0xFF2AABEE)],
      [Icons.music_note_rounded, 'TikTok', '@onbuch', Colors.black],
      [Icons.facebook_rounded, 'Facebook', 'Page', Color(0xFF1877F2)],
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SecHead(eyebrow: 'Reste connectée', title: 'La communauté', action: null),
      const SizedBox(height: 14),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: socials.map((s) => Expanded(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Column(children: [
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: OC.paper,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: OC.line, width: 1.5),
              ),
              child: Icon(s[0] as IconData, color: s[3] as Color, size: 25),
            ),
            const SizedBox(height: 8),
            Text(s[1] as String, style: body(11.5, weight: FontWeight.w700, color: OC.ink), textAlign: TextAlign.center),
            const SizedBox(height: 3),
            Text(s[2] as String, style: body(10, weight: FontWeight.w600, color: OC.muted)),
          ]),
        ))).toList(),
      ),
    ]);
  }
}
