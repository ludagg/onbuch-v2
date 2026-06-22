import 'dart:typed_data';
import 'package:go_router/go_router.dart';
import '../screens/onboarding/splash_screen.dart';
import '../screens/onboarding/value_screens.dart';
import '../screens/onboarding/auth_phone_screen.dart';
import '../screens/onboarding/profile_setup_screen.dart';
import '../screens/onboarding/welcome_screen.dart';
import '../screens/main_shell.dart';
import '../screens/home/home_screen.dart';
import '../screens/school/school_life_screen.dart';
import '../screens/school/school_events_screen.dart';
import '../screens/results/results_search_screen.dart';
import '../screens/results/result_success_screen.dart';
import '../screens/results/result_fail_screen.dart';
import '../screens/annales/annales_library_screen.dart';
import '../data/exam_taxonomy.dart';
import '../screens/annales/annales_collection_screen.dart';
import '../screens/annales/annales_folder_screen.dart';
import '../screens/annales/annale_subject_screen.dart';
import '../screens/annales/annale_detail_screen.dart';
import '../screens/annales/pdf_reader_screen.dart';
import '../screens/annales/video_corrige_screen.dart';
import '../screens/tutor/tutor_hub_screen.dart';
import '../screens/tutor/tutor_coach_screen.dart';
import '../screens/tutor/tutor_camera_screen.dart';
import '../screens/tutor/tutor_correction_screen.dart';
import '../screens/tutor/tutor_similar_screen.dart';
import '../screens/tutor/tutor_mode_screens.dart';
import '../screens/tutor/camera_capture_screen.dart';
import '../screens/tutor/course_summary_screen.dart';
import '../screens/tutor/course_summary_result_screen.dart';
import '../screens/tutor/crop_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/search/global_search_screen.dart';
import '../screens/news/article_detail_screen.dart';
import '../screens/news/news_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/affiche/affiche_screen.dart';
import '../screens/affiche/affiche_detail_screen.dart';
import '../models/affiche.dart';
import '../screens/menu/concours_screen.dart';
import '../screens/menu/concours_detail_screen.dart';
import '../screens/menu/concours_inscription_screen.dart';
import '../screens/menu/mes_candidatures_screen.dart';
import '../screens/menu/concours_prep_screen.dart';
import '../screens/menu/concours_progress_screen.dart';
import '../screens/menu/concours_blanc_screen.dart';
import '../screens/menu/concours_alertes_screen.dart';
import '../screens/menu/resultat_admission_screen.dart';
import '../models/concours_application.dart';
import '../screens/menu/credits_screen.dart';
import '../screens/menu/communaute_screen.dart';
import '../screens/menu/parametres_screen.dart';
import '../screens/menu/aide_screen.dart';
import '../screens/cours/cours_screen.dart';
import '../screens/cours/chapters_screen.dart';
import '../screens/cours/chapter_detail_screen.dart';
import '../screens/cours/quiz_screen.dart';
import '../screens/cours/quiz_result_screen.dart';
import '../screens/cours/cours_search_screen.dart';
import '../models/article.dart';
import '../models/exam_result.dart';
import '../models/concours.dart';
import '../models/annale.dart';
import '../models/tutor_request.dart';
import '../models/course.dart';
import '../services/auth_service.dart';

final _authService = AuthService();

