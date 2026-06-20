import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/concours.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/analytics_service.dart';

/// Parcours d'inscription à un concours (section C des wireframes) :
/// éligibilité → infos → documents → paiement Mobile Money → confirmation.
class ConcoursInscriptionScreen extends StatefulWidget {
  final Concours? concours;
  const ConcoursInscriptionScreen({super.key, this.concours});

  @override
  State<ConcoursInscriptionScreen> createState() => _ConcoursInscriptionScreenState();
}

class _ConcoursInscriptionScreenState extends State<ConcoursInscriptionScreen> {
  final _auth = AuthService();
  final _db = DatabaseService();

  int _step = 0; // 0=éligibilité, 1..3=étapes, 4=confirmation
  bool _paying = false;
  int _pay = 0; // 0=MTN, 1=Orange

  final _name = TextEditingController();
  final _serie = TextEditingController();
  final _birth = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();

  final _docs = [
    ['Acte de naissance', 'true'],
    ['Relevé de notes', 'true'],
    ['Photo 4×4', 'false'],
    ['Reçu de paiement', 'false'],
  ];

  String _classe = '';
  String? _receipt;
  bool _saved = false;

  Concours get c => widget.concours ?? const Concours(id: '-', name: 'Concours', organizer: '');

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  @override
  void dispose() {
    for (final ctl in [_name, _serie, _birth, _phone, _city]) {
      ctl.dispose();
    }
    super.dispose();
  }

  Future<void> _prefill() async {
    final user = await _auth.getCurrentUser();
    Map<String, dynamic>? p;
    if (user != null) p = await _db.getUserProfile(user.$id);
    if (!mounted) return;
    var name = user?.name.trim() ?? '';
    if (name.isEmpty && p != null) {
      name = [p['firstName'], p['lastName']].where((x) => (x ?? '').toString().trim().isNotEmpty).join(' ');
    }
    setState(() {
      _name.text = name;
      _serie.text = (p?['serie'] ?? '').toString();
      _phone.text = (p?['phoneNumber'] ?? '').toString();
      _city.text = (p?['city'] ?? '').toString();
      _classe = (p?['classe'] ?? '').toString();
    });
  }

