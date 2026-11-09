import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/design/design.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/home/presentation/screens/top_tracks_screen.dart';
import '../features/library/presentation/screens/album_screen.dart';
import '../features/library/presentation/screens/artist_screen.dart';
import '../features/library/presentation/screens/genre_screen.dart';
import '../features/library/domain/entities/track.dart';
import '../features/library/presentation/screens/library_screen.dart';
import '../features/library/presentation/screens/track_info_screen.dart';
import '../features/player/presentation/screens/player_screen.dart';
import '../features/player/presentation/screens/queue_screen.dart';
import '../features/playlists/presentation/screens/playlist_detail_screen.dart';
import '../features/playlists/presentation/screens/playlist_import_screen.dart';
import '../features/playlists/presentation/screens/playlist_add_tracks_screen.dart';
import '../features/playlists/presentation/screens/playlist_pick_screen.dart';
import '../features/playlists/presentation/screens/playlists_screen.dart';
import '../features/search/presentation/screens/saved_videos_screen.dart';
import '../features/search/presentation/screens/search_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/equalizer/presentation/screens/equalizer_screen.dart';
import '../features/subscriptions/presentation/screens/channel_search_screen.dart';
import '../features/subscriptions/presentation/screens/my_subscriptions_screen.dart';
import '../features/subscriptions/presentation/screens/subscriptions_screen.dart';
import 'app_shell.dart';

abstract final class Routes {
  static const home = '/home';
  static const library = '/library';
  static const playlists = '/playlists';
  static const search = '/search';
  static const settings = '/settings';
  static const player = '/player';
  static const queue = '/queue';

  /// 곡 상세 정보 · 편집 ([Track]을 `extra`로 넘긴다).
  static const trackInfo = '/track-info';

  /// 구독 채널 목록 · 채널 검색 (설정 아래, 탭 틀 위로 덮어 연다).
  static const subscriptions = '/settings/subscriptions';
  static const channelSearch = '/settings/channel-search';
  static const channelImport = '/settings/channel-import';

  /// 이퀄라이저 (설정 아래, 탭 틀 위로 덮어 연다).
  static const equalizer = '/settings/equalizer';

  /// 곡을 담을 재생목록 고르기 (곡 id는 `extra`로 넘긴다).
  static const playlistPick = '/playlists/pick';

  /// 유튜브 재생목록 가져오기 (주소를 미리 채우려면 문자열을 `extra`로 넘긴다).
  static const playlistImport = '/playlists/import';

  static String playlistDetail(String id) =>
      '/playlists/${Uri.encodeComponent(id)}';

  /// 재생목록 카드 순서 바꾸기.

  /// 재생목록에 곡 추가 (보관함의 곡을 골라 담는다).
  static String playlistAddTracks(String id) =>
      '/playlists/${Uri.encodeComponent(id)}/add';

  /// [album]은 곡에 저장된 앨범 이름 (빈 문자열이면 알 수 없는 앨범).
  static String album(String album) =>
      Uri(path: '/library/album', queryParameters: {'name': album}).toString();

  /// [genre]는 곡에 저장된 장르 (빈 문자열이면 알 수 없는 장르).
  static String genre(String genre) =>
      Uri(path: '/library/genre', queryParameters: {'name': genre}).toString();

  /// [artist]는 곡에 저장된 아티스트 이름 (빈 문자열이면 알 수 없는 아티스트).
  static String artist(String artist) => Uri(
    path: '/library/artist',
    queryParameters: {'name': artist},
  ).toString();
}

final _rootKey = GlobalKey<NavigatorState>();

/// 앱 라우터. 하단 탭 5개는 각자 스택을 유지하고(StatefulShellRoute),
/// 전체 화면 플레이어는 탭 위로 덮어 연다.
GoRouter createRouter({String initialLocation = Routes.home}) => GoRouter(
  navigatorKey: _rootKey,
  initialLocation: initialLocation,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(shell: shell),
      branches: [
        // 탭 순서: 보관함 · 재생목록 · 홈(가운데) · 검색 · 설정.
        _branch(
          Routes.library,
          const LibraryScreen(),
          routes: [
            GoRoute(
              path: 'artist',
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: ArtistScreen(
                  artist: state.uri.queryParameters['name'] ?? '',
                ),
              ),
            ),
            GoRoute(
              path: 'genre',
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: GenreScreen(
                  genre: state.uri.queryParameters['name'] ?? '',
                ),
              ),
            ),
            GoRoute(
              path: 'album',
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: AlbumScreen(
                  album: state.uri.queryParameters['name'] ?? '',
                ),
              ),
            ),
          ],
        ),
        _branch(
          Routes.playlists,
          const PlaylistsScreen(),
          routes: [
            // 곡 담기 선택은 탭 틀 위로 덮어 연다.
            GoRoute(
              path: 'pick',
              parentNavigatorKey: _rootKey,
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: PlaylistPickScreen(
                  trackIds: {...?(state.extra as List<String>?)},
                ),
              ),
            ),
            GoRoute(
              path: 'import',
              parentNavigatorKey: _rootKey,
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: PlaylistImportScreen(
                  initialUrl: state.extra as String? ?? '',
                ),
              ),
            ),
            GoRoute(
              path: ':id/add',
              parentNavigatorKey: _rootKey,
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: PlaylistAddTracksScreen(
                  playlistId: state.pathParameters['id']!,
                ),
              ),
            ),
            GoRoute(
              path: ':id',
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: PlaylistDetailScreen(
                  playlistId: state.pathParameters['id']!,
                ),
              ),
            ),
          ],
        ),
        _branch(
          Routes.home,
          const HomeScreen(libraryRoute: Routes.library),
          routes: [
            GoRoute(
              path: 'top-tracks',
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: const TopTracksScreen(),
              ),
            ),
          ],
        ),
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
              routes: [
                GoRoute(
                  path: 'saved',
                  parentNavigatorKey: _rootKey,
                  pageBuilder: (context, state) => NoTransitionPage(
                    key: state.pageKey,
                    child: const SavedVideosScreen(),
                  ),
                ),
              ],
            ),
          ],
        ),
        _branch(
          Routes.settings,
          const SettingsScreen(),
          routes: [
            GoRoute(
              path: 'subscriptions',
              parentNavigatorKey: _rootKey,
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: const SubscriptionsScreen(),
              ),
            ),
            GoRoute(
              path: 'equalizer',
              parentNavigatorKey: _rootKey,
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: EqualizerScreen(
                  deviceKey: state.uri.queryParameters['device'],
                ),
              ),
            ),
            GoRoute(
              path: 'channel-search',
              parentNavigatorKey: _rootKey,
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: const ChannelSearchScreen(),
              ),
            ),
            GoRoute(
              path: 'channel-import',
              parentNavigatorKey: _rootKey,
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: const MySubscriptionsScreen(),
              ),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: Routes.trackInfo,
      parentNavigatorKey: _rootKey,
      pageBuilder: (context, state) => MaterialPage(
        child: TrackInfoScreen(track: state.extra! as Track),
      ),
    ),
    GoRoute(
      path: Routes.queue,
      parentNavigatorKey: _rootKey,
      pageBuilder: (context, state) => const MaterialPage(child: QueueScreen()),
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
  ],
);

StatefulShellBranch _branch(
  String path,
  Widget screen, {
  List<RouteBase> routes = const [],
}) => StatefulShellBranch(
  routes: [
    GoRoute(
      path: path,
      pageBuilder: (context, state) => NoTransitionPage(child: screen),
      routes: routes,
    ),
  ],
);
