import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../widgets/skeletons.dart';
import '../../models/app_notification.dart';
import '../../services/notifications_service.dart';

/// Centre de notifications. Liste les notifications (gérées côté admin) et
/// suit l'état « lu / non lu » localement.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = NotificationsService();

  List<AppNotification>? _items;
  Set<String> _read = <String>{};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _service.fetch(limit: 40);
    final read = await _service.readIds();
    if (!mounted) return;
    setState(() {
      _items = items;
      _read = read;
      _loading = false;
    });
  }

  int get _unread =>
      (_items ?? const <AppNotification>[]).where((n) => !_read.contains(n.id)).length;

  Future<void> _markAllRead() async {
    final items = _items ?? const <AppNotification>[];
    if (items.isEmpty) return;
    await _service.markAllRead(items.map((n) => n.id));
    if (!mounted) return;
    setState(() => _read = {..._read, ...items.map((n) => n.id)});
  }

  Future<void> _open(AppNotification n) async {
    if (!_read.contains(n.id)) {
      await _service.markRead(n.id);
      if (mounted) setState(() => _read = {..._read, n.id});
    }
    final route = n.route;
    if (route != null && route.startsWith('/') && mounted) {
      context.push(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: AppBar(
        title: Text('Notifications', style: display(17, weight: FontWeight.w700)),
        backgroundColor: OC.bg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        actions: [
          if (_unread > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text('Tout lire',
                  style: body(13, weight: FontWeight.w700, color: OC.o600)),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: OC.o500,
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        children: const [SkeletonList(count: 6)],
      );
    }
    final items = _items ?? const <AppNotification>[];
    if (items.isEmpty) return _empty();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final n = items[i];
        return _NotifTile(
          notif: n,
          unread: !_read.contains(n.id),
          onTap: () => _open(n),
        );
      },
    );
  }

  Widget _empty() {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Column(children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: OC.o50, shape: BoxShape.circle),
            child: const Icon(Icons.notifications_none_rounded, size: 36, color: OC.o500),
          ),
          const SizedBox(height: 16),
          Text('Aucune notification', style: display(18, weight: FontWeight.w700)),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Tes alertes (résultats, examens, crédits…) s\'afficheront ici.',
              textAlign: TextAlign.center,
              style: body(13.5, color: OC.muted, weight: FontWeight.w500),
            ),
          ),
        ]),
      ],
    );
  }
}

/// Style (icône + couleurs) selon le type de notification.
class _NotifStyle {
  final IconData icon;
  final Color accent, bg;
  const _NotifStyle(this.icon, this.accent, this.bg);
}

_NotifStyle _styleFor(String type) {
  switch (type) {
    case 'result':
      return const _NotifStyle(Icons.celebration_rounded, OC.good, OC.goodBg);
    case 'exam':
      return const _NotifStyle(Icons.event_available_rounded, OC.o600, OC.o50);
    case 'credit':
      return const _NotifStyle(Icons.paid_rounded, OC.warn, OC.warnBg);
    case 'course':
      return const _NotifStyle(Icons.menu_book_rounded, OC.waInk, OC.goodBg);
    case 'promo':
      return const _NotifStyle(Icons.local_offer_rounded, OC.blue, OC.blueBg);
    default:
      return const _NotifStyle(Icons.notifications_rounded, OC.o500, OC.o50);
  }
}

class _NotifTile extends StatelessWidget {
  final AppNotification notif;
  final bool unread;
  final VoidCallback onTap;
  const _NotifTile({required this.notif, required this.unread, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = _styleFor(notif.type);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: unread ? OC.o50.withValues(alpha: 0.6) : OC.paper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: unread ? OC.o100 : OC.line, width: 1.5),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: s.bg, borderRadius: BorderRadius.circular(12)),
            child: Icon(s.icon, size: 21, color: s.accent),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(
                    notif.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: body(14, weight: unread ? FontWeight.w800 : FontWeight.w700)
                        .copyWith(height: 1.2),
                  ),
                ),
                if (unread) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 9, height: 9,
                    margin: const EdgeInsets.only(top: 3),
                    decoration: const BoxDecoration(color: OC.o500, shape: BoxShape.circle),
                  ),
                ],
              ]),
              if (notif.body.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(notif.body,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: body(12.5, color: OC.ink2, weight: FontWeight.w500).copyWith(height: 1.35)),
              ],
              const SizedBox(height: 7),
              Text(timeAgo(notif.createdAt),
                  style: body(11, color: OC.muted, weight: FontWeight.w600)),
            ]),
          ),
        ]),
      ),
    );
  }
}
