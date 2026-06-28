import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../widgets/leo_mascot.dart';
import '../../services/referral_service.dart';

/// Écran « Parrainage » : l'élève voit SON code à partager, ses stats (filleuls
/// + crédits gagnés) et le fonctionnement. La saisie d'un code se fait à
/// l'inscription (champ facultatif) — ici on partage le sien.
class ParrainageScreen extends StatefulWidget {
  const ParrainageScreen({super.key});

  @override
  State<ParrainageScreen> createState() => _ParrainageScreenState();
}

class _ParrainageScreenState extends State<ParrainageScreen> {
  ReferralStats _stats = const ReferralStats();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await ReferralService.instance.stats();
    if (mounted) setState(() { _stats = s; _loading = false; });
  }

  void _copy() {
    if (_stats.code.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _stats.code));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Code copié ! Partage-le à tes amis.'),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _share() async {
    if (_stats.code.isEmpty) return;
    await Share.share(
      'Rejoins-moi sur OnBuch 🎓 ! Mets mon code de parrainage ${_stats.code} '
      'à l\'inscription (sous le mot de passe) et gagne 5 crédits offerts pour démarrer. '
      'Révise, gagne de l\'XP et grimpe au classement avec moi !',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: obBackAppBar(context, 'Parrainage'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: OC.o500))
          : RefreshIndicator(
              color: OC.o600,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  // Héro : Léo + accroche.
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [OC.darkHero, OC.darkHero2]),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(children: [
                      const LeoMascot(size: 54, mood: LeoMood.wave),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Invite tes amis', style: display(19, weight: FontWeight.w800, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text('Gagne des crédits OnBuch pour chaque ami qui révise avec toi.',
                              style: body(12.5, color: Colors.white.withValues(alpha: 0.85), weight: FontWeight.w500).copyWith(height: 1.35)),
                        ]),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 18),

                  // Mon code.
                  Text('Ton code de parrainage', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
                    decoration: BoxDecoration(
                      color: OC.o50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: OC.o200, width: 1.5),
                    ),
                    child: Row(children: [
                      Expanded(
                        child: Text(
                          _stats.code.isEmpty ? '— — — —' : _stats.code,
                          style: mono(24, weight: FontWeight.w800, color: OC.o700).copyWith(letterSpacing: 3),
                        ),
                      ),
                      _CodeBtn(Icons.copy_rounded, 'Copier', _copy),
                      const SizedBox(width: 8),
                      _CodeBtn(Icons.ios_share_rounded, 'Partager', _share),
                    ]),
                  ),
                  const SizedBox(height: 10),
                  Text('Ton ami met ce code à l\'inscription (sous le mot de passe).',
                      style: body(11.5, color: OC.muted, weight: FontWeight.w500)),
                  const SizedBox(height: 22),

                  // Stats.
                  Row(children: [
                    Expanded(child: _StatCard(Icons.group_rounded, '${_stats.total}', 'Filleuls', OC.blue, OC.blueBg)),
                    const SizedBox(width: 11),
                    Expanded(child: _StatCard(Icons.verified_rounded, '${_stats.rewarded}', 'Validés', OC.good, OC.goodBg)),
                    const SizedBox(width: 11),
                    Expanded(child: _StatCard(Icons.bolt_rounded, '${_stats.creditsEarned}', 'Crédits gagnés', const Color(0xFFA6701A), const Color(0xFFFBF0DD))),
                  ]),
                  if (_stats.pending > 0) ...[
                    const SizedBox(height: 10),
                    Text('${_stats.pending} ami${_stats.pending > 1 ? 's' : ''} inscrit${_stats.pending > 1 ? 's' : ''} — tu seras crédité dès qu\'il${_stats.pending > 1 ? 's atteignent' : ' atteint'} le niveau 2.',
                        style: body(11.5, color: OC.muted, weight: FontWeight.w500).copyWith(height: 1.3)),
                  ],
                  const SizedBox(height: 22),

                  // Comment ça marche.
                  Text('Comment ça marche', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
                  const SizedBox(height: 10),
                  _Step('1', 'Partage ton code', 'Envoie ton code à tes amis.'),
                  _Step('2', 'Ton ami s\'inscrit', 'Il met ton code à l\'inscription et gagne 5 crédits offerts.'),
                  _Step('3', 'Tu gagnes 10 crédits', 'Dès que ton ami atteint le niveau 2 en révisant.'),
                ],
              ),
            ),
    );
  }
}

class _CodeBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _CodeBtn(this.icon, this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(color: OC.o600, borderRadius: BorderRadius.circular(11)),
        child: Row(children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 5),
          Text(label, style: body(12, weight: FontWeight.w700, color: Colors.white)),
        ]),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color c, bg;
  const _StatCard(this.icon, this.value, this.label, this.c, this.bg);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(16), border: Border.all(color: OC.line, width: 1.5)),
      child: Column(children: [
        Container(
          width: 34, height: 34, alignment: Alignment.center,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: c),
        ),
        const SizedBox(height: 8),
        FittedBox(child: Text(value, style: display(18, weight: FontWeight.w800))),
        const SizedBox(height: 1),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
            style: body(10, color: OC.muted, weight: FontWeight.w600)),
      ]),
    );
  }
}

class _Step extends StatelessWidget {
  final String n, title, desc;
  const _Step(this.n, this.title, this.desc);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 28, height: 28, alignment: Alignment.center,
          decoration: BoxDecoration(color: OC.o100, shape: BoxShape.circle),
          child: Text(n, style: display(13, weight: FontWeight.w800, color: OC.o700)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: body(13.5, weight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(desc, style: body(12, color: OC.muted, weight: FontWeight.w500).copyWith(height: 1.3)),
        ])),
      ]),
    );
  }
}
