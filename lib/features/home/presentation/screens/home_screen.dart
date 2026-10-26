import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../library/domain/entities/track.dart';
import '../../../library/presentation/widgets/library_selection.dart';
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../bloc/home_bloc.dart';
import '../widgets/history_section.dart';
import '../widgets/home_parts.dart';
import '../widgets/recent_section.dart';
import '../widgets/recommend_section.dart';
import '../widgets/top_played_section.dart';
import 'top_tracks_screen.dart';

/// 홈: 네 구역으로 이뤄진다. 구역마다 모양이 달라 한눈에 구분된다.
/// ① 최근 들은 곡 ② 날짜별 청취 데이터 ③ 많이 들은 곡 ④ 추천 플레이리스트.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.libraryRoute = '/library'});

  /// 보관함이 비었을 때 "보관함으로" 버튼이 가는 곳.
  final String libraryRoute;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<HomeBloc>()..add(const HomeStarted()),
    child: _HomeView(libraryRoute: libraryRoute),
  );
}

class _HomeView extends StatefulWidget {
  const _HomeView({required this.libraryRoute});

  final String libraryRoute;

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> with TrackPicker<_HomeView> {
  // 구역이 여럿인 읽기 전용 목록: 전체 선택 · 앨범/아티스트/장르 지정은 두지 않고 재생목록 추가만 둔다.
  @override
  bool get pickerEditable => false;

  @override
  bool get pickerCanSelectAll => false;

  String get libraryRoute => widget.libraryRoute;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<HomeBloc>().state;
    final s = state.summary;
    final player = context.read<NowPlayingCubit>();
    // 홈 목록에 나올 수 있는 모든 곡 (고른 곡 id를 곡으로 되돌리는 데 쓴다).
    final all = <Track>[
      ...s.recent,
      for (final t in s.topTracks) t.track,
      for (final a in s.stats.topArtists) ...a.tracks,
      for (final g in s.stats.topGenres) ...g.tracks,
    ];

    final header = AppTopBar(
      large: true,
      title: l10n.navHome,
      subtitle: l10n.homeSubtitle,
    );

    // 보관함이 비었으면 구역 대신 안내 하나만, 머리 아래 남은 자리 가운데에 둔다.
    if (state.loaded && s.libraryEmpty) {
      return SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
                ),
                child: _EmptyState(
                  title: l10n.homeEmptyLibraryTitle,
                  body: l10n.homeEmptyLibraryBody,
                  action: l10n.homeGoLibrary,
                  onAction: () => context.go(libraryRoute),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final body = <Widget>[
      RecentSection(summary: s, player: player, selectionFor: selectionFor),
      const HomeDivider(),
      HistorySection(summary: s, joinedAt: state.joinedAt),
      const HomeDivider(),
      TopPlayedSection(
        summary: s,
        player: player,
        onMore: () => context.push(topTracksLocation),
        selectionFor: selectionFor,
      ),
      const HomeDivider(),
      RecommendSection(playlists: s.recommendedPlaylists, player: player),
    ];

    return SafeArea(
      bottom: false,
      // 구역이 4개뿐이라 한꺼번에 그린다: 목록을 지연 생성하면 스크롤로 벗어난 구역의
      // 접힘 · 선택 상태가 사라진다.
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom:
                  AppSpacing.lg +
                  MediaQuery.paddingOf(context).bottom +
                  selectionBottomGap,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [header, ...body],
            ),
          ),
          ?selectionBar(all, all),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.body,
    required this.action,
    required this.onAction,
  });

  final String title;
  final String body;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: AppIcons.equalizer,
      title: title,
      body: body,
      action: PillButton(
        label: action,
        icon: AppIcons.library,
        onPressed: onAction,
      ),
    );
  }
}
