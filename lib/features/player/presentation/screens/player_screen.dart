import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../bloc/now_playing_cubit.dart';
import '../bloc/player_style_cubit.dart';
import '../widgets/player_common.dart';
import '../widgets/player_layouts.dart';
import '../widgets/player_style_sheet.dart';

/// 전체 화면 플레이어 (상세 기능: 미니·전체 화면 플레이어 #19, 기본 재생 컨트롤 #14,
/// 셔플·반복 #15, 재생 대기열 편집 #16 — 대기열은 보기 · 선택만).
/// 모양은 더 보기 메뉴의 "플레이어 테마"로 고른다 ([PlayerStyle], D-039).
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  /// 커버 ↔ 가사 전환 (상세 기능: 가사).
  bool get _showLyrics => playerShowLyrics.value;

  @override
  void initState() {
    super.initState();
    playerShowLyrics.value = false;
    playerShowLyrics.addListener(_onLyricsToggle);
  }

  void _onLyricsToggle() => setState(() {});

  Animation<double>? _covered;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 위에 덮인 화면(대기열 등)이 닫혀 다시 맨 위가 되면 빈 화면인지 본다.
    final next = ModalRoute.of(context)?.secondaryAnimation;
    if (next == _covered) return;
    _covered?.removeStatusListener(_onCoverStatus);
    _covered = next?..addStatusListener(_onCoverStatus);
  }

  @override
  void dispose() {
    playerShowLyrics.removeListener(_onLyricsToggle);
    _covered?.removeStatusListener(_onCoverStatus);
    super.dispose();
  }

  void _onCoverStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) _closeIfEmpty();
  }

  /// 재생할 곡이 없으면(대기열을 비웠을 때) 빈 플레이어를 닫는다.
  void _closeIfEmpty() {
    if (!mounted || context.read<NowPlayingCubit>().state.track != null) return;
    if ((ModalRoute.of(context)?.isCurrent ?? false) && context.canPop()) {
      context.pop();
    }
  }

  String? _loggedTrackId;

  @override
  Widget build(BuildContext context) {
    final style = context.watch<PlayerStyleCubit>().state;
    // 재생 위치만 바뀔 때는 다시 그리지 않는다 (진행 막대 · 시간은 PositionBuilder가 따로 그린다).
    return BlocBuilder<NowPlayingCubit, NowPlayingState>(
      buildWhen: (a, b) => a.copyWith(position: b.position) != b,
      builder: (context, state) => _screen(context, state, style),
    );
  }

  Widget _screen(
    BuildContext context,
    NowPlayingState state,
    PlayerStyle style,
  ) {
    final track = state.track;
    if (track != null && track.id != _loggedTrackId) {
      _loggedTrackId = track.id;
      debugPrint(
        'MuloPlayer track=${track.id} isVideo=${track.isVideo} '
        'hasVideo=${track.hasVideo} style=$style uri=${track.uri}',
      );
    }
    if (track == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _closeIfEmpty());
    }

    return Scaffold(
      backgroundColor: context.palette.background,
      body: track == null
          ? const AppBackground()
          : _shrinkForSheet(
              _layout(
                style,
                PlayerLayoutData(
                  track: track,
                  state: state,
                  vm: context.read<NowPlayingCubit>(),
                  showLyrics: _showLyrics,
                  onToggleLyrics: () =>
                      playerShowLyrics.value = !playerShowLyrics.value,
                ),
              ),
            ),
    );
  }

  /// 플레이어 테마 시트가 떠 있으면 화면 전체를 시트 위 빈 곳에 맞게 줄여 보여준다.
  Widget _shrinkForSheet(Widget child) => LayoutBuilder(
    builder: (context, c) => ValueListenableBuilder<double>(
      valueListenable: playerStyleSheetHeight,
      builder: (context, sheet, _) => AnimatedScale(
        scale: c.maxHeight > 0
            ? ((c.maxHeight - sheet) / c.maxHeight).clamp(.5, 1.0)
            : 1,
        alignment: Alignment.topCenter,
        duration: AppMotion.medium,
        curve: AppMotion.standard,
        child: child,
      ),
    ),
  );

  Widget _layout(PlayerStyle style, PlayerLayoutData data) => switch (style) {
    PlayerStyle.square => SquarePlayer(data: data),
    PlayerStyle.fullBleed => FullBleedPlayer(data: data),
    PlayerStyle.arc => ArcPlayer(data: data),
  };
}
