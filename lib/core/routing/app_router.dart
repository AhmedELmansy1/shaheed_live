import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/league_model.dart';
import '../../data/models/match_model.dart';
import '../../data/models/team_model.dart';
import '../../presentation/diagnostics/design_gallery_screen.dart';
import '../../presentation/diagnostics/diagnostics_screen.dart';
import '../../presentation/favorites/favorite_teams_screen.dart';
import '../../presentation/home/home_screen.dart';
import '../../presentation/leagues/league_details_screen.dart';
import '../../presentation/leagues/leagues_screen.dart';
import '../../presentation/match_details/match_details_screen.dart';
import '../../presentation/onboarding/league_selection_screen.dart';
import '../../presentation/onboarding/notification_permission_screen.dart';
import '../../presentation/onboarding/team_selection_screen.dart';
import '../../presentation/search/team_fixtures_screen.dart';
import '../../presentation/search/team_search_screen.dart';
import '../../presentation/settings/settings_screen.dart';
import '../../presentation/shell/main_shell.dart';
import '../../presentation/update/force_update_screen.dart';
import '../services/notification_service.dart';
import '../services/update_service.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Helper ChangeNotifier for triggering GoRouter refresh on Riverpod state changes.
class AppRouterRefreshNotifier extends ChangeNotifier {
  void refresh() {
    notifyListeners();
  }
}

/// Provider for [GoRouter] with real-time reactive version check and onboarding guards.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = AppRouterRefreshNotifier();
  ref.onDispose(refreshNotifier.dispose);

  // Reactively trigger router refresh whenever version / update status changes in real-time
  ref.listen<AppUpdateInfo>(appUpdateInfoProvider, (previous, next) {
    refreshNotifier.refresh();
  });

  late final GoRouter router;

  router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/home',
    refreshListenable: refreshNotifier,
    routes: [
      GoRoute(path: '/', redirect: (context, state) => '/home'),
      GoRoute(
        path: '/force-update',
        builder: (context, state) => const ForceUpdateScreen(),
      ),
      GoRoute(
        path: '/onboarding/notifications',
        builder: (context, state) => const NotificationPermissionScreen(),
      ),
      GoRoute(
        path: '/onboarding/leagues',
        builder: (context, state) => const LeagueSelectionScreen(),
      ),
      GoRoute(
        path: '/onboarding/teams',
        builder: (context, state) => const TeamSelectionScreen(),
      ),
      // StatefulShellRoute hosting the 3 main tabs with BottomNavigationBar
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // Branch 1: Leagues
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/leagues',
                builder: (context, state) => const LeaguesScreen(),
              ),
            ],
          ),
          // Branch 2: Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      // Redirect legacy /channels path cleanly to /home
      GoRoute(
        path: '/channels',
        redirect: (context, state) => '/home',
      ),
      // Search screen
      GoRoute(
        path: '/search',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const TeamSearchScreen(),
      ),
      // Favorite teams management screen
      GoRoute(
        path: '/favorites',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const FavoriteTeamsScreen(),
      ),
      // Team fixtures screen
      GoRoute(
        path: '/team/:name/fixtures',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final teamName = state.pathParameters['name'] ?? '';
          final teamModel = state.extra is TeamModel
              ? state.extra as TeamModel
              : null;
          return TeamFixturesScreen(teamName: teamName, teamModel: teamModel);
        },
      ),
      // Match details screen
      GoRoute(
        path: '/match/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '0';
          final match = state.extra is MatchModel
              ? state.extra as MatchModel
              : null;
          return MatchDetailsScreen(matchId: id, initialMatch: match);
        },
      ),
      // League details screen
      GoRoute(
        path: '/league/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final league = state.extra is LeagueModel
              ? state.extra as LeagueModel
              : null;
          return LeagueDetailsScreen(leagueId: id, initialLeague: league);
        },
      ),
      // Settings: Manage Leagues screen
      GoRoute(
        path: '/settings/leagues',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            const LeagueSelectionScreen(isEditing: true),
      ),
      // Diagnostics screen (enabled only via --dart-define=ENABLE_DIAGNOSTICS=true)
      GoRoute(
        path: '/diagnostics',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          if (!kEnableDiagnostics) {
            return const Scaffold(
              body: Center(child: Text('Diagnostics disabled in this build.')),
            );
          }
          return const DiagnosticsScreen();
        },
      ),
      // Design Gallery (enabled only via --dart-define=ENABLE_DIAGNOSTICS=true)
      GoRoute(
        path: '/design-gallery',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          if (!kEnableDiagnostics) {
            return const Scaffold(
              body: Center(child: Text('Diagnostics disabled in this build.')),
            );
          }
          return const DesignGalleryScreen();
        },
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) async {
      final location = state.matchedLocation;

      // 1. Guard against Hard Block: Check Version / Force Update FIRST
      final updateInfo = ref.read(appUpdateInfoProvider);
      debugPrint(
        '[AppRouter.redirect] Checking location="$location" | isHardBlocked=${updateInfo.isHardBlocked}, '
        'status=${updateInfo.status}, current="${updateInfo.currentVersion}", latest="${updateInfo.latestVersion}"',
      );
      if (updateInfo.isHardBlocked) {
        if (location != '/force-update') {
          debugPrint('[AppRouter.redirect] -> REDIRECTING to /force-update');
          return '/force-update';
        }
        return null;
      } else {
        // If user was on /force-update but update is no longer forced, redirect to home
        if (location == '/force-update') {
          debugPrint('[AppRouter.redirect] -> Leaving /force-update to /home');
          return '/home';
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final notifSetup =
          prefs.getBool('hasCompletedNotificationSetup') ?? false;
      final onboardingDone = prefs.getBool('hasCompletedOnboarding') ?? false;

      // 2. Guard: Require Notification setup before any other route
      if (!notifSetup && location != '/onboarding/notifications') {
        return '/onboarding/notifications';
      }

      // 3. Guard: Require Onboarding (leagues & teams selection) before Home & Match Details
      if (notifSetup &&
          !onboardingDone &&
          (location == '/home' ||
              location == '/leagues' ||
              location == '/settings' ||
              location.startsWith('/match/') ||
              location.startsWith('/league/') ||
              location == '/search' ||
              location.startsWith('/team/'))) {
        return '/onboarding/leagues';
      }

      return null;
    },
  );

  // Configure global notification deep link callback
  NotificationService.onMatchNotificationTap = (matchId) {
    try {
      router.push('/match/$matchId');
    } catch (e) {
      debugPrint('Error navigating from notification tap: $e');
    }
  };

  // Check if there was a pending cold start notification tap
  if (NotificationService.pendingColdStartMatchId != null) {
    final pendingId = NotificationService.pendingColdStartMatchId!;
    NotificationService.pendingColdStartMatchId = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        router.push('/match/$pendingId');
      } catch (e) {
        debugPrint('Error navigating to pending cold start match: $e');
      }
    });
  }

  ref.onDispose(router.dispose);
  return router;
});
