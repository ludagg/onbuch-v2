const appwriteEndpoint = 'https://nyc.cloud.appwrite.io/v1';
const appwriteProjectId = '6a30463b00001375e229';
const appwriteDatabaseId = '6a3047f8001d11d1b3c1';
const appwriteUsersCollectionId = 'users';
const appwriteExamSeriesCollectionId = 'exam_series';
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

// ── Push (FCM via Appwrite Messaging) ───────────────────────────────────────
// Optionnels. Laisser vide fonctionne tant qu'il n'y a qu'un seul provider push
// côté Appwrite. Renseigner si tu veux cibler un provider/topic précis.
// `appwritePushTopicId` : si défini, chaque appareil s'abonne à ce topic, ce qui
// permet à l'admin d'envoyer un push « à tous » en une fois.
const appwriteFcmProviderId = '';
const appwritePushTopicId = '';