  Future<void> _pickDoc(int i) async {
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (x != null && mounted) setState(() => _docs[i][1] = 'true');
    } catch (_) {}
  }

  Future<void> _payAndSubmit() async {
    setState(() => _paying = true);
    await Future.delayed(const Duration(milliseconds: 1300)); // simulation paiement
    final rnd = Random().nextInt(90000) + 10000;
    final receipt = 'OB-${DateTime.now().year}-$rnd';
    try {
      final user = await _auth.getCurrentUser();
      if (user != null) {
        await _db.createApplication(
          uid: user.$id,
          concoursId: c.id,
          concoursName: c.name,
          examLabel: c.examDate == null ? null : DateFormat('d MMM', 'fr_FR').format(c.examDate!),
          receiptNo: receipt,
        );
        _saved = true;
        AnalyticsService.logEvent('concours_apply', {'concours': c.name});
      }
    } catch (_) {
      _saved = false;
    }
    if (!mounted) return;
    setState(() {
      _receipt = receipt;
      _paying = false;
      _step = 4;
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = _step == 0
        ? 'Mon éligibilité'
        : _step == 4
            ? 'Inscription'
            : 'Inscription · $_step/4';
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: AppBar(
        backgroundColor: OC.bg,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            if (_step > 0 && _step < 4) {
              setState(() => _step -= 1);
            } else {
              context.canPop() ? context.pop() : context.go('/concours');
            }
          },
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: display(16, weight: FontWeight.w700)),
          Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: body(11, color: OC.muted, weight: FontWeight.w500)),
        ]),
      ),
      body: Column(children: [
        if (_step >= 1 && _step <= 3) _progress(),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: _stepBody(),
        )),
        if (_step != 4) _bottom(),
      ]),
    );
  }

  Widget _progress() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: _step / 4,
          minHeight: 6,
          backgroundColor: OC.panel,
          valueColor: const AlwaysStoppedAnimation(OC.o500),
        ),
      ),
    );
  }

  Widget _stepBody() {
    switch (_step) {
      case 1:
        return _infos();
      case 2:
        return _documents();
      case 3:
        return _paiement();
      case 4:
        return _confirmation();
      default:
        return _eligibilite();
    }
  }

  // ── 0 · Éligibilité ──
  Widget _eligibilite() {
    final rows = [
      ('Diplôme requis', _serie.text.isEmpty ? 'Bac' : 'Bac ${_serie.text}'),
      ('Classe actuelle', _classe.isEmpty ? '—' : _classe),
      ('Série compatible', _serie.text.isEmpty ? 'À vérifier' : '${_serie.text} ✓'),
      ('Dossier', 'Avant la clôture'),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: OC.goodBg, borderRadius: BorderRadius.circular(18)),
        child: Column(children: [
          const Icon(Icons.verified_rounded, size: 36, color: OC.good),
          const SizedBox(height: 8),
          Text('Profil éligible', style: display(20, weight: FontWeight.w700, color: OC.waInk)),
          const SizedBox(height: 4),
          Text(_name.text.isEmpty ? 'Selon ton profil OnBuch' : 'Selon le profil de ${_name.text}',
              textAlign: TextAlign.center, style: body(12.5, color: OC.waInk, weight: FontWeight.w500)),
        ]),
      ),
      const SizedBox(height: 16),
      ...rows.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: Row(children: [
              const Icon(Icons.check_circle_rounded, size: 17, color: OC.o500),
              const SizedBox(width: 10),
              Expanded(child: Text(r.$1, style: body(13, color: OC.ink2, weight: FontWeight.w500))),
              Text(r.$2, style: body(13, weight: FontWeight.w700)),
            ]),
          )),
      _note('Pré-vérification indicative à partir de ton profil. Les conditions officielles font foi.'),
    ]);
  }

  // ── 1 · Infos ──
  Widget _infos() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _field('Nom & prénom', _name),
      _field('Date de naissance', _birth, hint: 'JJ/MM/AAAA'),
      _field('Série du Bac', _serie),
      _field('Téléphone', _phone, hint: '+237…', keyboard: TextInputType.phone),
      _field('Ville', _city),
      _note('Pré-rempli depuis ton profil OnBuch — modifie si besoin.'),
    ]);
  }

  // ── 2 · Documents ──
  Widget _documents() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Pièces à joindre', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
      const SizedBox(height: 12),
      ...List.generate(_docs.length, (i) {
        final added = _docs[i][1] == 'true';
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: OC.paper,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: added ? OC.o100 : OC.line2, width: 1.5),
          ),
          child: Row(children: [
            Icon(added ? Icons.check_circle_rounded : Icons.upload_file_outlined,
                size: 20, color: added ? OC.o500 : OC.muted),
            const SizedBox(width: 11),
            Expanded(child: Text(_docs[i][0], style: body(13, weight: FontWeight.w600))),
            GestureDetector(
              onTap: () => _pickDoc(i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: added ? OC.o50 : OC.panel,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(added ? 'Remplacer' : 'Importer',
                    style: body(11.5, weight: FontWeight.w700, color: added ? OC.o700 : OC.ink2)),
              ),
            ),
          ]),
        );
      }),
      _note('Photo ou scan de chaque pièce. Stockage sécurisé à venir.'),
    ]);
  }

  // ── 3 · Paiement ──
  Widget _paiement() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: OC.panel, borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Expanded(child: Text('Frais de dossier', style: body(13, color: OC.ink2, weight: FontWeight.w600))),
          Text('10 000 FCFA', style: display(17, weight: FontWeight.w800)),
        ]),
      ),
      const SizedBox(height: 16),
      Text('Mode de paiement', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
      const SizedBox(height: 10),
      _payOption(0, 'MTN MoMo', const Color(0xFFFFCB05), 'MTN', Colors.black),
      const SizedBox(height: 9),
      _payOption(1, 'Orange Money', const Color(0xFFFF6600), 'OM', Colors.white),
      const SizedBox(height: 12),
      _note('Paiement Mobile Money — intégration de l\'opérateur en cours. Cette étape est simulée pour l\'instant.'),
    ]);
  }

  Widget _payOption(int i, String label, Color brand, String code, Color codeColor) {
    final on = _pay == i;
    return GestureDetector(
      onTap: () => setState(() => _pay = i),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: OC.paper,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: on ? OC.o500 : OC.line2, width: on ? 2 : 1.5),
        ),
        child: Row(children: [
          Container(
            width: 34, height: 24, alignment: Alignment.center,
            decoration: BoxDecoration(color: brand, borderRadius: BorderRadius.circular(5)),
            child: Text(code, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: codeColor)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: body(13.5, weight: FontWeight.w700))),
          Icon(on ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              size: 20, color: on ? OC.o500 : OC.muted),
        ]),
      ),
    );
  }

  // ── 4 · Confirmation ──
  Widget _confirmation() {
    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      const SizedBox(height: 8),
      Container(
        width: 64, height: 64,
        decoration: const BoxDecoration(color: OC.goodBg, shape: BoxShape.circle),
        child: const Icon(Icons.check_rounded, size: 36, color: OC.good),
      ),
      const SizedBox(height: 14),
      Text('Candidature envoyée !', style: display(22, weight: FontWeight.w700), textAlign: TextAlign.center),
      const SizedBox(height: 6),
      Text(_receipt == null ? '' : 'Récépissé n° $_receipt',
          style: body(13, color: OC.ink2, weight: FontWeight.w600)),
      if (!_saved) ...[
        const SizedBox(height: 6),
        Text('(non enregistrée — connecte-toi pour suivre ta candidature)',
            textAlign: TextAlign.center, style: body(11.5, color: OC.muted, weight: FontWeight.w500)),
      ],
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: OC.paper, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: OC.line, width: 1.5)),
        child: Column(children: [
          _confRow('Concours', c.name),
          const SizedBox(height: 9),
          _confRow('Statut', 'Soumis'),
          if (c.examDate != null) ...[
            const SizedBox(height: 9),
            _confRow('Écrits le', DateFormat('d MMMM y', 'fr_FR').format(c.examDate!)),
          ],
        ]),
      ),
      const SizedBox(height: 18),
      Row(children: [
        Expanded(child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: OC.line2, width: 1.5),
            foregroundColor: OC.ink,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          icon: const Icon(Icons.track_changes_rounded, size: 18),
          label: const Text('Mes candidatures', style: TextStyle(fontWeight: FontWeight.w700)),
          onPressed: () => context.go('/mes-candidatures'),
        )),
      ]),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: OC.o500, foregroundColor: Colors.white, elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: () => context.go('/concours-prep', extra: c),
          child: const Text('Préparer ce concours', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
    ]);
  }

  Widget _confRow(String l, String v) => Row(children: [
        Expanded(child: Text(l, style: body(12, color: OC.ink2, weight: FontWeight.w500))),
        Flexible(child: Text(v, maxLines: 1, overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right, style: body(12.5, weight: FontWeight.w700))),
      ]);

  // ── Bottom CTA ──
  Widget _bottom() {
    String label;
    VoidCallback? onTap;
    switch (_step) {
      case 0:
        label = 'Lancer mon inscription';
        onTap = () => setState(() => _step = 1);
        break;
      case 1:
        label = 'Continuer';
        onTap = () => setState(() => _step = 2);
        break;
      case 2:
        label = 'Continuer';
        onTap = () => setState(() => _step = 3);
        break;
      default:
        label = 'Payer 10 000 FCFA';
        onTap = _paying ? null : _payAndSubmit;
    }
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              gradient: OC.grad,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: OC.o500.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 6))],
            ),
            child: Center(
              child: _paying
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                  : Text(label, style: body(14.5, weight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctl, {String? hint, TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: body(12, weight: FontWeight.w700, color: OC.ink2)),
        const SizedBox(height: 6),
        TextField(
          controller: ctl,
          keyboardType: keyboard,
          style: body(14, color: OC.ink, weight: FontWeight.w600),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: body(14, color: OC.muted),
            contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
            filled: true,
            fillColor: OC.paper,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: OC.line2, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: OC.o500, width: 2),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _note(String t) => Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(11)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.info_outline_rounded, size: 15, color: OC.o600),
          const SizedBox(width: 8),
          Expanded(child: Text(t, style: body(11.5, color: OC.o700, weight: FontWeight.w600).copyWith(height: 1.35))),
        ]),
      );
}
