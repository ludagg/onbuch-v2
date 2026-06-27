import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../widgets/states.dart';
import '../../services/auth_service.dart';
import '../../services/gamification_service.dart';
import '../../services/leaderboard_service.dart';

/// Classement complet (façon Duolingo) : **National** (XP total, podium, ton
/// rang), **Ma ligue** (hebdo, compte à rebours, promotion/relégation) et
/// **Ligues** (échelle Bronze→Diamant, nb de joueurs, accès au classement de
/// chaque ligue). Tape un élève pour voir sa fiche.
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  static const int _promoZone = 10; // top 10 montent
  static const int _relegZone = 5; // 5 derniers descendent

  int _tab = 0; // 0 National · 1 Ma ligue · 2 Ligues
  bool _loading = true;
  String? _uid;

  League _league = kLeagues.first;
  List<LeaderboardEntry> _entries = const [];
  int _myRank = 0;

  List<LeaderboardEntry> _natEntries = const [];
  int _natRank = 0;
  int _natTotal = 0;

  Map<String, int> _counts = const {};

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
      _counts = await lb.leagueCounts();
    } catch (_) {/* hors-ligne → cache / vide */}
    if (mounted) setState(() => _loading = false);
  }

  // ── Compte à rebours fin de semaine (lundi) ─────────────────────────────────
  String _countdown() {
    final now = DateTime.now();
    final dToMon = (8 - now.weekday) % 7;
    final nextMonday = DateTime(now.year, now.month, now.day)
        .add(Duration(days: dToMon == 0 ? 7 : dToMon));
    final diff = nextMonday.difference(now);
    if (diff.inDays >= 1) return '${diff.inDays} j ${diff.inHours % 24} h';
    return '${diff.inHours} h ${diff.inMinutes % 60} min';
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
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  _segmented(),
                  const SizedBox(height: 16),
                  if (_tab == 0) ..._national() else if (_tab == 1) ..._ligue() else ..._ligues(),
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
                  style: body(13, weight: FontWeight.w800, color: _tab == i ? Colors.white : OC.ink2)),
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: OC.panel, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        seg('National', 0), const SizedBox(width: 4),
        seg('Ma ligue', 1), const SizedBox(width: 4),
        seg('Ligues', 2),
      ]),
    );
  }

  // ════ Onglet National ═══════════════════════════════════════════════════════
  List<Widget> _national() {
    final top3 = _natEntries.take(3).toList();
    final rest = _natEntries.skip(3).toList();
    return [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [OC.darkHero, OC.darkHero2]),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(children: [
          Container(
            width: 56, height: 56, alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), shape: BoxShape.circle),
            child: const Icon(Icons.public_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Ton rang national', style: body(12.5, color: Colors.white.withValues(alpha: 0.8), weight: FontWeight.w700)),
            Text(_natRank > 0 ? '#$_natRank' : '—', style: display(30, weight: FontWeight.w800, color: Colors.white)),
            if (_natTotal > 0)
              Text('sur $_natTotal élève${_natTotal > 1 ? 's' : ''} classé${_natTotal > 1 ? 's' : ''}',
                  style: body(11.5, color: Colors.white.withValues(alpha: 0.75), weight: FontWeight.w600)),
          ])),
        ]),
      ),
      const SizedBox(height: 18),
      if (_natEntries.isEmpty)
        const EmptyState(
          icon: Icons.public_rounded,
          title: 'Classement en préparation',
          message: 'Gagne du XP pour apparaître dans le classement national.')
      else ...[
        if (top3.isNotEmpty) _podium(top3, national: true),
        const SizedBox(height: 8),
        for (final e in rest) _rankRow(e, national: true),
      ],
    ];
  }

  // ════ Onglet Ma ligue ════════════════════════════════════════════════════════
  List<Widget> _ligue() {
    final c = _league.color;
    final idx = kLeagues.indexOf(_league);
    final isTop = idx == kLeagues.length - 1;
    final isBottom = idx == 0;
    final me = _entries.where((e) => e.uid == _uid).toList();
    final myXp = me.isEmpty ? 0 : me.first.weeklyXp;
    final top3 = _entries.take(3).toList();
    final rest = _entries.skip(3).toList();
    return [
      _leagueHeader(_league, subtitle: isTop
          ? 'La ligue la plus prestigieuse 👑'
          : 'Le top $_promoZone monte en ligue supérieure'),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: _miniCard(Icons.leaderboard_rounded, _myRank > 0 ? '#$_myRank' : '—', 'Ma position')),
        const SizedBox(width: 10),
        Expanded(child: _miniCard(Icons.bolt_rounded, '$myXp', 'XP semaine')),
        const SizedBox(width: 10),
        Expanded(child: _miniCard(Icons.timer_outlined, _countdown(), 'Fin de semaine')),
      ]),
      const SizedBox(height: 16),
      if (_entries.isEmpty)
        const EmptyState(
          icon: Icons.leaderboard_rounded,
          title: 'Classement en préparation',
          message: 'Gagne du XP cette semaine pour apparaître dans ta ligue.')
      else ...[
        if (top3.isNotEmpty) _podium(top3, national: false),
        const SizedBox(height: 8),
        for (final e in rest)
          _rankRow(e, national: false,
              promo: !isTop && e.rank <= _promoZone,
              releg: !isBottom && e.rank > _entries.length - _relegZone && _entries.length > _promoZone),
      ],
    ];
  }

  // ════ Onglet Ligues (échelle) ════════════════════════════════════════════════
  List<Widget> _ligues() {
    return [
      Text('Gravis les ligues', style: display(18, weight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text('Chaque semaine, le top de ta ligue monte d\'un cran. Garde ta série pour grimper !',
          style: body(12.5, color: OC.muted, weight: FontWeight.w500).copyWith(height: 1.4)),
      const SizedBox(height: 16),
      // Du plus haut au plus bas (Diamant en haut).
      for (var i = kLeagues.length - 1; i >= 0; i--) _ladderTile(kLeagues[i]),
    ];
  }

  Widget _ladderTile(League l) {
    final mine = l.name == _league.name;
    final count = _counts[l.name] ?? 0;
    final levelRange = () {
      final idx = kLeagues.indexOf(l);
      final next = idx < kLeagues.length - 1 ? kLeagues[idx + 1].minLevel : null;
      return next == null ? 'Niveau ${l.minLevel}+' : 'Niveaux ${l.minLevel}–${next - 1}';
    }();
    return GestureDetector(
      onTap: () => _showLeagueSheet(l),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: mine ? l.color.withValues(alpha: 0.10) : OC.paper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: mine ? l.color : OC.line, width: mine ? 2 : 1.5),
        ),
        child: Row(children: [
          Container(
            width: 46, height: 46, alignment: Alignment.center,
            decoration: BoxDecoration(color: l.color.withValues(alpha: 0.16), shape: BoxShape.circle),
            child: Icon(l.icon, color: l.color, size: 24),
          ),
          const SizedBox(width: 13),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Ligue ${l.name}', style: body(14.5, weight: FontWeight.w800)),
              if (mine) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: l.color, borderRadius: BorderRadius.circular(6)),
                  child: Text('TOI', style: body(9, weight: FontWeight.w800, color: Colors.white).copyWith(letterSpacing: 0.5)),
                ),
              ],
            ]),
            const SizedBox(height: 2),
            Text('$levelRange · $count joueur${count > 1 ? 's' : ''}',
                style: body(11.5, color: OC.muted, weight: FontWeight.w600)),
          ])),
          Icon(Icons.chevron_right_rounded, size: 20, color: OC.muted),
        ]),
      ),
    );
  }

  Future<void> _showLeagueSheet(League l) async {
    final list = await LeaderboardService.instance.top(league: l.name);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: OC.bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.8, minChildSize: 0.5, maxChildSize: 0.95, expand: false,
        builder: (_, ctrl) => ListView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: OC.line2, borderRadius: BorderRadius.circular(999)))),
            const SizedBox(height: 16),
            _leagueHeader(l, subtitle: 'Classement de la semaine'),
            const SizedBox(height: 14),
            if (list.isEmpty)
              const EmptyState(icon: Icons.leaderboard_rounded, title: 'Personne pour l\'instant', message: 'Cette ligue se remplira bientôt.')
            else
              for (final e in list) _rankRow(e, national: false),
          ],
        ),
      ),
    );
  }

  // ── Briques communes ─────────────────────────────────────────────────────────
  Widget _leagueHeader(League l, {required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [l.color, Color.lerp(l.color, Colors.black, 0.3)!]),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(children: [
        Container(
          width: 58, height: 58, alignment: Alignment.center,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle),
          child: Icon(l.icon, color: Colors.white, size: 30),
        ),
        const SizedBox(height: 10),
        Text('Ligue ${l.name}', style: display(20, weight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 4),
        Text(subtitle, textAlign: TextAlign.center,
            style: body(12.5, color: Colors.white.withValues(alpha: 0.9), weight: FontWeight.w600).copyWith(height: 1.4)),
      ]),
    );
  }

  Widget _miniCard(IconData ic, String value, String label) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: OC.line, width: 1.5)),
        child: Column(children: [
          Icon(ic, size: 18, color: OC.o600),
          const SizedBox(height: 6),
          FittedBox(child: Text(value, style: display(15, weight: FontWeight.w800))),
          const SizedBox(height: 1),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: body(9.5, color: OC.muted, weight: FontWeight.w600)),
        ]),
      );

  // Podium top 3 (2 · 1 · 3).
  Widget _podium(List<LeaderboardEntry> top3, {required bool national}) {
    LeaderboardEntry? at(int i) => i < top3.length ? top3[i] : null;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 14),
      decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(18), border: Border.all(color: OC.line, width: 1.5)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(child: _podiumCol(at(1), 2, 64, national)),
        Expanded(child: _podiumCol(at(0), 1, 84, national)),
        Expanded(child: _podiumCol(at(2), 3, 50, national)),
      ]),
    );
  }

  Widget _podiumCol(LeaderboardEntry? e, int place, double height, bool national) {
    final medal = place == 1 ? const Color(0xFFE3B341) : place == 2 ? const Color(0xFF9AA0A6) : const Color(0xFFCD7F32);
    if (e == null) return const SizedBox.shrink();
    final isMe = e.uid == _uid;
    return GestureDetector(
      onTap: () => _showUser(e),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (place == 1) Icon(Icons.emoji_events_rounded, color: medal, size: 22),
        const SizedBox(height: 4),
        Container(
          width: place == 1 ? 56 : 48, height: place == 1 ? 56 : 48, alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isMe ? OC.o600 : medal.withValues(alpha: 0.18), shape: BoxShape.circle,
            border: Border.all(color: medal, width: 2.5)),
          child: Text(e.initial, style: display(place == 1 ? 20 : 17, weight: FontWeight.w800, color: isMe ? Colors.white : medal)),
        ),
        const SizedBox(height: 6),
        Text(isMe ? 'Toi' : e.name, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
            style: body(11.5, weight: FontWeight.w800)),
        Text('${national ? e.xp : e.weeklyXp} XP', style: mono(10.5, weight: FontWeight.w700, color: OC.o700)),
        const SizedBox(height: 6),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: medal.withValues(alpha: 0.16),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 6),
          child: Text('$place', style: display(18, weight: FontWeight.w800, color: medal)),
        ),
      ]),
    );
  }

  Widget _rankRow(LeaderboardEntry e, {required bool national, bool promo = false, bool releg = false}) {
    final isMe = e.uid == _uid;
    final value = national ? '${e.xp} XP' : '${e.weeklyXp} XP';
    final zoneColor = promo ? OC.good : (releg ? OC.bad : null);
    return GestureDetector(
      onTap: () => _showUser(e),
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: isMe ? OC.o50 : OC.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isMe ? OC.o200 : OC.line, width: 1.5),
        ),
        child: Row(children: [
          SizedBox(width: 26, child: Text('${e.rank}', textAlign: TextAlign.center,
              style: display(14, weight: FontWeight.w800, color: zoneColor ?? OC.muted))),
          const SizedBox(width: 8),
          Container(
            width: 38, height: 38, alignment: Alignment.center,
            decoration: BoxDecoration(color: isMe ? OC.o600 : OC.panel, shape: BoxShape.circle),
            child: Text(e.initial, style: display(16, weight: FontWeight.w800, color: isMe ? Colors.white : OC.ink2)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isMe ? '${e.name} (toi)' : e.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: body(13.5, weight: FontWeight.w800, color: isMe ? OC.o700 : OC.ink)),
            Text('Niveau ${e.level} · ${leagueForLevel(e.level).name}',
                style: body(11, color: OC.muted, weight: FontWeight.w600)),
          ])),
          const SizedBox(width: 8),
          Text(value, style: mono(13, weight: FontWeight.w800, color: OC.ink2)),
          if (zoneColor != null) ...[
            const SizedBox(width: 6),
            Icon(promo ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 14, color: zoneColor),
          ],
        ]),
      ),
    );
  }

  // Fiche d'un élève (au tap).
  void _showUser(LeaderboardEntry e) {
    final l = leagueForLevel(e.level);
    final isMe = e.uid == _uid;
    showModalBottomSheet(
      context: context,
      backgroundColor: OC.bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: OC.line2, borderRadius: BorderRadius.circular(999))),
          const SizedBox(height: 20),
          Container(
            width: 80, height: 80, alignment: Alignment.center,
            decoration: BoxDecoration(color: isMe ? OC.o600 : l.color.withValues(alpha: 0.16), shape: BoxShape.circle, border: Border.all(color: l.color, width: 2.5)),
            child: Text(e.initial, style: display(34, weight: FontWeight.w800, color: isMe ? Colors.white : l.color)),
          ),
          const SizedBox(height: 12),
          Text(isMe ? '${e.name} (toi)' : e.name, style: display(19, weight: FontWeight.w800), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(l.icon, size: 16, color: l.color),
            const SizedBox(width: 6),
            Text('Ligue ${l.name} · Niveau ${e.level}', style: body(13, color: OC.ink2, weight: FontWeight.w700)),
          ]),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _miniCard(Icons.bolt_rounded, '${e.xp}', 'XP total')),
            const SizedBox(width: 10),
            Expanded(child: _miniCard(Icons.calendar_today_rounded, '${e.weeklyXp}', 'XP semaine')),
            const SizedBox(width: 10),
            Expanded(child: _miniCard(Icons.leaderboard_rounded, e.rank > 0 ? '#${e.rank}' : '—', 'Position')),
          ]),
        ]),
      ),
    );
  }
}
