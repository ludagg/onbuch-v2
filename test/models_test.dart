// Tests unitaires purs (sans réseau) sur la logique métier des modèles et
// utilitaires. Verrouillent les parsers `fromMap` et les getters dérivés.
import 'package:flutter_test/flutter_test.dart';
import 'package:onbuch/models/course.dart';
import 'package:onbuch/models/article.dart';
import 'package:onbuch/models/exam.dart';
import 'package:onbuch/models/calendar_event.dart';
import 'package:onbuch/services/database_service.dart';

void main() {
  group('Course.fromMap', () {
    test('lecture défensive : map vide → valeurs par défaut', () {
      final c = Course.fromMap({}, id: 'a', createdAtFallback: '2026-01-01T00:00:00.000Z');
      expect(c.id, 'a');
      expect(c.title, '');
      expect(c.subject, CourseSubject.maths);
      expect(c.kind, 'cours');
      expect(c.isFiche, isFalse);
      expect(c.order, 0);
      expect(c.premium, isFalse);
      expect(c.body, isNull);
    });

    test('parse la matière depuis la clé', () {
      expect(Course.fromMap({'subject': 'pc'}, id: '1', createdAtFallback: '').subject,
          CourseSubject.pc);
      expect(Course.fromMap({'subject': 'histgeo'}, id: '1', createdAtFallback: '').subject,
          CourseSubject.histgeo);
      // Clé inconnue → repli sur maths
      expect(Course.fromMap({'subject': 'zzz'}, id: '1', createdAtFallback: '').subject,
          CourseSubject.maths);
    });

    test('kind=fiche → isFiche', () {
      final c = Course.fromMap({'kind': 'fiche'}, id: '1', createdAtFallback: '');
      expect(c.isFiche, isTrue);
    });

    test('order accepte un entier sous forme de chaîne', () {
      expect(Course.fromMap({'order': '7'}, id: '1', createdAtFallback: '').order, 7);
      expect(Course.fromMap({'order': 3}, id: '1', createdAtFallback: '').order, 3);
    });

    test('readTimeMinutes : corps vide → 1 min', () {
      expect(Course.fromMap({}, id: '1', createdAtFallback: '').readTimeMinutes, 1);
    });

    test('readTimeMinutes croît avec le nombre de mots', () {
      final body = List.filled(400, 'mot').join(' ');
      final c = Course.fromMap({'body': body}, id: '1', createdAtFallback: '');
      expect(c.readTimeMinutes, 2); // 400 mots / 200 = 2
    });
  });

  group('Course.matchesProfile', () {
    Course make({String? classe, String? serie}) => Course.fromMap(
          {'classe': classe, 'serie': serie},
          id: '1',
          createdAtFallback: '',
        );

    test('champ cours vide → s\'applique à tout le monde', () {
      expect(make().matchesProfile(profileClasse: 'Terminale', profileSerie: 'D'), isTrue);
    });

    test('même classe/série → match', () {
      final c = make(classe: 'Terminale', serie: 'D');
      expect(c.matchesProfile(profileClasse: 'terminale', profileSerie: 'd'), isTrue);
    });

    test('classe différente → pas de match', () {
      final c = make(classe: 'Terminale');
      expect(c.matchesProfile(profileClasse: 'Première'), isFalse);
    });

    test('profil non renseigné → ne masque pas le contenu', () {
      final c = make(classe: 'Terminale', serie: 'D');
      expect(c.matchesProfile(profileClasse: '', profileSerie: ''), isTrue);
      expect(c.matchesProfile(), isTrue);
    });
  });

  group('CourseSubjectX', () {
    test('clé ↔ enum cohérents pour toutes les matières', () {
      for (final s in CourseSubject.values) {
        expect(s.label, isNotEmpty);
        expect(s.tileKey, isNotEmpty);
        expect(s.key, isNotEmpty);
      }
    });
  });

  group('Article', () {
    Article make(String? body) => Article(
          id: '1',
          category: 'Actu',
          title: 't',
          source: 's',
          publishedAt: DateTime(2026, 1, 1),
          body: body,
        );

    test('paragraphs découpe sur les retours ligne et ignore le vide', () {
      final a = make('Para un.\n\nPara deux.\n  \nPara trois.');
      expect(a.paragraphs, ['Para un.', 'Para deux.', 'Para trois.']);
    });

    test('paragraphs vide quand pas de corps', () {
      expect(make(null).paragraphs, isEmpty);
    });

    test('readTimeMinutes au minimum 1', () {
      expect(make('').readTimeMinutes, 1);
    });
  });

  group('Exam.state', () {
    test('status forcé prime sur les dates', () {
      final e = Exam(id: '1', label: 'Bac', examDate: DateTime(2000), status: 'upcoming');
      expect(e.state, ExamState.upcoming);
    });

    test('auto : épreuve à venir → upcoming, cible = date d\'épreuve', () {
      final future = DateTime.now().add(const Duration(days: 10));
      final e = Exam(id: '1', label: 'Bac', examDate: future);
      expect(e.state, ExamState.upcoming);
      expect(e.countdownTarget, future);
    });

    test('auto : épreuve passée sans date de résultats → awaiting', () {
      final past = DateTime.now().subtract(const Duration(days: 2));
      final e = Exam(id: '1', label: 'Bac', examDate: past);
      expect(e.state, ExamState.awaiting);
    });

    test('auto : résultats publiés → resultsAvailable, pas de compte à rebours', () {
      final e = Exam(
        id: '1',
        label: 'Bac',
        examDate: DateTime.now().subtract(const Duration(days: 5)),
        resultsDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(e.state, ExamState.resultsAvailable);
      expect(e.countdownTarget, isNull);
    });
  });

  group('CalendarEvent', () {
    test('coversDay vrai dans l\'intervalle, faux en dehors', () {
      final ev = CalendarEvent(
        id: '1',
        title: 'Compo',
        type: CalendarEventType.composition,
        start: DateTime(2026, 3, 10),
        end: DateTime(2026, 3, 12),
      );
      expect(ev.coversDay(DateTime(2026, 3, 10)), isTrue);
      expect(ev.coversDay(DateTime(2026, 3, 11)), isTrue);
      expect(ev.coversDay(DateTime(2026, 3, 12)), isTrue);
      expect(ev.coversDay(DateTime(2026, 3, 9)), isFalse);
      expect(ev.coversDay(DateTime(2026, 3, 13)), isFalse);
    });

    test('isRange distingue jour unique et intervalle', () {
      final single = CalendarEvent(
        id: '1', title: 'x', type: CalendarEventType.info,
        start: DateTime(2026, 3, 10), end: DateTime(2026, 3, 10),
      );
      final range = CalendarEvent(
        id: '2', title: 'y', type: CalendarEventType.conge,
        start: DateTime(2026, 3, 10), end: DateTime(2026, 3, 20),
      );
      expect(single.isRange, isFalse);
      expect(range.isRange, isTrue);
    });

    test('fromMap : endDate manquante → end = start', () {
      final ev = CalendarEvent.fromMap(
        {'title': 'Rentrée', 'type': 'rentree', 'startDate': '2026-09-01T00:00:00.000'},
        id: '1',
      );
      expect(ev.type, CalendarEventType.rentree);
      expect(ev.isRange, isFalse);
    });
  });

  group('DatabaseService.splitFullName', () {
    test('découpe prénom / nom', () {
      expect(DatabaseService.splitFullName('Awa Ngono'),
          {'firstName': 'Awa', 'lastName': 'Ngono'});
    });

    test('nom composé → reste dans lastName', () {
      expect(DatabaseService.splitFullName('Jean Paul Mbarga'),
          {'firstName': 'Jean', 'lastName': 'Paul Mbarga'});
    });

    test('chaîne vide → valeur de repli', () {
      expect(DatabaseService.splitFullName('   '),
          {'firstName': 'Utilisateur', 'lastName': ''});
    });
  });
}
