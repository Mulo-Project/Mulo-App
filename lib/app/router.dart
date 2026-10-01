import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/design/design.dart';
import '../features/design_preview/presentation/screens/design_preview_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/library/presentation/screens/library_screen.dart';
import '../features/player/presentation/screens/player_screen.dart';
import '../features/playlists/presentation/screens/playlists_screen.dart';
import '../features/search/presentation/screens/search_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import 'app_shell.dart';

abstract final class Routes {
  static const home = '/home';
  static const library = '/library';
  static const playlists = '/playlists';
  static const search = '/search';
  static const settings = '/settings';
  static const player = '/player';
  static const designPreview = '/design-preview';
}

final _rootKey = GlobalKey<NavigatorState>();

/// 앱 라우터. 하단 탭 5개는 각자 스택을 유지하고(StatefulShellRoute),
/// 전체 화면 플레이어 · 디자인 미리보기는 탭 위로 덮어 연다.
GoRouter createRouter({String initialLocation = Routes.home}) => GoRouter(
  navigatorKey: _rootKey,
  initialLocation: initialLocation,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(shell: shell),
      branches: [
        // 탭 순서: 보관함 · 재생목록 · 홈(가운데) · 검색 · 설정.
        _branch(Routes.library, const LibraryScreen()),
        _branch(Routes.playlists, const PlaylistsScreen()),
        _branch(Routes.home, const HomeScreen(libraryRoute: Routes.library)),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.search,
              // ?q= 로 입력칸을 채워 연다 (공유 메뉴로 받기 #4에서 쓴다).
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: SearchScreen(
                  initialQuery: state.uri.queryParameters['q'] ?? '',
                ),
              ),
            ),
          ],
        ),
        _branch(Routes.settings, const SettingsScreen()),
      ],
    ),
    GoRoute(
      path: Routes.player,
      parentNavigatorKey: _rootKey,
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const PlayerScreen(),
        transitionDuration: AppMotion.slow,
        reverseTransitionDuration: AppMotion.medium,
        transitionsBuilder: (context, animation, _, child) => SlideTransition(
          position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(
            CurvedAnimation(parent: animation, curve: AppMotion.emphasized),
          ),
          child: child,
        ),
      ),
    ),
    GoRoute(
      path: Routes.designPreview,
      parentNavigatorKey: _rootKey,
      builder: (context, state) => const DesignPreviewScreen(),
    ),
  ],
);

StatefulShellBranch _branch(String path, Widget screen) => StatefulShellBranch(
  routes: [
    GoRoute(
      path: path,
      pageBuilder: (context, state) => NoTransitionPage(child: screen),
    ),
  ],
);
