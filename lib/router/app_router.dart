import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/onboarding/splash_screen.dart';
import '../screens/onboarding/value_screens.dart';
import '../screens/onboarding/auth_phone_screen.dart';
import '../screens/onboarding/profile_setup_screen.dart';
import '../screens/onboarding/welcome_screen.dart';
import '../screens/main_shell.dart';
import '../screens/home/home_screen.dart';
import '../screens/school/school_life_screen.dart';
import '../screens/results/results_search_screen.dart';
import '../screens/results/result_success_screen.dart';
import '../screens/results/result_fail_screen.dart';
import '../screens/annales/annales_library_screen.dart';
import '../screens/annales/annales_folder_screen.dart';
import '../screens/annales/annale_detail_screen.dart';
import '../screens/annales/pdf_reader_screen.dart';
import '../screens/annales/video_corrige_screen.dart';
import '../screens/tutor/tutor_hub_screen.dart';
import '../screens/tutor/tutor_camera_screen.dart';
import '../screens/tutor/tutor_correction_screen.dart';
import '../screens/tutor/tutor_similar_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/news/article_detail_screen.dart';
import '../screens/news/news_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/affiche/affiche_screen.dart';
import '../screens/affiche/affiche_detail_screen.dart';
import '../models/affiche.dart';
import '../screens/menu/concours_screen.dart';
import '../screens/menu/credits_screen.dart';
import '../screens/menu/communaute_screen.dart';
import '../screens/menu/parametres_screen.dart';
import '../screens/menu/aide_screen.dart';
import '../screens/cours/cours_screen.dart';
import '../screens/cours/chapters_screen.dart';
import '../screens/cours/chapter_detail_screen.dart';
import '../screens/cours/quiz_screen.dart';
import '../models/article.dart';
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
    GoRoute(path: '/concours', builder: (_, __) => const ConcoursScreen()),
    GoRoute(path: '/credits', builder: (_, __) => const CreditsScreen()),
    GoRoute(path: '/communaute', builder: (_, __) => const CommunauteScreen()),
    GoRoute(path: '/parametres', builder: (_, __) => const ParametresScreen()),
    GoRoute(path: '/aide', builder: (_, __) => const AideScreen()),
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
    ShellRoute(
      builder: (_, state, child) => MainShell(location: state.uri.path, child: child),
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/campus', builder: (_, __) => const SchoolLifeScreen()),
        GoRoute(
          path: '/results',
          builder: (_, __) => const ResultsSearchScreen(),
          routes: [
            GoRoute(path: 'success', builder: (_, __) => const ResultSuccessScreen()),
            GoRoute(path: 'fail', builder: (_, __) => const ResultFailScreen()),
          ],
        ),
        GoRoute(
          path: '/annales',
          builder: (_, __) => const AnnalesLibraryScreen(),
          routes: [
            GoRoute(path: 'folder/:name', builder: (_, s) => AnnalesFolderScreen(folderName: s.pathParameters['name'] ?? '')),
            GoRoute(path: 'detail', builder: (_, __) => const AnnaleDetailScreen()),
            GoRoute(path: 'pdf', builder: (_, __) => const PdfReaderScreen()),
            GoRoute(path: 'video', builder: (_, __) => const VideoCorrigeScreen()),
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
          ],
        ),
        GoRoute(path: '/cours', builder: (_, __) => const CoursScreen()),
        GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      ],
    ),
  ],
);
