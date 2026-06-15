import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';

const _exams = [
  ('Baccalauréat', 'Série D · 2026', 'Numéro de table', 'ex. 10428'),
  ('Probatoire', 'Série A · 2026', 'Numéro de table', 'ex. 20415'),
  ('BEPC', 'Session 2026', 'Numéro de table', 'ex. 30912'),
  ('GCE O Level', 'June 2026', 'Candidate number', 'ex. CMR-44012'),
  ('GCE A Level', 'June 2026', 'Candidate number', 'ex. CMR-51008'),
  ('BTS', 'Session 2026', 'Numéro de candidat', 'ex. 7781'),
  ('Université', 'Licence · S2', 'Matricule', 'ex. 21A234FS'),
];

class ResultsSearchScreen extends StatefulWidget {
  const ResultsSearchScreen({super.key});

  @override
  State<ResultsSearchScreen> createState() => _ResultsSearchScreenState();
}

class _ResultsSearchScreenState extends State<ResultsSearchScreen> {
  int _examIdx = 0;

  @override
  Widget build(BuildContext context) {
    final ex = _exams[_examIdx];
    return Scaffold(
      backgroundColor: OC.bg,
      appBar: AppBar(
        title: Text('Résultats', style: display(17, weight: FontWeight.w700)),
        backgroundColor: OC.bg,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, size: 20),
            color: OC.ink2,
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Exam selector
          Text(
            'EXAMEN OU CONCOURS',
            style: body(11, weight: FontWeight.w800, color: OC.muted).copyWith(letterSpacing: 0.1 * 11),
          ),
          const SizedBox(height: 7),
          GestureDetector(
            onTap: () => _showExamPicker(context),
            child: Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: OC.paper,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: OC.line2, width: 1.5),
                boxShadow: [BoxShadow(color: OC.ink.withOpacity(0.03), blurRadius: 2)],
              ),
              child: Row(children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(gradient: OC.grad, borderRadius: BorderRadius.circular(13),
                      boxShadow: [BoxShadow(color: OC.o500.withOpacity(0.28), blurRadius: 14, offset: const Offset(0, 6))]),
                  child: const Icon(Icons.school_outlined, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 13),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(ex.$1, style: display(16, weight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(ex.$2, style: body(12, weight: FontWeight.w600, color: OC.muted)),
                ])),
                Row(children: [
                  Text('Changer', style: body(12.5, weight: FontWeight.w700, color: OC.o600)),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: OC.o600, size: 17),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 13),

          // Search card
          OBCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              OBField(label: ex.$3, placeholder: ex.$4, icon: Icons.tag_rounded, focused: true),
              const SizedBox(height: 6),
              Text('Le numéro figure sur ta convocation d\'examen.', style: body(11.5, color: OC.muted, weight: FontWeight.w500)),
              const SizedBox(height: 11),
              OBField(
                label: 'Centre d\'examen (optionnel)',
                placeholder: 'Sélectionner…',
                icon: Icons.location_on_outlined,
                trailing: const Icon(Icons.keyboard_arrow_down_rounded, color: OC.muted, size: 18),
              ),
              const SizedBox(height: 13),
              Row(children: [
                Expanded(child: GestureDetector(
                  onTap: () => context.go('/results/success'),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: OC.grad,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: OC.o500.withOpacity(0.30), blurRadius: 14, offset: const Offset(0, 6))],
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('Voir mon résultat', style: body(14, weight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 17),
                    ]),
                  ),
                )),
              ]),
            ]),
          ),
          const SizedBox(height: 13),

          // Followed
          Text('Résultats suivis', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
          const SizedBox(height: 8),
          OBCard(
            child: Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: OC.o50, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: OC.o100, width: 1.5),
                ),
                child: const Icon(Icons.school_outlined, color: OC.o600, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Baccalauréat 2026', style: body(14, weight: FontWeight.w700)),
                const SizedBox(height: 3),
                Row(children: [
                  Container(width: 7, height: 7, decoration: const BoxDecoration(color: OC.warn, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('Publication prévue dans ~2 jours', style: body(12, color: OC.ink2, weight: FontWeight.w500)),
                ]),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(color: OC.o50, borderRadius: BorderRadius.circular(999), border: Border.all(color: OC.o100, width: 1.5)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.notifications_outlined, size: 14, color: OC.o600),
                  const SizedBox(width: 5),
                  Text('Alerte', style: body(11.5, weight: FontWeight.w700, color: OC.o700)),
                ]),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  void _showExamPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: OC.bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 44, height: 5, decoration: BoxDecoration(color: OC.line2, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 14),
            Text('Choisis ton examen', style: display(19, weight: FontWeight.w600), textAlign: TextAlign.center),
            const SizedBox(height: 14),
            ...List.generate(_exams.length, (i) {
              final e = _exams[i];
              final sel = i == _examIdx;
              return GestureDetector(
                onTap: () { setState(() => _examIdx = i); Navigator.pop(context); },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 9),
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: OC.paper,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: sel ? OC.o500 : OC.line, width: sel ? 2 : 1.5),
                    boxShadow: sel ? [BoxShadow(color: OC.o50, blurRadius: 0, spreadRadius: 3)] : null,
                  ),
                  child: Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        gradient: sel ? OC.grad : null,
                        color: sel ? null : OC.panel,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.school_outlined, color: sel ? Colors.white : OC.ink2, size: 21),
                    ),
                    const SizedBox(width: 13),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e.$1, style: body(14.5, weight: FontWeight.w700)),
                      Text(e.$2, style: body(12, color: OC.muted, weight: FontWeight.w500)),
                    ])),
                    if (sel)
                      Container(
                        width: 24, height: 24,
                        decoration: const BoxDecoration(color: OC.o500, shape: BoxShape.circle),
                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 15),
                      )
                    else
                      Container(width: 22, height: 22, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: OC.line2, width: 2))),
                  ]),
                ),
              );
            }),
          ]),
        ),
      ),
    );
  }
}
