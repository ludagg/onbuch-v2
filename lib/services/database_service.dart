// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:http/http.dart' as http;
import '../appwrite_config.dart';
import 'disk_cache.dart';
import '../models/article.dart';
import '../models/exam.dart';
import '../models/home_announcement.dart';
import '../models/calendar_event.dart';
import '../models/concours.dart';
import '../models/concours_application.dart';
import '../models/prep_center.dart';
import '../models/concours_resource.dart';
import '../models/course.dart';
import '../models/quiz.dart';
import '../models/review.dart';
import '../models/affiche.dart';
import '../models/app_notification.dart';
import '../models/exam_result.dart';
import '../models/result_source.dart';
import '../models/exam_series.dart';
import '../models/social_link.dart';
import '../models/annale.dart';
import 'appwrite_client.dart';

class DatabaseService {
  // ── Cache mémoire (contenu global, partagé pour la session) ───────────────
  static final Map<String, _CacheEntry> _cache = {};
  static const _cacheTtl = Duration(minutes: 5);

  /// Renvoie le contenu depuis le cache mémoire (si frais), sinon le récupère
  /// via [fetchRaw] (documents bruts) et le construit avec [build].
  ///
  /// Stratégie hors-ligne en 3 couches : **mémoire** (5 min) → **réseau** →
  /// **disque** (dernier contenu connu). Le résultat réseau (même vide) fait
  /// autorité ; on ne bascule sur le disque qu'en cas d'**échec réseau**, pour
  /// que l'app reste utilisable sans connexion, y compris après redémarrage.
  Future<List<T>> _cachedList<T>(
    String key,
    Future<List<Map<String, dynamic>>> Function() fetchRaw,
    List<T> Function(List<Map<String, dynamic>> raw) build, {
    bool force = false,
  }) async {
    final e = _cache[key];
    if (!force && e != null && DateTime.now().difference(e.at) < _cacheTtl) {
      return (e.data as List).cast<T>();
    }
    try {
      final raw = await fetchRaw();
      final built = build(raw);
      if (raw.isNotEmpty) {
        _cache[key] = _CacheEntry(built, DateTime.now());
        unawaited(DiskCache.writeList(key, raw));
      }
      return built; // succès (même vide) → fait autorité
    } catch (_) {
      // Échec réseau : on sert le dernier contenu connu (mémoire puis disque).
      if (e != null) return (e.data as List).cast<T>();
      final disk = await DiskCache.readList(key);
      if (disk != null && disk.isNotEmpty) {
        final built = build(disk);
        _cache[key] = _CacheEntry(built, DateTime.now());
        return built;
      }
      return <T>[];
    }
  }

  /// Vide le cache mémoire (ex. rafraîchissement manuel). Le cache disque, lui,
  /// est conservé (repli hors-ligne) et n'est purgé qu'à la déconnexion.
  static void clearCache() => _cache.clear();

  /// Connecté à Internet ? Sonde légère via Appwrite : une réponse serveur
  /// (même 401) prouve la connectivité ; seule une erreur réseau = hors-ligne.
  static Future<bool> isOnline() async {
    try {
      await AppwriteClient.account.get().timeout(const Duration(seconds: 6));
      return true;
    } on AppwriteException catch (e) {
      return e.code != null; // réponse du serveur reçue → en ligne
    } catch (_) {
      return false; // timeout / pas de réseau
    }
  }

  // ── Profil utilisateur ───────────────────────────────────────────────────

