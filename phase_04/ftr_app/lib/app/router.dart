import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/navigation/content_route_resolver.dart';
import '../core/widgets/ftr_shell.dart';
import '../features/account/presentation/account_privacy_screen.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/auth/presentation/reset_password_screen.dart';
import '../features/courses/presentation/courses_screen.dart';
import '../features/courses/presentation/category_contents_screen.dart';
import '../features/favorites/presentation/favorites_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/notes/presentation/notes_screen.dart';
import '../features/premium/presentation/premium_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/quiz/presentation/quiz_screen.dart';
import '../features/search/presentation/search_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => FtrShell(location: state.uri.path, child: child),
      routes: [
        GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/courses', builder: (_, __) => const CoursesScreen()),
        GoRoute(
          path: '/courses/:slug',
          builder: (_, state) => CategoryContentsScreen(
            categoryName: state.uri.queryParameters['name'] ?? '',
          ),
        ),
        GoRoute(path: '/favorites', builder: (_, __) => const FavoritesScreen()),
        GoRoute(path: '/notes', builder: (_, __) => const NotesScreen()),
        GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      ],
    ),
    GoRoute(path: '/auth', builder: (_, __) => const AuthScreen()),
    GoRoute(path: '/reset-password', builder: (_, __) => const ResetPasswordScreen()),
    GoRoute(path: '/account', builder: (_, __) => const AccountPrivacyScreen()),
    GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
    GoRoute(
      path: '/content/:id',
      builder: (_, state) => ContentRouteResolver(contentId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/quiz/:id',
      builder: (_, state) => QuizScreen(contentId: state.pathParameters['id']!),
    ),
    GoRoute(path: '/premium', builder: (_, __) => const PremiumScreen()),
  ],
  errorBuilder: (_, state) => Scaffold(body: Center(child: Text('Sayfa bulunamadı: ${state.uri}'))),
);
