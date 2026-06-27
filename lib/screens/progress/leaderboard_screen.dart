import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../widgets/states.dart';
import '../../services/auth_service.dart';
import '../../services/gamification_service.dart';
import '../../services/leaderboard_service.dart';

/// Classement / ligues (façon Duolingo) : l'élève est rangé dans une ligue selon
/// son niveau, et classé chaque semaine selon le XP gagné. Le top monte d'une
/// ligue ; objectif : pousser à revenir pour grimper au classement.
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  static const int _promoZone = 10; // top 10 montent en ligue supérieure

  bool _loading = true;
  League _league = kLeagues.first;
  List<LeaderboardEntry> _entries = const [];
  String? _uid;
  int _myRank = 0;

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

      if (user != null) {
        _uid = user.$id;
        final name = user.name.trim().isNotEmpty ? user.name.trim() : 'Élève';
        await LeaderboardService.instance.submit(
          uid: _uid!, name: name, level: g.level, xp: g.xp, weeklyXp: weekly);
        var list = await LeaderboardService.instance.top(league: league.name);
        // Filet de sécurité : s'assurer que l'élève figure bien au classement.
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
      }
      _league = league;
    } catch (_) {/* hors-ligne → état vide */}
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
                  _leagueHeader(),
                  const SizedBox(height: 16),
                  _ligueRow(),
                  const SizedBox(height: 14),
                  if (_entries.isEmpty)
                    const EmptyState(
                      icon: Icons.leaderboard_rounded,
                      title: 'Classement en préparation',
                      message: 'Gagne du XP cette semaine pour apparaître dans ta ligue. '
                          'Reviens demain, d\'autres élèves arrivent !',
                    )
                  else
                    for (var i = 0; i < _entries.length; i++)
                      _rankRow(_entries[i], i),
                ],
              ),
            ),
    );
  }

  // En-tête : grand badge de ligue + nom + règle de promotion.
  Widget _leagueHeader() {
    final c = _league.color;
    final idx = kLeagues.indexOf(_league);
    final isTop = idx == kLeagues.length - 1;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [c, Color.lerp(c, Colors.black, 0.3)!]),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(children: [
        Container(
          width: 64, height: 64, alignment: Alignment.center,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle),
          child: Icon(_league.icon, color: Colors.white, size: 34),
        ),
        const SizedBox(height: 10),
        Text('Ligue ${_league.name}', style: display(20, weight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 4),
        Text(
          isTop
              ? 'Tu es dans la ligue la plus prestigieuse 👑'
              : 'Le top $_promoZone monte en ligue supérieure cette semaine',
          textAlign: TextAlign.center,
          style: body(12.5, color: Colors.white.withValues(alpha: 0.9), weight: FontWeight.w600).copyWith(height: 1.4),
        ),
      ]),
    );
  }

  // Bandeau : ma position + XP de la semaine.
  Widget _ligueRow() {
    final me = _entries.where((e) => e.uid == _uid).toList();
    final myXp = me.isEmpty ? 0 : me.first.weeklyXp;
    return Container(
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
    );
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

  Widget _rankRow(LeaderboardEntry e, int i) {
    final isMe = e.uid == _uid;
    final inPromo = e.rank <= _promoZone;
    // Ligne « zone de promotion » : trait après le dernier promu.
    final showPromoDivider = e.rank == _promoZone && _entries.length > _promoZone &&
        kLeagues.indexOf(_league) < kLeagues.length - 1;

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
            decoration: BoxDecoration(
              color: isMe ? OC.o600 : OC.panel, shape: BoxShape.circle),
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
          Text('${e.weeklyXp} XP', style: mono(13, weight: FontWeight.w800, color: OC.ink2)),
        ]),
      ),
      if (showPromoDivider)
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