final appRouter = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) async {
    final path = state.uri.path;
    final isPublic = path == '/splash' ||
        path.startsWith('/onboarding') ||
        path.startsWith('/auth') ||
        path == '/welcome';
    if (isPublic) return null;
    final loggedIn = await _authService.isLoggedIn();
    if (!loggedIn) return '/auth/phone';
    return null;
  },
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/onboarding/1', builder: (_, __) => const Value1Screen()),
    GoRoute(path: '/onboarding/2', builder: (_, __) => const Value2Screen()),
    GoRoute(path: '/onboarding/3', builder: (_, __) => const Value3Screen()),
    GoRoute(path: '/auth/phone', builder: (_, __) => const AuthPhoneScreen()),
    GoRoute(path: '/auth/profile', builder: (_, __) => const ProfileSetupScreen()),
    GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
    GoRoute(
      path: '/article',
      builder: (_, s) => ArticleDetailScreen(article: s.extra as Article?),
    ),
    GoRoute(path: '/actualites', builder: (_, __) => const NewsScreen()),
    GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
    GoRoute(path: '/affiche', builder: (_, __) => const AfficheScreen()),
    GoRoute(path: '/affiche-detail', builder: (_, s) => AfficheDetailScreen(item: s.extra as AfficheItem?)),
    GoRoute(path: '/concours-detail', builder: (_, s) => ConcoursDetailScreen(concours: s.extra as Concours?)),
    GoRoute(path: '/concours-inscription', builder: (_, s) => ConcoursInscriptionScreen(concours: s.extra as Concours?)),
    GoRoute(path: '/mes-candidatures', builder: (_, __) => const MesCandidaturesScreen()),
    GoRoute(path: '/concours-prep', builder: (_, s) => ConcoursPrepScreen(concours: s.extra as Concours?)),
    GoRoute(path: '/concours-progress', builder: (_, __) => const ConcoursProgressScreen()),
    GoRoute(path: '/concours-blanc', builder: (_, s) => ConcoursBlancScreen(concours: s.extra as Concours?)),
    GoRoute(path: '/concours-alertes', builder: (_, __) => const ConcoursAlertesScreen()),
    GoRoute(path: '/resultat-admission', builder: (_, s) => ResultatAdmissionScreen(application: s.extra as ConcoursApplication?)),
    GoRoute(path: '/credits', builder: (_, __) => const CreditsScreen()),
    GoRoute(path: '/communaute', builder: (_, __) => const CommunauteScreen()),
    GoRoute(path: '/parametres', builder: (_, __) => const ParametresScreen()),
    GoRoute(path: '/aide', builder: (_, __) => const AideScreen()),
    GoRoute(path: '/edit-profile', builder: (_, __) => const EditProfileScreen()),
    GoRoute(path: '/search', builder: (_, __) => const GlobalSearchScreen()),
    GoRoute(
      path: '/cours-subject',
      builder: (_, s) => ChaptersScreen(subject: s.extra as Subject?),
    ),
    GoRoute(
      path: '/cours-chapter',
      builder: (_, s) {
        final m = s.extra is Map ? s.extra as Map : const {};
        return ChapterDetailScreen(
          chapter: m['chapter'] as Chapter?,
          subjectName: m['subject'] as String?,
        );
      },
    ),
    GoRoute(
      path: '/cours-quiz',
      builder: (_, s) {
        final m = s.extra is Map ? s.extra as Map : const {};
        return QuizScreen(
          chapter: m['chapter'] as Chapter?,
          subjectName: m['subject'] as String?,
        );
      },
    ),
    GoRoute(
      path: '/cours-quiz-result',
      builder: (_, s) => QuizResultScreen(
        data: s.extra is Map ? (s.extra as Map).cast<String, dynamic>() : null,
      ),
    ),
    GoRoute(path: '/cours-search', builder: (_, __) => const CoursSearchScreen()),
    ShellRoute(
      builder: (_, state, child) => MainShell(location: state.uri.path, child: child),
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/concours', builder: (_, __) => const ConcoursScreen()),
        GoRoute(path: '/campus', builder: (_, __) => const SchoolLifeScreen()),
        GoRoute(path: '/agenda', builder: (_, __) => const SchoolEventsScreen()),
        GoRoute(
          path: '/results',
          builder: (_, __) => const ResultsSearchScreen(),
          routes: [
            GoRoute(path: 'success', builder: (_, s) => ResultSuccessScreen(result: s.extra as ExamResult?)),
            GoRoute(path: 'fail', builder: (_, s) => ResultFailScreen(result: s.extra as ExamResult?)),
          ],
        ),
        GoRoute(
          path: '/annales',
          builder: (_, __) => const AnnalesLibraryScreen(),
          routes: [
            GoRoute(path: 'folder/:name', builder: (_, s) => AnnalesFolderScreen(folderName: s.pathParameters['name'] ?? '', node: s.extra as ExamNode?, exam: s.uri.queryParameters['exam'])),
            GoRoute(
              path: 'subject',
              builder: (_, s) {
                final m = s.extra is Map ? s.extra as Map : const {};
                return AnnaleSubjectScreen(
                  subject: (m['subject'] ?? '').toString(),
                  exam: m['exam'] as String?,
                  filiere: m['filiere'] as String?,
                );
              },
            ),
            GoRoute(path: 'detail', builder: (_, s) => AnnaleDetailScreen(annale: s.extra is Annale ? s.extra as Annale : null)),
            GoRoute(
              path: 'pdf',
              builder: (_, s) {
                final m = s.extra is Map ? s.extra as Map : const {};
                return PdfReaderScreen(
                  url: (m['url'] ?? '').toString(),
                  title: m['title'] as String?,
                  subtitle: m['subtitle'] as String?,
                  offlineId: m['offlineId'] as String?,
                );
              },
            ),
            GoRoute(
              path: 'video',
              builder: (_, s) {
                final m = s.extra is Map ? s.extra as Map : const {};
                return VideoCorrigeScreen(
                  url: (m['url'] ?? '').toString(),
                  title: m['title'] as String?,
                  subtitle: m['subtitle'] as String?,
                );
              },
            ),
            GoRoute(path: 'recent', builder: (_, __) => const AnnalesCollectionScreen(kind: AnnaleCollection.recent)),
            GoRoute(path: 'offline', builder: (_, __) => const AnnalesCollectionScreen(kind: AnnaleCollection.offline)),
            GoRoute(path: 'favorites', builder: (_, __) => const AnnalesCollectionScreen(kind: AnnaleCollection.favorites)),
          ],
        ),
        GoRoute(
          path: '/tutor',
          builder: (_, __) => const TutorHubScreen(),
          routes: [
            GoRoute(path: 'camera', builder: (_, __) => const TutorCameraScreen()),
            GoRoute(
              path: 'correction',
              builder: (_, s) {
                final e = s.extra;
                final req = e is TutorRequest
                    ? e
                    : (e is Uint8List ? TutorRequest(image: e) : null);
                return TutorCorrectionScreen(request: req);
              },
            ),
            GoRoute(path: 'similar', builder: (_, __) => const TutorSimilarScreen()),
            GoRoute(path: 'coach', builder: (_, __) => const TutorCoachScreen()),
            GoRoute(path: 'corriger', builder: (_, __) => const TutorCorrigerScreen()),
            GoRoute(path: 'expliquer', builder: (_, __) => const TutorExpliquerScreen()),
            GoRoute(path: 'entrainer', builder: (_, __) => const TutorEntrainerScreen()),
            GoRoute(path: 'capture', builder: (_, s) => CameraCaptureScreen(subject: s.extra as String?)),
            GoRoute(path: 'resume', builder: (_, s) => CourseSummaryScreen(subject: s.extra as String?)),
            GoRoute(path: 'fiche', builder: (_, s) => CourseSummaryResultScreen(request: s.extra as TutorRequest?)),
            // Ouverture d'un job terminé par tap sur une notification push.
            GoRoute(
              path: 'job/:id',
              builder: (_, s) => TutorCorrectionScreen(
                request: TutorRequest(jobId: s.pathParameters['id']),
              ),
            ),
            GoRoute(
              path: 'crop',
              builder: (_, s) {
                final m = s.extra as Map?;
                final bytes = m?['bytes'] as Uint8List?;
                if (bytes == null) return const TutorHubScreen();
                return CropScreen(bytes: bytes, subject: m?['subject'] as String?);
              },
            ),
          ],
        ),
        GoRoute(path: '/cours', builder: (_, __) => const CoursScreen()),
        GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      ],
    ),
  ],
);
