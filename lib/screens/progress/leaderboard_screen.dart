import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../widgets/states.dart';
import '../../services/auth_service.dart';
import '../../services/gamification_service.dart';
import '../../services/leaderboard_service.dart';

/// Classement : un onglet **National** (tous les élèves, par XP total, avec ton
/// rang national) et un onglet **Ma ligue** (façon Duolingo, classement hebdo
/// par XP de la semaine, zone de promotion). Données mises en cache pour rester
/// lisibles hors-ligne.
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  static const int _promoZone = 10; // top 10 montent en ligue supérieure

  int _tab = 0; // 0 = National, 1 = Ma ligue
  bool _loading = true;
  String? _uid;

  // Ligue (hebdo)
  League _league = kLeagues.first;
  List<LeaderboardEntry> _entries = const [];
  int _myRank = 0;

  // National (XP total)
  List<LeaderboardEntry> _natEntries = const [];
  int _natRank = 0;
  int _natTotal = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final user = await AuthService().getCurrentUser();
      await GamificationService.instance.load();
      final g = GamificationService.instance.state.value;
      final weekly = GamificationService.instance.weeklyXp();
      final league = leagueForLevel(g.level);
      final lb = LeaderboardService.instance;

      if (user != null) {
        _uid = user.$id;
        final name = user.name.trim().isNotEmpty ? user.name.trim() : 'Élève';
        await lb.submit(uid: _uid!, name: name, level: g.level, xp: g.xp, weeklyXp: weekly);

        // Ligue (hebdo)
        var list = await lb.top(league: league.name);
        if (!list.any((e) => e.uid == _uid)) {
          list = [
            ...list,
            LeaderboardEntry(uid: _uid!, name: name, level: g.level, weeklyXp: weekly, xp: g.xp),
          ]..sort((a, b) => b.weeklyXp.compareTo(a.weeklyXp));
          for (var i = 0; i < list.length; i++) {
            list[i].rank = i + 1;
          }
        }
        _entries = list;
        _myRank = list.indexWhere((e) => e.uid == _uid) + 1;

        // National (XP total)
        final nat = await lb.nationalTop();
        if (!nat.any((e) => e.uid == _uid)) {
          nat.add(LeaderboardEntry(uid: _uid!, name: name, level: g.level, weeklyXp: weekly, xp: g.xp));
          nat.sort((a, b) => b.xp.compareTo(a.xp));
          for (var i = 0; i < nat.length; i++) {
            nat[i].rank = i + 1;
          }
        }
        _natEntries = nat;
        final r = await lb.nationalRank(myXp: g.xp);
        _natRank = r.rank;
        _natTotal = r.total;
      }
      _league = league;
    } catch (_) {/* hors-ligne → état vide / cache */}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: obBackAppBar(context, 'Classement'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: OC.o500))
          : RefreshIndicator(
              color: OC.o600,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  _segmented(),
                  const SizedBox(height: 16),
                  if (_tab == 0) ..._national() else ..._ligue(),
                ],
              ),
            ),
    );
  }

  Widget _segmented() {
    Widget seg(String label, int i) => Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _tab = i),
            child: Container(
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _tab == i ? OC.o600 : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Text(label,
                  style: body(13.5, weight: FontWeight.w800, color: _tab == i ? Colors.white : OC.ink2)),
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: OC.panel, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [seg('National', 0), const SizedBox(width: 4), seg('Ma ligue', 1)]),
    );
  }

  // ── Onglet National ─────────────────────────────────────────────────────────
  List<Widget> _national() {
    return [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [OC.darkHero, OC.darkHero2]),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(children: [
          Container(
            width: 60, height: 60, alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), shape: BoxShape.circle),
            child: const Icon(Icons.public_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Rang national', style: body(12.5, color: Colors.white.withValues(alpha: 0.8), weight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(_natRank > 0 ? '#$_natRank' : '—',
                style: display(30, weight: FontWeight.w800, color: Colors.white)),
            if (_natTotal > 0)
              Text('sur $_natTotal élève${_natTotal > 1 ? 's' : ''} classé${_natTotal > 1 ? 's' : ''}',
                  style: body(11.5, color: Colors.white.withValues(alpha: 0.75), weight: FontWeight.w600)),
          ])),
        ]),
      ),
      const SizedBox(height: 16),
      Text('Top national', style: body(14, weight: FontWeight.w800, color: OC.ink2)),
      const SizedBox(height: 12),
      if (_natEntries.isEmpty)
        const EmptyState(
          icon: Icons.public_rounded,
          title: 'Classement en préparation',
          message: 'Gagne du XP pour apparaître dans le classement national.',
        )
      else
        for (final e in _natEntries) _rankRow(e, national: true, showPromo: false),
    ];
  }

  // ── Onglet Ma ligue ─────────────────────────────────────────────────────────
  List<Widget> _ligue() {
    final c = _league.color;
    final idx = kLeagues.indexOf(_league);
    final isTop = idx == kLeagues.length - 1;
    final me = _entries.where((e) => e.uid == _uid).toList();
    final myXp = me.isEmpty ? 0 : me.first.weeklyXp;
    return [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [c, Color.lerp(c, Colors.black, 0.3)!]),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(children: [
          Container(
            width: 60, height: 60, alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle),
            child: Icon(_league.icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 10),
          Text('Ligue ${_league.name}', style: display(20, weight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 4),
          Text(
            isTop ? 'Tu es dans la ligue la plus prestigieuse 👑'
                  : 'Le top $_promoZone monte en ligue supérieure cette semaine',
            textAlign: TextAlign.center,
            style: body(12.5, color: Colors.white.withValues(alpha: 0.9), weight: FontWeight.w600).copyWith(height: 1.4),
          ),
        ]),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: OC.paper, borderRadius: BorderRadius.circular(16), border: Border.all(color: OC.line, width: 1.5)),
        child: Row(children: [
          _statChip(Icons.leaderboard_rounded, _myRank > 0 ? '#$_myRank' : '—', 'Ma position'),
          Container(width: 1.5, height: 34, color: OC.line, margin: const EdgeInsets.symmetric(horizontal: 14)),
          _statChip(Icons.bolt_rounded, '$myXp', 'XP cette semaine'),
          const Spacer(),
          Text('${_entries.length} en lice', style: body(11.5, color: OC.muted, weight: FontWeight.w700)),
        ]),
      ),
      const SizedBox(height: 14),
      if (_entries.isEmpty)
        const EmptyState(
          icon: Icons.leaderboard_rounded,
          title: 'Classement en préparation',
          message: 'Gagne du XP cette semaine pour apparaître dans ta ligue.',
        )
      else
        for (final e in _entries) _rankRow(e, national: false, showPromo: true),
    ];
  }

  Widget _statChip(IconData ic, String value, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(ic, size: 18, color: OC.o600),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text(value, style: display(16, weight: FontWeight.w800)),
        Text(label, style: body(9.5, color: OC.muted, weight: FontWeight.w600)),
      ]),
    ]);
  }

  Widget _rankRow(LeaderboardEntry e, {required bool national, required bool showPromo}) {
    final isMe = e.uid == _uid;
    final inPromo = !national && e.rank <= _promoZone;
    final promoDivider = showPromo && e.rank == _promoZone && _entries.length > _promoZone &&
        kLeagues.indexOf(_league) < kLeagues.length - 1;
    final value = national ? '${e.xp} XP' : '${e.weeklyXp} XP';

    return Column(children: [
      Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: isMe ? OC.o50 : OC.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isMe ? OC.o200 : OC.line, width: 1.5),
        ),
        child: Row(children: [
          SizedBox(width: 30, child: _rankBadge(e.rank, inPromo)),
          const SizedBox(width: 8),
          Container(
            width: 38, height: 38, alignment: Alignment.center,
            decoration: BoxDecoration(color: isMe ? OC.o600 : OC.panel, shape: BoxShape.circle),
            child: Text(e.initial,
                style: display(16, weight: FontWeight.w800, color: isMe ? Colors.white : OC.ink2)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isMe ? '${e.name} (toi)' : e.name,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: body(13.5, weight: FontWeight.w800, color: isMe ? OC.o700 : OC.ink)),
            Text('Niveau ${e.level}', style: body(11, color: OC.muted, weight: FontWeight.w600)),
          ])),
          const SizedBox(width: 8),
          Text(value, style: mono(13, weight: FontWeight.w800, color: OC.ink2)),
        ]),
      ),
      if (promoDivider)
        Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: Row(children: [
            Expanded(child: Divider(color: OC.good.withValues(alpha: 0.5), thickness: 1.5)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text('ZONE DE PROMOTION', style: body(9.5, weight: FontWeight.w800, color: OC.good).copyWith(letterSpacing: 1)),
            ),
            Expanded(child: Divider(color: OC.good.withValues(alpha: 0.5), thickness: 1.5)),
          ]),
        ),
    ]);
  }

  Widget _rankBadge(int rank, bool inPromo) {
    Color? medal;
    if (rank == 1) medal = const Color(0xFFE3B341);
    if (rank == 2) medal = const Color(0xFF9AA0A6);
    if (rank == 3) medal = const Color(0xFFCD7F32);
    if (medal != null) {
      return Container(
        width: 26, height: 26, alignment: Alignment.center,
        decoration: BoxDecoration(color: medal.withValues(alpha: 0.18), shape: BoxShape.circle),
        child: Text('$rank', style: display(13, weight: FontWeight.w800, color: medal)),
      );
    }
    return Text('$rank',
        textAlign: TextAlign.center,
        style: display(14, weight: FontWeight.w800, color: inPromo ? OC.good : OC.muted));
  }
}
