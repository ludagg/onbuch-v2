const appwriteEndpoint = 'https://nyc.cloud.appwrite.io/v1';
const appwriteProjectId = '6a30463b00001375e229';
const appwriteDatabaseId = '6a3047f8001d11d1b3c1';
const appwriteUsersCollectionId = 'users';
const appwriteExamSeriesCollectionId = 'exam_series';
const appwriteSocialLinksCollectionId = 'social_links';
const appwriteResultsCollectionId = 'results';
const appwriteExamResultsCollectionId = 'exam_results';
const appwriteAnalyticsCollectionId = 'analytics_events';
const appwriteArticlesCollectionId = 'articles';
const appwriteExamsCollectionId = 'exams';
const appwriteSchoolCalendarCollectionId = 'school_calendar';
const appwriteConcoursCollectionId = 'concours';
const appwritePrepCentersCollectionId = 'prep_centers';
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
const appwriteAppConfigCollectionId = 'app_config';
const appwriteGamificationCollectionId = 'gamification';

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

// ── Crédits via Mobile Money (bot Telegram + rachat de code) ─────────────────
// Le paiement Orange/MTN passe par le bot @OnBuchCreditsBot (achat « hors-app »,
// positionné côté web) ; l'app ne fait que **racheter un code**. Conformité
// Play : le build mobile n'affiche AUCUN lien de paiement externe — uniquement
// le champ « J'ai un code ». Le CTA Telegram n'apparaît que sur le web.
const onbuchRedeemUrl = 'https://telegram-bot-nine-henna.vercel.app/api/redeem';
const onbuchCreditsBotUrl = 'https://t.me/OnBuchCreditsBot';
