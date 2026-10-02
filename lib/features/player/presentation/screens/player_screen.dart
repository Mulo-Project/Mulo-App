import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../bloc/now_playing_cubit.dart';
import '../bloc/player_style_cubit.dart';
import '../widgets/player_common.dart';
import '../widgets/player_layouts.dart';

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
  var _showLyrics = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<NowPlayingCubit>().state;
    final style = context.watch<PlayerStyleCubit>().state;
    final track = state.track;

    return Scaffold(
      backgroundColor: context.palette.background,
      body: track == null
          ? const AppBackground()
          : _layout(
              style,
              PlayerLayoutData(
                track: track,
                state: state,
                vm: context.read<NowPlayingCubit>(),
                showLyrics: _showLyrics,
                onToggleLyrics: () =>
                    setState(() => _showLyrics = !_showLyrics),
              ),
            ),
    );
  }

  Widget _layout(PlayerStyle style, PlayerLayoutData data) => switch (style) {
    PlayerStyle.vinyl => VinylPlayer(data: data),
    PlayerStyle.square => SquarePlayer(data: data),
    PlayerStyle.fullBleed => FullBleedPlayer(data: data),
    PlayerStyle.arc => ArcPlayer(data: data),
  };
}
