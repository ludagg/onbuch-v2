import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ob_widgets.dart';
import '../../services/firestore_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  int _level = 3; // Terminale
  int _exam = 0;  // Baccalauréat
  bool _saving = false;

  final _firestoreService = FirestoreService();

  static const _levels = ['3ème', '2nde', '1ère', 'Terminale', 'Sup. / Fac'];
  static const _exams  = ['Baccalauréat', 'Probatoire', 'GCE A Level', 'BTS', 'Concours (ENS…)'];

  Future<void> _saveAndContinue() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      context.go('/welcome');
      return;
    }

    setState(() => _saving = true);
    try {
      await _firestoreService.createUserProfile(
        uid,
        classe: _levels[_level],
        examen: _exams[_exam],
      );
      if (mounted) context.go('/welcome');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sauvegarde : $e'),
          backgroundColor: OC.bad,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(12),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OC.bg,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: Row(children: [
              ProgressDots(count: 3, active: 2),
              const Spacer(),
              Text('Étape 3/3', style: body(13, weight: FontWeight.w700, color: OC.muted)),
            ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Parle-nous de toi', style: display(25, weight: FontWeight.w700)),
                const SizedBox(height: 7),
                Text('Pour adapter ton tuteur et tes alertes. Modifiable à tout moment.',
                    style: body(14.5, color: OC.ink2).copyWith(height: 1.4)),
                const SizedBox(height: 22),

                // Level picker
                Text('Ta classe / niveau', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
                const SizedBox(height: 11),
                Wrap(spacing: 9, runSpacing: 9, children: List.generate(_levels.length, (i) {
                  final on = i == _level;
                  return GestureDetector(
                    onTap: () => setState(() => _level = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: on ? OC.o50 : OC.paper,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: on ? OC.o500 : OC.line2, width: 1.5),
                      ),
                      child: Text(_levels[i], style: body(13.5, weight: FontWeight.w700, color: on ? OC.o700 : OC.ink2)),
                    ),
                  );
                })),
                const SizedBox(height: 22),

                // Exam picker
                Text('Examen / concours visé', style: body(13, weight: FontWeight.w800, color: OC.ink2)),
                const SizedBox(height: 11),
                Wrap(spacing: 9, runSpacing: 9, children: List.generate(_exams.length, (i) {
                  final on = i == _exam;
                  return GestureDetector(
                    onTap: () => setState(() => _exam = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: on ? OC.o50 : OC.paper,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: on ? OC.o500 : OC.line2, width: 1.5),
                      ),
                      child: Text(_exams[i], style: body(13.5, weight: FontWeight.w700, color: on ? OC.o700 : OC.ink2)),
                    ),
                  );
                })),
                const SizedBox(height: 22),

                // Series field
                OBField(
                  label: 'Série (optionnel)',
                  placeholder: 'D — Sciences & Mathématiques',
                  trailing: const Icon(Icons.keyboard_arrow_down_rounded, color: OC.muted, size: 20),
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
            decoration: const BoxDecoration(
              color: OC.paper,
              border: Border(top: BorderSide(color: OC.line, width: 1.5)),
            ),
            child: Column(children: [
              GestureDetector(
                onTap: _saving ? null : _saveAndContinue,
                child: Container(
                  width: double.infinity, height: 50,
                  decoration: BoxDecoration(
                    gradient: OC.grad,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: OC.o500.withOpacity(0.30), blurRadius: 14, offset: const Offset(0, 6))],
                  ),
                  child: _saving
                      ? const Center(child: SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        ))
                      : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text('Entrer dans OnBuch', style: body(14, weight: FontWeight.w700, color: Colors.white)),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 17),
                        ]),
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => context.go('/home'),
                child: Center(child: Text('Plus tard', style: body(13.5, weight: FontWeight.w600, color: OC.muted))),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
