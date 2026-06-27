const appwriteEndpoint = 'https://nyc.cloud.appwrite.io/v1';
const appwriteProjectId = '6a30463b00001375e229';
const appwriteDatabaseId = '6a3047f8001d11d1b3c1';
const appwriteUsersCollectionId = 'users';
const appwriteExamSeriesCollectionId = 'exam_series';
const appwriteSocialLinksCollectionId = 'social_links';
const appwriteResultsCollectionId = 'results';
const appwriteExamResultsCollectionId = 'exam_results';
// Sources de résultats configurables par l'admin (manuel / PDF / API).
const appwriteResultSourcesCollectionId = 'result_sources';
// Bucket Storage des PDF de résultats chargés par l'admin (réutilise le bucket
// `annales_files` — le plan Appwrite limite le nombre de buckets).
const appwriteResultPdfsBucketId = 'annales_files';
const appwriteAnalyticsCollectionId = 'analytics_events';
const appwriteArticlesCollectionId = 'articles';
const appwriteExamsCollectionId = 'exams';
const appwriteSchoolCalendarCollectionId = 'school_calendar';
const appwriteConcoursCollectionId = 'concours';
const appwritePrepCentersCollectionId = 'prep_centers';
// Annuaire des universités et liste des bourses (page Orientation). Gérés par
// l'admin, avec repli sur des listes curées embarquées (lib/data). Cf.
// tools/setup_universites.sh et tools/setup_bourses.sh.
const appwriteUniversitiesCollectionId = 'universities';
const appwriteBoursesCollectionId = 'bourses';
const appwriteConcoursResourcesCollectionId = 'concours_resources';
const appwriteConcoursApplicationsCollectionId = 'concours_applications';
const appwriteSubjectsCollectionId = 'subjects';
const appwriteChaptersCollectionId = 'chapters';
const appwriteLessonsCollectionId = 'lessons';
const appwriteChapterProgressCollectionId = 'chapter_progress';
const appwriteQuizzesCollectionId = 'quizzes';
const appwriteAfficheCollectionId = 'affiche';
const appwriteTutorJobsCollectionId = 'tutor_jobs';
const appwriteTutorQuotaCollectionId = 'tutor_quota';
const appwriteNotificationsCollectionId = 'notifications';
const appwriteAnnalesCollectionId = 'annales';
// Documents de cours (PDF) collectés depuis `annales` — section « Cours PDF ».
const appwriteCourseDocsCollectionId = 'course_docs';
const appwriteAppConfigCollectionId = 'app_config';
// Annonces configurables affichées en tête du carrousel d'accueil.
const appwriteHomeAnnouncementsCollectionId = 'home_announcements';
const appwriteGamificationCollectionId = 'gamification';
// Classement / ligues (façon Duolingo) : chaque élève publie son entrée
// (lecture publique, écriture propriétaire). Cf. tools/setup_leaderboard.sh.
const appwriteLeaderboardCollectionId = 'leaderboard';

// ── Module Exercices (banque d'exercices par matière/classe) ────────────────
// Chapitres + fiches (énoncé PDF + correction PDF) gérés par l'admin ;
// progression privée par élève (trouvé / pas trouvé). Cf. tools/setup_exercises.sh.
const appwriteExerciseChaptersCollectionId = 'exercise_chapters';
const appwriteExerciseSheetsCollectionId = 'exercise_sheets';

// ── Fascicules (livres PDF OnBuch — onglet Cours « Nos fascicules ») ─────────
// Un fascicule = un PDF (bucket `annales_files`) + une couverture, géré par
// l'admin. Cf. tools/setup_fascicules.sh.
const appwriteFasciculesCollectionId = 'fascicules';
// Numéro WhatsApp dédié aux PRÉCOMMANDES (fascicules…), géré par l'admin,
// séparé des réseaux sociaux. Cf. tools/setup_order_settings.sh.
const appwriteOrderSettingsCollectionId = 'order_settings';
const appwriteExerciseProgressCollectionId = 'exercise_progress';

// Endpoint serverless (Vercel) qui résout une recherche de résultat pour les
// sources `pdf` (extraction texte) et `api` (proxy externe). Hébergé sur Vercel
// car le plan Appwrite a atteint sa limite de fonctions. Aucun secret requis :
// les collections lues (`result_sources`, `exam_results`) sont en lecture
// publique. Le type `manual` est résolu côté app directement.
const resultLookupUrl = 'https://onbuch-v2.vercel.app/api/result-lookup';

// Page d'atterrissage des liens de partage (ouvre l'app si installée, sinon
// propose le téléchargement). Projet Vercel dédié.
const onbuchShareBaseUrl = 'https://onbuch-go.vercel.app';

// ── Agent d'études Léo (Phase 0 — fondations data) ──────────────────────────
// Données utilisateur (documentSecurity : chaque doc est restreint à son
// propriétaire). Créées par `tools/setup_agent_collections.sh`.
const appwriteQuizAttemptsCollectionId = 'quiz_attempts';
const appwriteTopicMasteryCollectionId = 'topic_mastery';
const appwriteTutorThreadsCollectionId = 'tutor_threads';
const appwriteStudentMemoryCollectionId = 'student_memory';
const appwriteReviewQueueCollectionId = 'review_queue';

// ── Push (FCM via Appwrite Messaging) ───────────────────────────────────────
// Optionnels. Laisser vide fonctionne tant qu'il n'y a qu'un seul provider push
// côté Appwrite. Renseigner si tu veux cibler un provider/topic précis.
// `appwritePushTopicId` : si défini, chaque appareil s'abonne à ce topic, ce qui
// permet à l'admin d'envoyer un push « à tous » en une fois.
const appwriteFcmProviderId = '';
const appwritePushTopicId = '';

// ── Packs de cours (paiement en crédits OnBuch) ─────────────────────────────
// Un pack = une matière (`subjects`), rattachée examen→série comme les annales.
// Propriété dans `pack_purchases`. L'achat (déduction de crédits) passe par
// l'endpoint serveur du projet Vercel du bot.
const appwritePackPurchasesCollectionId = 'pack_purchases';
const onbuchBuyPackUrl = 'https://telegram-bot-nine-henna.vercel.app/api/buy-pack';

// ── Crédits via Mobile Money (bot Telegram + rachat de code) ─────────────────
// Le paiement Orange/MTN passe par le bot @OnBuchCreditsBot (achat « hors-app »,
// positionné côté web) ; l'app ne fait que **racheter un code**. Conformité
// Play : le build mobile n'affiche AUCUN lien de paiement externe — uniquement
// le champ « J'ai un code ». Le CTA Telegram n'apparaît que sur le web.
const onbuchRedeemUrl = 'https://telegram-bot-nine-henna.vercel.app/api/redeem';
const onbuchCreditsBotUrl = 'https://t.me/OnBuchCreditsBot';