  /// Découpe un nom complet en `firstName` / `lastName` pour la collection
  /// `users` (qui attend ces deux champs séparés).
  static Map<String, dynamic> splitFullName(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return {'firstName': 'Utilisateur', 'lastName': ''};
    }
    return {
      'firstName': parts.first,
      'lastName': parts.length > 1 ? parts.sublist(1).join(' ') : '',
    };
  }

  /// Crée ou met à jour le profil d'un utilisateur dans la collection `users`.
  Future<void> createUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      // Vérifier si le document existe déjà
      final exists = await profileExists(uid);
      if (exists) {
        await AppwriteClient.databases.updateDocument(
          databaseId: appwriteDatabaseId,
          collectionId: appwriteUsersCollectionId,
          documentId: uid,
          data: data,
        );
      } else {
        await AppwriteClient.databases.createDocument(
          databaseId: appwriteDatabaseId,
          collectionId: appwriteUsersCollectionId,
          documentId: uid,
          data: {
            ...data,
            'createdAt': DateTime.now().toIso8601String(),
          },
          // Profil privé : seul son propriétaire le lit/modifie. Les admins y
          // accèdent via les permissions d'équipe au niveau de la collection.
          permissions: [
            Permission.read(Role.user(uid)),
            Permission.update(Role.user(uid)),
          ],
        );
      }
      _cache.remove('profile:$uid');
    } on AppwriteException {
      rethrow;
    }
  }

  /// Retourne le profil d'un utilisateur sous forme de Map, ou null s'il
  /// n'existe pas.
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final key = 'profile:$uid';
    final cached = _cache[key];
    if (cached != null && DateTime.now().difference(cached.at) < _cacheTtl) {
      return cached.data as Map<String, dynamic>?;
    }
    try {
      final doc = await AppwriteClient.databases.getDocument(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteUsersCollectionId,
        documentId: uid,
      );
      _cache[key] = _CacheEntry(doc.data, DateTime.now());
      unawaited(DiskCache.writeMap(key, doc.data));
      return doc.data;
    } on AppwriteException catch (e) {
      if (e.code == 404) return null;
      // Hors-ligne / erreur : on sert le dernier profil connu (mémoire puis
      // disque) afin que le profil reste lisible sans connexion.
      if (cached != null) return cached.data as Map<String, dynamic>?;
      final disk = await DiskCache.readMap(key);
      if (disk != null) {
        _cache[key] = _CacheEntry(disk, DateTime.now());
        return disk;
      }
      rethrow;
    }
  }

  /// Met à jour certains champs du profil.
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await AppwriteClient.databases.updateDocument(
      databaseId: appwriteDatabaseId,
      collectionId: appwriteUsersCollectionId,
      documentId: uid,
      data: data,
    );
    _cache.remove('profile:$uid');
  }

  /// Vérifie si le profil d'un utilisateur existe déjà.
  Future<bool> profileExists(String uid) async {
    return await getUserProfile(uid) != null;
  }

  /// Catalogue des séries / filières (toutes confondues, filtrées par cursus
  /// côté UI). Configuré par l'admin dans la collection `exam_series`.
  /// Tolérant hors-ligne (cache mémoire) ; renvoie une liste vide en cas
  /// d'échec pour laisser l'UI basculer sur une saisie libre.
  Future<List<ExamSeries>> getExamSeries({bool force = false}) {
    return _cachedList<ExamSeries>('exam_series', () async {
      final res = await AppwriteClient.databases.listDocuments(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteExamSeriesCollectionId,
        queries: [Query.limit(500)],
      );
      return res.documents.map((d) => d.data).toList();
    }, (raw) => raw
        .map((m) => ExamSeries.fromMap(m))
        .where((s) => s.active && s.name.isNotEmpty)
        .toList(), force: force);
  }

  /// Liens des réseaux sociaux (configurés par l'admin dans `social_links`).
  /// Triés par `order`, actifs uniquement, tolérant (liste vide si échec).
  Future<List<SocialLink>> getSocialLinks({bool force = false}) {
    return _cachedList<SocialLink>('social_links', () async {
      final res = await AppwriteClient.databases.listDocuments(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteSocialLinksCollectionId,
        queries: [Query.limit(50)],
      );
      return res.documents.map((d) => d.data).toList();
    }, (raw) => raw
        .map((m) => SocialLink.fromMap(m))
        .where((s) => s.active && s.url.isNotEmpty && s.label.isNotEmpty)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order)), force: force);
  }

  // ── Résultats d'examens ──────────────────────────────────────────────────

  /// Sauvegarde un résultat dans la collection `results`.
  Future<void> saveResult(String uid, Map<String, dynamic> result) async {
    await AppwriteClient.databases.createDocument(
      databaseId: appwriteDatabaseId,
      collectionId: appwriteResultsCollectionId,
      documentId: ID.unique(),
      data: {
        ...result,
        'userId': uid,
        'savedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Recherche un résultat publié par type d'examen + numéro de table.
  /// Retourne `null` si rien ne correspond (ou en cas d'erreur réseau).
  Future<ExamResult?> lookupResult({
    required String examType,
    required String tableNumber,
    String? year,
  }) async {
    final table = tableNumber.trim();
    if (table.isEmpty) return null;
    try {
      final res = await AppwriteClient.databases.listDocuments(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteExamResultsCollectionId,
        queries: [
          Query.equal('examType', examType),
          Query.equal('tableNumber', table),
          if (year != null && year.isNotEmpty) Query.equal('year', year),
          Query.limit(1),
        ],
      );
      if (res.documents.isEmpty) return null;
      final d = res.documents.first;
      return ExamResult.fromMap(d.data, id: d.$id);
    } on AppwriteException {
      return null;
    }
  }

  // ── Sources de résultats (configurées par l'admin) ───────────────────────

  /// Sources de résultats actives (manuel / PDF / API), triées par `order`.
  /// Tolérant : liste vide si erreur/hors-ligne ou collection absente.
  Future<List<ResultSource>> getResultSources({bool force = false}) {
    return _cachedList<ResultSource>('result_sources', () async {
      final res = await AppwriteClient.databases.listDocuments(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteResultSourcesCollectionId,
        queries: [Query.limit(100)],
      );
      return res.documents.map((d) => {...d.data, '\$id': d.$id}).toList();
    }, (raw) => raw
        .map((m) => ResultSource.fromMap(m, id: m['\$id'] as String))
        .where((s) => s.active && s.label.isNotEmpty)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order)), force: force);
  }

  /// Résultat d'une recherche dans une source : soit un [ExamResult] trouvé,
  /// soit `found == false` avec un éventuel message à afficher.
  /// `error == true` signale un problème technique (réseau, source mal
  /// configurée…) distinct d'un simple « introuvable ».
  Future<ResultLookup> searchResultSource({
    required ResultSource source,
    required String query,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return const ResultLookup.notFound();

    // Type `manual` : lecture directe de `exam_results` (tolérant hors-ligne).
    if (source.type == ResultSourceType.manual) {
      final r = await lookupResult(
        examType: source.examType,
        tableNumber: q,
        year: source.year.isEmpty ? null : source.year,
      );
      return r == null ? const ResultLookup.notFound() : ResultLookup.found(r);
    }

    // Types `pdf` / `api` : résolus par l'endpoint serverless (Vercel).
    try {
      final resp = await http
          .post(
            Uri.parse(resultLookupUrl),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'configId': source.id, 'query': q}),
          )
          .timeout(const Duration(seconds: 30));
      if (resp.statusCode != 200) {
        return const ResultLookup.error(
            'Recherche indisponible pour le moment. Réessaie.');
      }
      final body = resp.body.isEmpty ? '{}' : resp.body;
      final data = jsonDecode(body) as Map<String, dynamic>;
      if (data['ok'] != true) {
        return ResultLookup.error(
            (data['message'] ?? 'Recherche indisponible. Réessaie.').toString());
      }
      if (data['found'] != true || data['result'] == null) {
        return ResultLookup(
          found: false,
          message: (data['message'] ?? '').toString(),
        );
      }
      final result = ExamResult.fromMap(
        Map<String, dynamic>.from(data['result'] as Map),
        id: (data['result']['id'] ?? source.id).toString(),
      );
      return ResultLookup.found(result);
    } catch (_) {
      return const ResultLookup.error(
          'Recherche indisponible pour le moment. Vérifie ta connexion.');
    }
  }

  /// Retourne les résultats d'un utilisateur.
  Future<List<Map<String, dynamic>>> getResults(String uid) async {
    final result = await AppwriteClient.databases.listDocuments(
      databaseId: appwriteDatabaseId,
      collectionId: appwriteResultsCollectionId,
      queries: [Query.equal('userId', uid)],
    );
    return result.documents.map((d) => d.data).toList();
  }

  // ── Annales & documents ──────────────────────────────────────────────────

  /// Documents (épreuves/cours/fiches/TD) d'une matière pour un examen donné.
  /// Récupère toutes les entrées (paginées en interne, bornées) ; le tri/filtre
  /// fin se fait côté écran. Tolérant : liste vide si erreur/hors-ligne.
  Future<List<Annale>> getAnnales({required String exam, required String subject}) {
    return _cachedList<Annale>('annales:$exam:$subject', () async {
      final out = <Map<String, dynamic>>[];
      var offset = 0;
      while (true) {
        final res = await AppwriteClient.databases.listDocuments(
          databaseId: appwriteDatabaseId,
          collectionId: appwriteAnnalesCollectionId,
          queries: [
            Query.equal('exam', exam),
            Query.equal('subject', subject),
            Query.orderDesc('year'),
            Query.limit(100),
            Query.offset(offset),
          ],
        );
        out.addAll(res.documents.map((d) => {...d.data, '\$id': d.$id, '\$createdAt': d.$createdAt}));
        if (res.documents.length < 100 || out.length >= 300) break;
        offset += 100;
      }
      return out;
    }, (raw) => raw
        .map((m) => Annale.fromMap(m, id: m['\$id'] as String, createdAt: m['\$createdAt'] as String?))
        .toList());
  }

  /// Un document d'annales par son id (pour les liens de partage / deep links).
  Future<Annale?> getAnnaleById(String id) async {
    try {
      final doc = await AppwriteClient.databases.getDocument(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteAnnalesCollectionId,
        documentId: id,
      );
      return Annale.fromMap(doc.data, id: doc.$id, createdAt: doc.$createdAt);
    } on AppwriteException {
      return null;
    }
  }

  /// Tous les documents d'un examen (les plus récents d'abord) — pour compter
  /// par matière et afficher « récemment ajoutés ». Liste vide si erreur.
  Future<List<Annale>> getAnnalesForExam(String exam) {
    return _cachedList<Annale>('annales:exam:$exam', () async {
      final out = <Map<String, dynamic>>[];
      var offset = 0;
      while (true) {
        final res = await AppwriteClient.databases.listDocuments(
          databaseId: appwriteDatabaseId,
          collectionId: appwriteAnnalesCollectionId,
          queries: [
            Query.equal('exam', exam),
            Query.orderDesc('\$createdAt'),
            Query.limit(100),
            Query.offset(offset),
          ],
        );
        out.addAll(res.documents.map((d) => {...d.data, '\$id': d.$id, '\$createdAt': d.$createdAt}));
        if (res.documents.length < 100 || out.length >= 500) break;
        offset += 100;
      }
      return out;
    }, (raw) => raw
        .map((m) => Annale.fromMap(m, id: m['\$id'] as String, createdAt: m['\$createdAt'] as String?))
        .toList());
  }

  /// Annales les plus récentes, tous examens confondus — pour la **recherche**
  /// (filtrage côté écran : titre/matière/examen/catégorie/année). Paginé et
  /// borné ; mis en cache 5 min. Liste vide si erreur/hors-ligne.
  Future<List<Annale>> searchAnnales({int limit = 400}) {
    return _cachedList<Annale>('annales:search:$limit', () async {
      final out = <Map<String, dynamic>>[];
      var offset = 0;
      while (true) {
        final res = await AppwriteClient.databases.listDocuments(
          databaseId: appwriteDatabaseId,
          collectionId: appwriteAnnalesCollectionId,
          queries: [
            Query.orderDesc('\$createdAt'),
            Query.limit(100),
            Query.offset(offset),
          ],
        );
        out.addAll(res.documents.map((d) => {...d.data, '\$id': d.$id, '\$createdAt': d.$createdAt}));
        if (res.documents.length < 100 || out.length >= limit) break;
        offset += 100;
      }
      return out;
    }, (raw) => raw
        .map((m) => Annale.fromMap(m, id: m['\$id'] as String, createdAt: m['\$createdAt'] as String?))
        .toList());
  }

  /// Les épreuves ajoutées le plus récemment, tous examens confondus
  /// (section « Ajoutées récemment » de la page Annales). Cache 5 min.
  Future<List<Annale>> recentAnnales({int limit = 8}) {
    return _cachedList<Annale>('annales:recent:$limit', () async {
      final res = await AppwriteClient.databases.listDocuments(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteAnnalesCollectionId,
        queries: [
          Query.orderDesc('\$createdAt'),
          Query.limit(limit),
        ],
      );
      return res.documents.map((d) => {...d.data, '\$id': d.$id, '\$createdAt': d.$createdAt}).toList();
    }, (raw) => raw
        .map((m) => Annale.fromMap(m, id: m['\$id'] as String, createdAt: m['\$createdAt'] as String?))
        .toList());
  }

  /// Documents de cours (PDF) collectés depuis `annales` (section « Cours PDF »
  /// de la page Cours). Petite collection → on lit tout et on trie côté app.
  /// Réutilise le modèle [Annale] (mêmes champs). Cache 5 min, tolérant.
  Future<List<Annale>> getCourseDocs({int limit = 1000}) {
    return _cachedList<Annale>('course_docs:$limit', () async {
      final res = await AppwriteClient.databases.listDocuments(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteCourseDocsCollectionId,
        queries: [Query.limit(limit)],
      );
      return res.documents.map((d) => {...d.data, '\$id': d.$id, '\$createdAt': d.$createdAt}).toList();
    }, (raw) => raw
        .map((m) => Annale.fromMap(m, id: m['\$id'] as String, createdAt: m['\$createdAt'] as String?))
        .toList());
  }

  /// Nombre de documents par examen (compteurs de la page Annales).
  Future<Map<String, int>> annalesCountByExam(List<String> exams) async {
    final key = 'annales:counts';
    final out = <String, int>{};
    var anyError = false;
    for (final ex in exams) {
      try {
        final res = await AppwriteClient.databases.listDocuments(
          databaseId: appwriteDatabaseId,
          collectionId: appwriteAnnalesCollectionId,
          queries: [Query.equal('exam', ex), Query.limit(1)],
        );
        out[ex] = res.total;
      } on AppwriteException {
        anyError = true;
        out[ex] = 0;
      }
    }
    if (!anyError) {
      unawaited(DiskCache.writeMap(key, out.map((k, v) => MapEntry(k, v))));
      return out;
    }
    // Hors-ligne : on complète avec les derniers compteurs connus (disque).
    final disk = await DiskCache.readMap(key);
    if (disk != null) {
      for (final ex in exams) {
        if (out[ex] == 0 && disk[ex] is num) out[ex] = (disk[ex] as num).toInt();
      }
    }
    return out;
  }

  // ── Fil d'actualités ─────────────────────────────────────────────────────

  /// Retourne les articles du fil OnBuch, les plus récents d'abord.
  ///
  /// Renvoie une liste vide en cas d'erreur (collection absente, réseau…) afin
  /// que l'écran d'accueil puisse afficher un contenu de repli sans planter.
  Future<List<Article>> getArticles({int limit = 6}) {
    return _cachedList<Article>('articles:$limit', () async {
      final res = await AppwriteClient.databases.listDocuments(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteArticlesCollectionId,
        queries: [
          Query.orderDesc('\$createdAt'),
          Query.limit(limit),
        ],
      );
      return res.documents.map((d) => {...d.data, '\$id': d.$id, '\$createdAt': d.$createdAt}).toList();
    }, (raw) => raw
        .map((m) => Article.fromMap(m, id: m['\$id'] as String, createdAtFallback: m['\$createdAt'] as String))
        .toList());
  }

  /// Retourne un article par son ID, ou null s'il est introuvable.
  Future<Article?> getArticleById(String id) async {
    try {
      final doc = await AppwriteClient.databases.getDocument(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteArticlesCollectionId,
        documentId: id,
      );
      return Article.fromMap(doc.data, id: doc.$id, createdAtFallback: doc.$createdAt);
    } on AppwriteException {
      return null;
    }
  }

  // ── Notifications ─────────────────────────────────────────────────────────

  /// Retourne les notifications (gérées côté admin), les plus récentes d'abord.
  /// Liste vide en cas d'erreur (collection absente, réseau…), pour ne pas
  /// planter l'écran.
  Future<List<AppNotification>> getNotifications({int limit = 30}) {
    return _cachedList<AppNotification>('notifications:$limit', () async {
      final res = await AppwriteClient.databases.listDocuments(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteNotificationsCollectionId,
        queries: [
          Query.orderDesc('\$createdAt'),
          Query.limit(limit),
        ],
      );
      return res.documents.map((d) => {...d.data, '\$id': d.$id, '\$createdAt': d.$createdAt}).toList();
    }, (raw) => raw
        .map((m) => AppNotification.fromMap(m, id: m['\$id'] as String, createdAtFallback: m['\$createdAt'] as String))
        .toList());
  }

  // ── Examens (carrousel d'accueil) ─────────────────────────────────────────

  /// Retourne les examens configurés, triés par `order` croissant.
  /// Liste vide en cas d'erreur (l'accueil affiche alors un repli).
  Future<List<Exam>> getExams({int limit = 20}) {
    return _cachedList<Exam>('exams:$limit', () async {
      final res = await AppwriteClient.databases.listDocuments(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteExamsCollectionId,
        queries: [
          Query.orderAsc('order'),
          Query.limit(limit),
        ],
      );
      return res.documents.map((d) => {...d.data, '\$id': d.$id, '\$createdAt': d.$createdAt}).toList();
    }, (raw) => raw
        .map((m) => Exam.fromMap(m, id: m['\$id'] as String, createdAtFallback: m['\$createdAt'] as String))
        .toList());
  }

  /// Annonces configurables du carrousel d'accueil (les actives, dans leur
  /// fenêtre de programmation, triées par `order`). Tolérant : collection
  /// absente / hors-ligne → liste vide.
  Future<List<HomeAnnouncement>> getHomeAnnouncements({int limit = 10}) {
    return _cachedList<HomeAnnouncement>('home_announcements:$limit', () async {
      final res = await AppwriteClient.databases.listDocuments(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteHomeAnnouncementsCollectionId,
        queries: [
          Query.orderAsc('order'),
          Query.limit(limit),
        ],
      );
      return res.documents.map((d) => {...d.data, '\$id': d.$id}).toList();
    }, (raw) => raw
        .map((m) => HomeAnnouncement.fromMap(m, id: m['\$id'] as String))
        .where((a) => a.isLive)
        .toList());
  }

  // ── Calendrier scolaire ───────────────────────────────────────────────────

  /// Retourne les événements du calendrier scolaire, du plus ancien au plus
  /// récent. Liste vide en cas d'erreur.
  Future<List<CalendarEvent>> getCalendarEvents({int limit = 100}) {
    return _cachedList<CalendarEvent>('calendar:$limit', () async {
      final res = await AppwriteClient.databases.listDocuments(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteSchoolCalendarCollectionId,
        queries: [
          Query.orderAsc('startDate'),
          Query.limit(limit),
        ],
      );
      return res.documents.map((d) => {...d.data, '\$id': d.$id}).toList();
    }, (raw) => raw.map((m) => CalendarEvent.fromMap(m, id: m['\$id'] as String)).toList());
  }

  // ── Concours ──────────────────────────────────────────────────────────────

  /// Retourne les concours (triés par `order`). Liste vide en cas d'erreur.
  Future<List<Concours>> getConcours({int limit = 50}) {
    return _cachedList<Concours>('concours:$limit', () async {
      final res = await AppwriteClient.databases.listDocuments(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteConcoursCollectionId,
        queries: [
          Query.orderAsc('order'),
          Query.limit(limit),
        ],
      );
      return res.documents.map((d) => {...d.data, '\$id': d.$id}).toList();
    }, (raw) => raw.map((m) => Concours.fromMap(m, id: m['\$id'] as String)).toList());
  }

  /// Centres de préparation aux concours (triés par `order`).
  Future<List<PrepCenter>> getPrepCenters({int limit = 30}) {
    return _cachedList<PrepCenter>('prep_centers:$limit', () async {
      final res = await AppwriteClient.databases.listDocuments(
        databaseId: appwriteDatabaseId,
        collectionId: appwritePrepCentersCollectionId,
        queries: [Query.orderAsc('order'), Query.limit(limit)],
      );
      return res.documents.map((d) => {...d.data, '\$id': d.$id}).toList();
    }, (raw) => raw.map((m) => PrepCenter.fromMap(m, id: m['\$id'] as String)).toList());
  }

  /// Ressources de préparation aux concours (triées par `order`).
  Future<List<ConcoursResource>> getConcoursResources({int limit = 40}) {
    return _cachedList<ConcoursResource>('concours_resources:$limit', () async {
      final res = await AppwriteClient.databases.listDocuments(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteConcoursResourcesCollectionId,
        queries: [Query.orderAsc('order'), Query.limit(limit)],
      );
      return res.documents.map((d) => {...d.data, '\$id': d.$id}).toList();
    }, (raw) => raw.map((m) => ConcoursResource.fromMap(m, id: m['\$id'] as String)).toList());
  }

  /// Enregistre une candidature de l'utilisateur à un concours (privée).
  Future<ConcoursApplication> createApplication({
    required String uid,
    required String concoursId,
    required String concoursName,
    String? examLabel,
    String? receiptNo,
  }) async {
    final now = DateTime.now();
    final doc = await AppwriteClient.databases.createDocument(
      databaseId: appwriteDatabaseId,
      collectionId: appwriteConcoursApplicationsCollectionId,
      documentId: ID.unique(),
      data: {
        'userId': uid,
        'concoursId': concoursId,
        'concoursName': concoursName,
        'status': 'submitted',
        if (examLabel != null) 'examLabel': examLabel,
        if (receiptNo != null) 'receiptNo': receiptNo,
        'createdAt': now.toIso8601String(),
      },
      permissions: [
        Permission.read(Role.user(uid)),
        Permission.update(Role.user(uid)),
        Permission.delete(Role.user(uid)),
      ],
    );
    return ConcoursApplication.fromMap(doc.data, id: doc.$id, createdAtFallback: doc.$createdAt);
  }

  /// Candidatures de l'utilisateur connecté (les plus récentes d'abord).
  Future<List<ConcoursApplication>> getMyApplications(String uid) async {
    try {
      final res = await AppwriteClient.databases.listDocuments(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteConcoursApplicationsCollectionId,
        queries: [Query.equal('userId', uid), Query.orderDesc('\$createdAt'), Query.limit(50)],
      );
      return res.documents
          .map((d) => ConcoursApplication.fromMap(d.data, id: d.$id, createdAtFallback: d.$createdAt))
          .toList();
    } on AppwriteException {
      return const <ConcoursApplication>[];
    }
  }

  // ── Cours (matières & chapitres) ──────────────────────────────────────────

  /// Matières, triées par `order`.
  Future<List<Subject>> getSubjects({int limit = 50}) {
    return _cachedList<Subject>('subjects:$limit', () async {
      final res = await AppwriteClient.databases.listDocuments(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteSubjectsCollectionId,
        queries: [Query.orderAsc('order'), Query.limit(limit)],
      );
      return res.documents.map((d) => {...d.data, '\$id': d.$id}).toList();
    }, (raw) => raw.map((m) => Subject.fromMap(m, id: m['\$id'] as String)).toList());
  }

  /// Tous les chapitres (filtrés côté app par matière), triés par `order`.
  Future<List<Chapter>> getChapters({int limit = 500}) {
    return _cachedList<Chapter>('chapters:$limit', () async {
      final res = await AppwriteClient.databases.listDocuments(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteChaptersCollectionId,
        queries: [Query.orderAsc('order'), Query.limit(limit)],
      );
      return res.documents.map((d) => {...d.data, '\$id': d.$id}).toList();
    }, (raw) => raw.map((m) => Chapter.fromMap(m, id: m['\$id'] as String)).toList());
  }

  /// Fiche de cours mise en cache pour un chapitre, ou null si non générée.
  Future<String?> getLesson(String chapterId) async {
    try {
      final doc = await AppwriteClient.databases.getDocument(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteLessonsCollectionId,
        documentId: chapterId,
      );
      final c = doc.data['content']?.toString() ?? '';
      return c.trim().isEmpty ? null : c;
    } on AppwriteException {
      return null;
    }
  }

  /// QCM mis en cache pour un chapitre, ou null si non généré.
  Future<List<QuizQuestion>?> getQuiz(String chapterId) async {
    try {
      final doc = await AppwriteClient.databases.getDocument(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteQuizzesCollectionId,
        documentId: chapterId,
      );
      final c = doc.data['content']?.toString() ?? '';
      return c.trim().isEmpty ? null : parseQuiz(c);
    } on AppwriteException {
      return null;
    }
  }

  /// IDs des matières (packs) possédées par l'utilisateur — achats premium +
  /// ajouts de packs gratuits (`pack_purchases`).
  Future<Set<String>> getOwnedSubjectIds() async {
    try {
      final res = await AppwriteClient.databases.listDocuments(
        databaseId: appwriteDatabaseId,
        collectionId: appwritePackPurchasesCollectionId,
        queries: [Query.limit(200)],
      );
      return res.documents.map((d) => d.data['subjectId']?.toString() ?? '').where((s) => s.isNotEmpty).toSet();
    } on AppwriteException {
      return <String>{};
    }
  }

  /// Ajoute un pack GRATUIT à la bibliothèque (création directe, sans paiement).
  Future<bool> addFreePack(String subjectId) async {
    try {
      final user = await AppwriteClient.account.get();
      await AppwriteClient.databases.createDocument(
        databaseId: appwriteDatabaseId,
        collectionId: appwritePackPurchasesCollectionId,
        documentId: ID.unique(),
        data: {
          'uid': user.$id,
          'subjectId': subjectId,
          'priceCredits': 0,
          'createdAt': DateTime.now().toIso8601String(),
        },
        permissions: [Permission.read(Role.user(user.$id))],
      );
      return true;
    } on AppwriteException {
      return false;
    }
  }

  /// IDs des chapitres déjà consultés par l'utilisateur.
  Future<Set<String>> getViewedChapterIds() async {
    try {
      // La sécurité par document limite déjà aux progrès de l'utilisateur.
      final res = await AppwriteClient.databases.listDocuments(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteChapterProgressCollectionId,
        queries: [Query.limit(500)],
      );
      return res.documents.map((d) => d.data['chapterId']?.toString() ?? '').where((s) => s.isNotEmpty).toSet();
    } on AppwriteException {
      return <String>{};
    }
  }

  /// Marque un chapitre comme consulté (idempotent côté UI).
  Future<void> markChapterViewed(String chapterId) async {
    try {
      final user = await AppwriteClient.account.get();
      await AppwriteClient.databases.createDocument(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteChapterProgressCollectionId,
        documentId: ID.unique(),
        data: {
          'uid': user.$id,
          'chapterId': chapterId,
          'viewedAt': DateTime.now().toIso8601String(),
        },
        permissions: [
          Permission.read(Role.user(user.$id)),
          Permission.update(Role.user(user.$id)),
          Permission.delete(Role.user(user.$id)),
        ],
      );
    } on AppwriteException {
      // non bloquant
    }
  }

  /// Enregistre une tentative de QCM (`quiz_attempts`) et met à jour la maîtrise
  /// dérivée du chapitre (`topic_mastery`). Fondations de l'« agent d'études »
  /// (Phase 0) : on arrête de perdre les signaux d'apprentissage. Non bloquant.
  Future<void> recordQuizAttempt({
    required String chapterId,
    required String subject,
    String topic = '',
    required int score,
    required int total,
    List<int> wrong = const [],
  }) async {
    if (total <= 0) return;
    try {
      final user = await AppwriteClient.account.get();
      final uid = user.$id;
      final perms = [
        Permission.read(Role.user(uid)),
        Permission.update(Role.user(uid)),
        Permission.delete(Role.user(uid)),
      ];
      await AppwriteClient.databases.createDocument(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteQuizAttemptsCollectionId,
        documentId: ID.unique(),
        data: {
          'userId': uid,
          'subject': subject,
          'chapterId': chapterId,
          'topic': topic,
          'score': score,
          'total': total,
          'wrong': wrong.join(','),
          'createdAt': DateTime.now().toIso8601String(),
        },
        permissions: perms,
      );
      await _upsertMastery(uid, chapterId, subject, topic, score / total, perms);
      await _scheduleReview(uid, chapterId, subject, topic, score / total, perms);
      // Rafraîchit la mémoire longue de Léo avec ce nouveau signal.
      await syncStudentMemory(force: true);
    } on AppwriteException {
      // non bloquant
    }
  }

  /// Programme la prochaine révision du chapitre (algorithme SM-2 simplifié) :
  /// plus le quiz est réussi, plus l'échéance est éloignée ; un échec ramène à
  /// demain. Stocké dans `review_queue` (un item par chapitre). Non bloquant.
  Future<void> _scheduleReview(
    String uid,
    String chapterId,
    String subject,
    String topic,
    double ratio,
    List<String> perms,
  ) async {
    // Qualité SM-2 (2..5) déduite du taux de réussite.
    final q = ratio >= 0.8 ? 5 : (ratio >= 0.6 ? 4 : (ratio >= 0.5 ? 3 : 2));
    try {
      final list = await AppwriteClient.databases.listDocuments(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteReviewQueueCollectionId,
        queries: [Query.equal('userId', uid), Query.limit(200)],
      );
      final existing = list.documents.where((d) => d.data['chapterId'] == chapterId);
      String? docId;
      int reps = 0;
      double ease = 2.5;
      int prevInterval = 1;
      if (existing.isNotEmpty) {
        final d = existing.first;
        docId = d.$id;
        reps = (d.data['reps'] as num?)?.toInt() ?? 0;
        ease = (d.data['ease'] as num?)?.toDouble() ?? 2.5;
        prevInterval = (d.data['interval'] as num?)?.toInt() ?? 1;
      }
      int interval;
      if (q < 3) {
        reps = 0;
        interval = 1;
      } else {
        reps += 1;
        interval = reps == 1 ? 1 : (reps == 2 ? 3 : (prevInterval * ease).round().clamp(1, 365));
      }
      ease = (ease + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02)));
      if (ease < 1.3) ease = 1.3;
      final data = {
        'userId': uid,
        'chapterId': chapterId,
        'subject': subject,
        'topic': topic,
        'dueAt': DateTime.now().add(Duration(days: interval)).toIso8601String(),
        'interval': interval,
        'ease': ease,
        'reps': reps,
        'lastGrade': q,
        'status': 'active',
      };
      if (docId != null) {
        await AppwriteClient.databases.updateDocument(
          databaseId: appwriteDatabaseId,
          collectionId: appwriteReviewQueueCollectionId,
          documentId: docId,
          data: data,
        );
      } else {
        data['createdAt'] = DateTime.now().toIso8601String();
        await AppwriteClient.databases.createDocument(
          databaseId: appwriteDatabaseId,
          collectionId: appwriteReviewQueueCollectionId,
          documentId: ID.unique(),
          data: data,
          permissions: perms,
        );
      }
    } on AppwriteException {
      // non bloquant
    }
  }

  /// Révisions dues aujourd'hui (échéance passée), les plus urgentes d'abord.
  Future<List<ReviewItem>> dueReviews({int limit = 20}) async {
    try {
      final res = await AppwriteClient.databases.listDocuments(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteReviewQueueCollectionId,
        queries: [Query.orderAsc('dueAt'), Query.limit(100)],
      );
      final now = DateTime.now();
      return res.documents
          .map((d) => ReviewItem.fromDoc(d.$id, d.data))
          .where((r) => !r.dueAt.isAfter(now) && r.chapterId.isNotEmpty)
          .take(limit)
          .toList();
    } on AppwriteException {
      return const [];
    }
  }

  /// Chapitres les moins maîtrisés (depuis `topic_mastery`), pour le coach.
  Future<List<MasteryItem>> weakChapters({int limit = 5}) async {
    try {
      final res = await AppwriteClient.databases.listDocuments(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteTopicMasteryCollectionId,
        queries: [Query.limit(200)],
      );
      final items = res.documents
          .map((d) => MasteryItem.fromDoc(d.data))
          .where((m) => m.chapterId.isNotEmpty)
          .toList()
        ..sort((a, b) => a.mastery.compareTo(b.mastery));
      return items.take(limit).toList();
    } on AppwriteException {
      return const [];
    }
  }

  // ── Mémoire longue de Léo (student_memory) ─────────────────────────────────
  static DateTime? _lastMemorySync;

  /// Met à jour la **mémoire longue** de Léo (`student_memory/{uid}`) à partir
  /// des signaux déjà collectés : points faibles/forts (`topic_mastery`) +
  /// objectifs (profil). La fonction `tutor-ai` lit cette mémoire à chaque
  /// correction → Léo personnalise (« tu prépares le Bac D, tu bloques sur les
  /// dérivées… »). Best-effort, non bloquant ; n'écrase jamais avec du vide.
  /// `force` contourne l'anti-rebond (30 min) — utilisé après un quiz.
  Future<void> syncStudentMemory({bool force = false}) async {
    if (!force &&
        _lastMemorySync != null &&
        DateTime.now().difference(_lastMemorySync!) < const Duration(minutes: 30)) {
      return;
    }
    _lastMemorySync = DateTime.now();
    try {
      final user = await AppwriteClient.account.get();
      final uid = user.$id;

      // 1) Maîtrise par thème → faiblesses (<0,6) et forces (>=0,8).
      final res = await AppwriteClient.databases.listDocuments(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteTopicMasteryCollectionId,
        queries: [Query.limit(200)],
      );
      final items = res.documents
          .map((d) => MasteryItem.fromDoc(d.data))
          .where((m) => m.attempts > 0 && (m.subject.isNotEmpty || m.topic.isNotEmpty))
          .toList();
      String label(MasteryItem m) => m.topic.isNotEmpty
          ? '${m.topic}${m.subject.isNotEmpty ? ' (${m.subject})' : ''}'
          : m.subject;
      final weak = items.where((m) => m.mastery < 0.6).toList()
        ..sort((a, b) => a.mastery.compareTo(b.mastery));
      final strong = items.where((m) => m.mastery >= 0.8).toList()
        ..sort((a, b) => b.mastery.compareTo(a.mastery));
      final weaknesses = weak.take(6).map(label).toSet().join(', ');
      final strengths = strong.take(6).map(label).toSet().join(', ');

      // 2) Objectifs depuis le profil.
      final p = await getUserProfile(uid) ?? const <String, dynamic>{};
      String s(dynamic v) => (v ?? '').toString().trim();
      final examen = s(p['examen']);
      final serie = s(p['serie']);
      final classe = s(p['classe']);
      final career = s(p['careerGoal']);
      final goalParts = <String>[];
      if (examen.isNotEmpty) {
        goalParts.add('préparer le $examen${serie.isNotEmpty ? ' série $serie' : ''}');
      } else if (classe.isNotEmpty) {
        goalParts.add('réussir en $classe');
      }
      if (career.isNotEmpty) goalParts.add('vise : $career');
      final goals = goalParts.join(' · ');

      if (weaknesses.isEmpty && strengths.isEmpty && goals.isEmpty) return;

      String cap(String v, int n) => v.length > n ? v.substring(0, n) : v;
      final data = <String, dynamic>{
        'userId': uid,
        if (weaknesses.isNotEmpty) 'weaknesses': cap(weaknesses, 2000),
        if (strengths.isNotEmpty) 'strengths': cap(strengths, 2000),
        if (goals.isNotEmpty) 'goals': cap(goals, 1000),
        'lastSeen': DateTime.now().toIso8601String(),
      };
      try {
        await AppwriteClient.databases.updateDocument(
          databaseId: appwriteDatabaseId,
          collectionId: appwriteStudentMemoryCollectionId,
          documentId: uid,
          data: data,
        );
      } on AppwriteException catch (e) {
        if (e.code == 404) {
          await AppwriteClient.databases.createDocument(
            databaseId: appwriteDatabaseId,
            collectionId: appwriteStudentMemoryCollectionId,
            documentId: uid,
            data: data,
            permissions: [
              Permission.read(Role.user(uid)),
              Permission.update(Role.user(uid)),
              Permission.delete(Role.user(uid)),
            ],
          );
        }
      }
    } catch (_) {
      // best-effort : la mémoire ne doit jamais bloquer l'app.
    }
  }

  /// Mémoire longue de Léo pour l'utilisateur courant (pour l'afficher).
  /// Clés : `weaknesses`, `strengths`, `goals` (vides si rien).
  Future<Map<String, String>> getStudentMemory() async {
    try {
      final user = await AppwriteClient.account.get();
      final doc = await AppwriteClient.databases.getDocument(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteStudentMemoryCollectionId,
        documentId: user.$id,
      );
      String s(dynamic v) => (v ?? '').toString().trim();
      return {
        'weaknesses': s(doc.data['weaknesses']),
        'strengths': s(doc.data['strengths']),
        'goals': s(doc.data['goals']),
      };
    } catch (_) {
      return const {};
    }
  }

  /// Met à jour (ou crée) la maîtrise d'un chapitre par moyenne glissante.
  Future<void> _upsertMastery(
    String uid,
    String chapterId,
    String subject,
    String topic,
    double current,
    List<String> perms,
  ) async {
    final now = DateTime.now().toIso8601String();
    try {
      final list = await AppwriteClient.databases.listDocuments(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteTopicMasteryCollectionId,
        queries: [Query.equal('userId', uid), Query.limit(200)],
      );
      final existing = list.documents.where((d) => d.data['chapterId'] == chapterId);
      if (existing.isNotEmpty) {
        final doc = existing.first;
        final prevAttempts = (doc.data['attempts'] as num?)?.toInt() ?? 0;
        final prevMastery = (doc.data['mastery'] as num?)?.toDouble() ?? 0.0;
        // Moyenne glissante : pondère l'historique et la dernière tentative.
        final blended = prevAttempts == 0 ? current : (prevMastery * 0.6 + current * 0.4);
        await AppwriteClient.databases.updateDocument(
          databaseId: appwriteDatabaseId,
          collectionId: appwriteTopicMasteryCollectionId,
          documentId: doc.$id,
          data: {'mastery': blended, 'attempts': prevAttempts + 1, 'lastReviewedAt': now},
        );
      } else {
        await AppwriteClient.databases.createDocument(
          databaseId: appwriteDatabaseId,
          collectionId: appwriteTopicMasteryCollectionId,
          documentId: ID.unique(),
          data: {
            'userId': uid,
            'chapterId': chapterId,
            'subject': subject,
            'topic': topic,
            'mastery': current,
            'attempts': 1,
            'lastReviewedAt': now,
          },
          permissions: perms,
        );
      }
    } on AppwriteException {
      // non bloquant
    }
  }

  // ── À l'affiche (événements & partenaires) ────────────────────────────────

  /// Éléments « À l'affiche », triés par `order`. Liste vide en cas d'erreur.
  Future<List<AfficheItem>> getAffiche({int limit = 30}) {
    return _cachedList<AfficheItem>('affiche:$limit', () async {
      final res = await AppwriteClient.databases.listDocuments(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteAfficheCollectionId,
        queries: [Query.orderAsc('order'), Query.limit(limit)],
      );
      return res.documents.map((d) => {...d.data, '\$id': d.$id}).toList();
    }, (raw) => raw.map((m) => AfficheItem.fromMap(m, id: m['\$id'] as String)).toList());
  }

  // ── Analytics ────────────────────────────────────────────────────────────

  /// Loggue un événement analytics dans la collection `analytics_events`.
  /// Silencieux en cas d'erreur pour ne pas bloquer l'UX.
  Future<void> logAnalyticsEvent(
    String name,
    Map<String, dynamic> params,
  ) async {
    try {
      await AppwriteClient.databases.createDocument(
        databaseId: appwriteDatabaseId,
        collectionId: appwriteAnalyticsCollectionId,
        documentId: ID.unique(),
        data: {
          'name': name,
          'params': params.entries.map((e) => '${e.key}=${e.value}').join(', '),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (_) {
      // Silencieux — les analytics ne doivent jamais bloquer l'UX
    }
  }
}

class _CacheEntry {
  final dynamic data;
  final DateTime at;
  _CacheEntry(this.data, this.at);
}
